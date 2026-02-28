from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title='SmartTime Solver', version='0.3.0')


class Lesson(BaseModel):
    id: str
    classId: str
    teacherId: str
    subjectId: str
    preferredRoomId: Optional[str] = None
    requiredRoomType: Optional[str] = None
    fixedDay: Optional[int] = None
    fixedPeriod: Optional[int] = None
    isLabDouble: bool = False


class ConstraintConfig(BaseModel):
    teacherAvailability: Dict[str, List[Dict[str, int]]] = Field(default_factory=dict)
    teacherMaxPeriodsPerDay: Dict[str, int] = Field(default_factory=dict)
    classMaxPeriodsPerDay: Dict[str, int] = Field(default_factory=dict)
    fixedPeriods: Dict[str, Dict[str, int]] = Field(default_factory=dict)


class SolveRequest(BaseModel):
    schoolId: str
    days: int = 5
    periodsPerDay: int = 8
    lessons: List[Lesson]
    constraints: ConstraintConfig = Field(default_factory=ConstraintConfig)
    pinned: List[Dict[str, Any]] = Field(default_factory=list)
    seed: int = 7


class SolveResponse(BaseModel):
    schoolId: str
    status: str
    hardViolations: List[Dict[str, Any]]
    softPenaltyBreakdown: List[Dict[str, Any]]
    assignments: List[Dict[str, Any]]
    score: int


@dataclass(frozen=True)
class Slot:
    day: int
    period: int


def _slot_key(day: int, period: int) -> str:
    return f"{day}:{period}"


def _availability_index(av: Dict[str, List[Dict[str, int]]]) -> Dict[str, set[str]]:
    idx: Dict[str, set[str]] = {}
    for teacher, slots in av.items():
        idx[teacher] = {_slot_key(int(s['day']), int(s['period'])) for s in slots}
    return idx


def _build_slots(days: int, periods_per_day: int) -> List[Slot]:
    return [Slot(d, p) for d in range(1, days + 1) for p in range(1, periods_per_day + 1)]


def _can_place(
    lesson: Lesson,
    slot: Slot,
    room_id: str,
    teacher_slot: set[Tuple[str, int, int]],
    class_slot: set[Tuple[str, int, int]],
    room_slot: set[Tuple[str, int, int]],
    teacher_day_load: Dict[Tuple[str, int], int],
    class_day_load: Dict[Tuple[str, int], int],
    availability: Dict[str, set[str]],
    max_teacher_day: Dict[str, int],
    max_class_day: Dict[str, int],
) -> Tuple[bool, str]:
    t_key = (lesson.teacherId, slot.day, slot.period)
    c_key = (lesson.classId, slot.day, slot.period)
    r_key = (room_id, slot.day, slot.period)

    if t_key in teacher_slot:
        return False, 'teacher_conflict'
    if c_key in class_slot:
        return False, 'class_conflict'
    if r_key in room_slot:
        return False, 'room_conflict'

    if lesson.teacherId in availability:
        if _slot_key(slot.day, slot.period) not in availability[lesson.teacherId]:
            return False, 'teacher_unavailable'

    tmax = max_teacher_day.get(lesson.teacherId)
    if tmax is not None and teacher_day_load[(lesson.teacherId, slot.day)] >= tmax:
        return False, 'teacher_max_periods_per_day'

    cmax = max_class_day.get(lesson.classId)
    if cmax is not None and class_day_load[(lesson.classId, slot.day)] >= cmax:
        return False, 'class_max_periods_per_day'

    return True, ''


def _soft_penalties(assignments: List[Dict[str, Any]], periods_per_day: int) -> List[Dict[str, Any]]:
    penalties: List[Dict[str, Any]] = []

    # Teacher gaps (free periods between classes in same day)
    by_teacher_day: Dict[Tuple[str, int], List[int]] = defaultdict(list)
    by_class_day: Dict[Tuple[str, int], List[int]] = defaultdict(list)
    by_class_subject_day: Dict[Tuple[str, str, int], int] = Counter()

    teacher_rooms: Dict[str, set[str]] = defaultdict(set)

    for a in assignments:
        by_teacher_day[(a['teacherId'], a['day'])].append(a['period'])
        by_class_day[(a['classId'], a['day'])].append(a['period'])
        by_class_subject_day[(a['classId'], a['subjectId'], a['day'])] += 1
        teacher_rooms[a['teacherId']].add(a['roomId'])

    teacher_gap_pen = 0
    for _k, ps in by_teacher_day.items():
        s = sorted(ps)
        teacher_gap_pen += sum(max(0, s[i + 1] - s[i] - 1) for i in range(len(s) - 1))

    class_gap_pen = 0
    for _k, ps in by_class_day.items():
        s = sorted(ps)
        class_gap_pen += sum(max(0, s[i + 1] - s[i] - 1) for i in range(len(s) - 1))

    # Subject distribution: penalize concentration >2 lessons/day for same subject-class
    subject_distribution_pen = 0
    for _k, c in by_class_subject_day.items():
        if c > 2:
            subject_distribution_pen += (c - 2)

    # Teacher room instability: multiple rooms/day
    room_stability_pen = 0
    for _teacher, rooms in teacher_rooms.items():
        if len(rooms) > 1:
            room_stability_pen += (len(rooms) - 1)

    penalties.append({'type': 'teacher_gaps', 'penalty': teacher_gap_pen, 'weight': 5})
    penalties.append({'type': 'class_gaps', 'penalty': class_gap_pen, 'weight': 5})
    penalties.append({'type': 'subject_distribution', 'penalty': subject_distribution_pen, 'weight': 3})
    penalties.append({'type': 'teacher_room_stability', 'penalty': room_stability_pen, 'weight': 1})

    return penalties


@app.get('/health')
def health():
    return {'ok': True, 'service': 'solver', 'phase': 3}


@app.post('/solve', response_model=SolveResponse)
def solve(req: SolveRequest):
    slots = _build_slots(req.days, req.periodsPerDay)

    availability = _availability_index(req.constraints.teacherAvailability)
    max_teacher_day = req.constraints.teacherMaxPeriodsPerDay
    max_class_day = req.constraints.classMaxPeriodsPerDay

    teacher_slot: set[Tuple[str, int, int]] = set()
    class_slot: set[Tuple[str, int, int]] = set()
    room_slot: set[Tuple[str, int, int]] = set()

    teacher_day_load: Dict[Tuple[str, int], int] = defaultdict(int)
    class_day_load: Dict[Tuple[str, int], int] = defaultdict(int)

    assignments: List[Dict[str, Any]] = []
    hard_violations: List[Dict[str, Any]] = []

    # Seed deterministic traversal
    start = req.seed % max(1, len(slots))
    ordered_slots = slots[start:] + slots[:start]

    # Apply pinned placements first
    for pin in req.pinned:
        day = int(pin['day'])
        period = int(pin['period'])
        room_id = pin.get('roomId') or f"room_{pin.get('classId', 'X')}"
        t = pin.get('teacherId')
        c = pin.get('classId')

        if t:
            teacher_slot.add((t, day, period))
            teacher_day_load[(t, day)] += 1
        if c:
            class_slot.add((c, day, period))
            class_day_load[(c, day)] += 1
        room_slot.add((room_id, day, period))
        assignments.append({**pin, 'roomId': room_id, 'pinned': True})

    for lesson in req.lessons:
        forced = req.constraints.fixedPeriods.get(lesson.id) if req.constraints.fixedPeriods else None
        if forced:
            lesson = lesson.model_copy(update={'fixedDay': int(forced['day']), 'fixedPeriod': int(forced['period'])})

        room_id = lesson.preferredRoomId or f"room_{lesson.classId}"
        candidate_slots = ordered_slots
        if lesson.fixedDay and lesson.fixedPeriod:
            candidate_slots = [Slot(lesson.fixedDay, lesson.fixedPeriod)]

        placed = False
        failure_reasons = Counter()

        for slot in candidate_slots:
            # Lab double-period support: needs current + next period free
            if lesson.isLabDouble and slot.period >= req.periodsPerDay:
                failure_reasons['lab_double_out_of_bounds'] += 1
                continue

            ok, reason = _can_place(
                lesson,
                slot,
                room_id,
                teacher_slot,
                class_slot,
                room_slot,
                teacher_day_load,
                class_day_load,
                availability,
                max_teacher_day,
                max_class_day,
            )
            if not ok:
                failure_reasons[reason] += 1
                continue

            if lesson.isLabDouble:
                next_slot = Slot(slot.day, slot.period + 1)
                ok2, reason2 = _can_place(
                    lesson,
                    next_slot,
                    room_id,
                    teacher_slot,
                    class_slot,
                    room_slot,
                    teacher_day_load,
                    class_day_load,
                    availability,
                    max_teacher_day,
                    max_class_day,
                )
                if not ok2:
                    failure_reasons[f'lab_double_{reason2}'] += 1
                    continue

                for s in (slot, next_slot):
                    teacher_slot.add((lesson.teacherId, s.day, s.period))
                    class_slot.add((lesson.classId, s.day, s.period))
                    room_slot.add((room_id, s.day, s.period))
                    teacher_day_load[(lesson.teacherId, s.day)] += 1
                    class_day_load[(lesson.classId, s.day)] += 1
                    assignments.append({
                        'lessonId': lesson.id,
                        'classId': lesson.classId,
                        'teacherId': lesson.teacherId,
                        'subjectId': lesson.subjectId,
                        'day': s.day,
                        'period': s.period,
                        'roomId': room_id,
                        'pinned': False,
                        'isLabDouble': True,
                    })
                placed = True
                break

            teacher_slot.add((lesson.teacherId, slot.day, slot.period))
            class_slot.add((lesson.classId, slot.day, slot.period))
            room_slot.add((room_id, slot.day, slot.period))
            teacher_day_load[(lesson.teacherId, slot.day)] += 1
            class_day_load[(lesson.classId, slot.day)] += 1
            assignments.append({
                'lessonId': lesson.id,
                'classId': lesson.classId,
                'teacherId': lesson.teacherId,
                'subjectId': lesson.subjectId,
                'day': slot.day,
                'period': slot.period,
                'roomId': room_id,
                'pinned': False,
                'isLabDouble': False,
            })
            placed = True
            break

        if not placed:
            reason = failure_reasons.most_common(1)[0][0] if failure_reasons else 'no_feasible_slot'
            hard_violations.append({
                'type': 'unscheduled_lesson',
                'lessonId': lesson.id,
                'classId': lesson.classId,
                'teacherId': lesson.teacherId,
                'subjectId': lesson.subjectId,
                'reason': reason,
                'attemptedSlots': len(candidate_slots),
            })

    penalties = _soft_penalties(assignments, req.periodsPerDay)
    soft_penalty = sum(int(p['penalty']) * int(p['weight']) for p in penalties)

    status = 'success' if not hard_violations else 'partial'
    score = -1_000_000_000 * len(hard_violations) - soft_penalty

    return SolveResponse(
        schoolId=req.schoolId,
        status=status,
        hardViolations=hard_violations,
        softPenaltyBreakdown=penalties,
        assignments=assignments,
        score=score,
    )
