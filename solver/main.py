from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title='SmartTime Solver', version='0.4.0')


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


class Room(BaseModel):
    id: str
    roomType: Optional[str] = None


class ConstraintConfig(BaseModel):
    teacherAvailability: Dict[str, List[Dict[str, int]]] = Field(default_factory=dict)
    teacherMaxPeriodsPerDay: Dict[str, int] = Field(default_factory=dict)
    classMaxPeriodsPerDay: Dict[str, int] = Field(default_factory=dict)
    fixedPeriods: Dict[str, Dict[str, int]] = Field(default_factory=dict)
    subjectDailyLimit: Dict[str, int] = Field(default_factory=dict)  # key: classId:subjectId
    teacherMaxConsecutivePeriods: Dict[str, int] = Field(default_factory=dict)
    classMaxConsecutivePeriods: Dict[str, int] = Field(default_factory=dict)
    teacherNoLastPeriodMaxPerWeek: Dict[str, int] = Field(default_factory=dict)


class SolveRequest(BaseModel):
    schoolId: str
    days: int = 5
    periodsPerDay: int = 8
    lessons: List[Lesson]
    rooms: List[Room] = Field(default_factory=list)
    constraints: ConstraintConfig = Field(default_factory=ConstraintConfig)
    pinned: List[Dict[str, Any]] = Field(default_factory=list)
    seed: int = 7


class SolveResponse(BaseModel):
    schoolId: str
    status: str
    hardViolations: List[Dict[str, Any]]
    softPenaltyBreakdown: List[Dict[str, Any]]
    assignments: List[Dict[str, Any]]
    diagnostics: Dict[str, Any] = Field(default_factory=dict)
    score: int


@dataclass(frozen=True)
class Slot:
    day: int
    period: int


def _slot_key(day: int, period: int) -> str:
    return f'{day}:{period}'


def _availability_index(av: Dict[str, List[Dict[str, int]]]) -> Dict[str, set[str]]:
    idx: Dict[str, set[str]] = {}
    for teacher, slots in av.items():
        idx[teacher] = {_slot_key(int(s['day']), int(s['period'])) for s in slots}
    return idx


def _build_slots(days: int, periods_per_day: int) -> List[Slot]:
    return [Slot(d, p) for d in range(1, days + 1) for p in range(1, periods_per_day + 1)]


def _consecutive_run_length(periods: List[int], pivot: int) -> int:
    s = set(periods)
    run = 1
    left = pivot - 1
    right = pivot + 1
    while left in s:
        run += 1
        left -= 1
    while right in s:
        run += 1
        right += 1
    return run


def _consecutive_overflow(periods: List[int], limit: int) -> int:
    if not periods or limit <= 0:
        return 0
    s = sorted(set(periods))
    overflow = 0
    run = 1
    for i in range(1, len(s)):
        if s[i] == s[i - 1] + 1:
            run += 1
        else:
            if run > limit:
                overflow += run - limit
            run = 1
    if run > limit:
        overflow += run - limit
    return overflow


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
    class_subject_day_count: Dict[Tuple[str, str, int], int],
    subject_daily_limit: Dict[str, int],
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

    subj_key = f'{lesson.classId}:{lesson.subjectId}'
    subj_limit = subject_daily_limit.get(subj_key)
    if subj_limit is not None:
        if class_subject_day_count[(lesson.classId, lesson.subjectId, slot.day)] >= subj_limit:
            return False, 'subject_daily_limit'

    return True, ''


def _trial_respects_hard_constraints(
    trial: List[Dict[str, Any]],
    constraints: ConstraintConfig,
    availability: Dict[str, set[str]],
) -> bool:
    teacher_day_load: Dict[Tuple[str, int], int] = defaultdict(int)
    class_day_load: Dict[Tuple[str, int], int] = defaultdict(int)
    class_subject_day_count: Dict[Tuple[str, str, int], int] = defaultdict(int)
    for t in trial:
        teacher_day_load[(t['teacherId'], t['day'])] += 1
        class_day_load[(t['classId'], t['day'])] += 1
        class_subject_day_count[(t['classId'], t['subjectId'], t['day'])] += 1

    for t in trial:
        if t['teacherId'] in availability:
            if _slot_key(t['day'], t['period']) not in availability[t['teacherId']]:
                return False
        tcap = constraints.teacherMaxPeriodsPerDay.get(t['teacherId'])
        if tcap is not None and teacher_day_load[(t['teacherId'], t['day'])] > tcap:
            return False
        ccap = constraints.classMaxPeriodsPerDay.get(t['classId'])
        if ccap is not None and class_day_load[(t['classId'], t['day'])] > ccap:
            return False
        scap = constraints.subjectDailyLimit.get(f"{t['classId']}:{t['subjectId']}")
        if scap is not None and class_subject_day_count[(t['classId'], t['subjectId'], t['day'])] > scap:
            return False
    return True


def _resolve_room(lesson: Lesson, rooms: List[Room]) -> Optional[str]:
    if lesson.preferredRoomId:
        return lesson.preferredRoomId
    if lesson.requiredRoomType:
        for room in rooms:
            if room.roomType == lesson.requiredRoomType:
                return room.id
        return None
    return f'room_{lesson.classId}'


def _soft_penalties(
    assignments: List[Dict[str, Any]],
    periods_per_day: int,
    teacher_max_consecutive: Dict[str, int],
    class_max_consecutive: Dict[str, int],
    teacher_last_period_cap: Dict[str, int],
) -> List[Dict[str, Any]]:
    penalties: List[Dict[str, Any]] = []

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
    for ps in by_teacher_day.values():
        s = sorted(ps)
        teacher_gap_pen += sum(max(0, s[i + 1] - s[i] - 1) for i in range(len(s) - 1))

    class_gap_pen = 0
    for ps in by_class_day.values():
        s = sorted(ps)
        class_gap_pen += sum(max(0, s[i + 1] - s[i] - 1) for i in range(len(s) - 1))

    subject_distribution_pen = 0
    for c in by_class_subject_day.values():
        if c > 2:
            subject_distribution_pen += (c - 2)

    room_stability_pen = 0
    for rooms in teacher_rooms.values():
        if len(rooms) > 1:
            room_stability_pen += (len(rooms) - 1)

    teacher_consecutive_pen = 0
    for (teacher, _day), periods in by_teacher_day.items():
        limit = teacher_max_consecutive.get(teacher)
        if not limit:
            continue
        teacher_consecutive_pen += _consecutive_overflow(periods, limit)

    class_consecutive_pen = 0
    for (class_id, _day), periods in by_class_day.items():
        limit = class_max_consecutive.get(class_id)
        if not limit:
            continue
        class_consecutive_pen += _consecutive_overflow(periods, limit)

    teacher_last_period_count = Counter()
    for a in assignments:
        if a['period'] == periods_per_day:
            teacher_last_period_count[a['teacherId']] += 1

    teacher_last_period_pen = 0
    for teacher, count in teacher_last_period_count.items():
        cap = teacher_last_period_cap.get(teacher)
        if cap is not None and count > cap:
            teacher_last_period_pen += (count - cap)

    penalties.append({'type': 'teacher_gaps', 'penalty': teacher_gap_pen, 'weight': 5})
    penalties.append({'type': 'class_gaps', 'penalty': class_gap_pen, 'weight': 5})
    penalties.append({'type': 'subject_distribution', 'penalty': subject_distribution_pen, 'weight': 3})
    penalties.append({'type': 'teacher_room_stability', 'penalty': room_stability_pen, 'weight': 1})
    penalties.append({'type': 'teacher_consecutive_overload', 'penalty': teacher_consecutive_pen, 'weight': 4})
    penalties.append({'type': 'class_consecutive_overload', 'penalty': class_consecutive_pen, 'weight': 3})
    penalties.append({'type': 'teacher_last_period_overflow', 'penalty': teacher_last_period_pen, 'weight': 2})

    return penalties


def _score_penalties(penalties: List[Dict[str, Any]]) -> int:
    return sum(int(p['penalty']) * int(p['weight']) for p in penalties)


def _optimize_assignments(
    assignments: List[Dict[str, Any]],
    req: SolveRequest,
    availability: Dict[str, set[str]],
    rounds: int = 1,
) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    best = list(assignments)
    base = _score_penalties(
        _soft_penalties(
            best,
            req.periodsPerDay,
            req.constraints.teacherMaxConsecutivePeriods,
            req.constraints.classMaxConsecutivePeriods,
            req.constraints.teacherNoLastPeriodMaxPerWeek,
        )
    )
    improved = 0

    for _ in range(rounds):
        changed = False
        for i in range(len(best)):
            a = best[i]
            if a.get('pinned'):
                continue
            for j in range(i + 1, len(best)):
                b = best[j]
                if b.get('pinned'):
                    continue
                if a['isLabDouble'] or b['isLabDouble']:
                    continue

                if a['day'] == b['day'] and a['period'] == b['period']:
                    continue

                trial = [dict(x) for x in best]
                trial[i]['day'], trial[j]['day'] = trial[j]['day'], trial[i]['day']
                trial[i]['period'], trial[j]['period'] = trial[j]['period'], trial[i]['period']

                # Quick conflict validation after swap
                seen_teacher = set()
                seen_class = set()
                seen_room = set()
                valid = True
                for t in trial:
                    tk = (t['teacherId'], t['day'], t['period'])
                    ck = (t['classId'], t['day'], t['period'])
                    rk = (t['roomId'], t['day'], t['period'])
                    if tk in seen_teacher or ck in seen_class or rk in seen_room:
                        valid = False
                        break
                    seen_teacher.add(tk)
                    seen_class.add(ck)
                    seen_room.add(rk)

                if not valid:
                    continue

                if not _trial_respects_hard_constraints(trial, req.constraints, availability):
                    continue

                trial_score = _score_penalties(
                    _soft_penalties(
                        trial,
                        req.periodsPerDay,
                        req.constraints.teacherMaxConsecutivePeriods,
                        req.constraints.classMaxConsecutivePeriods,
                        req.constraints.teacherNoLastPeriodMaxPerWeek,
                    )
                )

                if trial_score < base:
                    best = trial
                    base = trial_score
                    improved += 1
                    changed = True
                    break
            if changed:
                break
        if not changed:
            break

    return best, {'movesAccepted': improved, 'finalSoftPenalty': base}


@app.get('/health')
def health():
    return {'ok': True, 'service': 'solver', 'phase': 3}


@app.post('/solve', response_model=SolveResponse)
def solve(req: SolveRequest):
    if req.days < 1 or req.periodsPerDay < 1:
        raise HTTPException(status_code=400, detail='days and periodsPerDay must be >= 1')

    slots = _build_slots(req.days, req.periodsPerDay)

    availability = _availability_index(req.constraints.teacherAvailability)
    max_teacher_day = req.constraints.teacherMaxPeriodsPerDay
    max_class_day = req.constraints.classMaxPeriodsPerDay

    teacher_slot: set[Tuple[str, int, int]] = set()
    class_slot: set[Tuple[str, int, int]] = set()
    room_slot: set[Tuple[str, int, int]] = set()

    teacher_day_load: Dict[Tuple[str, int], int] = defaultdict(int)
    class_day_load: Dict[Tuple[str, int], int] = defaultdict(int)
    class_subject_day_count: Dict[Tuple[str, str, int], int] = defaultdict(int)

    assignments: List[Dict[str, Any]] = []
    hard_violations: List[Dict[str, Any]] = []

    start = req.seed % max(1, len(slots))
    ordered_slots = slots[start:] + slots[:start]

    # Apply fixedPeriods overrides up-front so the heuristic ordering below
    # treats those lessons as fixed and schedules them before unconstrained ones.
    resolved_lessons: List[Lesson] = []
    for lesson in req.lessons:
        forced = req.constraints.fixedPeriods.get(lesson.id) if req.constraints.fixedPeriods else None
        if forced:
            lesson = lesson.model_copy(update={
                'fixedDay': int(forced['day']),
                'fixedPeriod': int(forced['period']),
            })
        resolved_lessons.append(lesson)

    # Fixed and more constrained lessons first (FET-inspired heuristic ordering)
    ordered_lessons = sorted(
        resolved_lessons,
        key=lambda l: (
            0 if (l.fixedDay and l.fixedPeriod) else 1,
            0 if l.requiredRoomType else 1,
            0 if l.isLabDouble else 1,
            l.id,
        ),
    )

    for pin_index, pin in enumerate(req.pinned):
        day = int(pin['day'])
        period = int(pin['period'])
        is_lab = bool(pin.get('isLabDouble', False))

        if day < 1 or day > req.days or period < 1 or period > req.periodsPerDay:
            hard_violations.append({
                'type': 'invalid_pin',
                'pin': pin,
                'reason': 'pin_out_of_range',
            })
            continue
        if is_lab and period + 1 > req.periodsPerDay:
            hard_violations.append({
                'type': 'invalid_pin',
                'pin': pin,
                'reason': 'lab_double_out_of_bounds',
            })
            continue

        class_id = pin.get('classId')
        if pin.get('roomId'):
            room_id = pin['roomId']
        elif class_id:
            room_id = f'room_{class_id}'
        else:
            room_id = f'room_pin_{pin_index}'

        t = pin.get('teacherId')
        c = class_id
        s = pin.get('subjectId')

        pin_slots = [(day, period)]
        if is_lab:
            pin_slots.append((day, period + 1))

        conflict_reason: Optional[str] = None
        for d, p in pin_slots:
            if t and (t, d, p) in teacher_slot:
                conflict_reason = 'teacher_conflict'
                break
            if c and (c, d, p) in class_slot:
                conflict_reason = 'class_conflict'
                break
            if (room_id, d, p) in room_slot:
                conflict_reason = 'room_conflict'
                break

        if conflict_reason:
            hard_violations.append({
                'type': 'invalid_pin',
                'pin': pin,
                'reason': conflict_reason,
            })
            continue

        for d, p in pin_slots:
            if t:
                teacher_slot.add((t, d, p))
                teacher_day_load[(t, d)] += 1
            if c:
                class_slot.add((c, d, p))
                class_day_load[(c, d)] += 1
            if c and s:
                class_subject_day_count[(c, s, d)] += 1
            room_slot.add((room_id, d, p))
            assignments.append({
                **pin,
                'day': d,
                'period': p,
                'roomId': room_id,
                'pinned': True,
                'isLabDouble': is_lab,
            })

    unscheduled_reasons = Counter()

    for lesson in ordered_lessons:
        room_id = _resolve_room(lesson, req.rooms)
        if room_id is None:
            unscheduled_reasons['no_matching_room_type'] += 1
            hard_violations.append({
                'type': 'unscheduled_lesson',
                'lessonId': lesson.id,
                'classId': lesson.classId,
                'teacherId': lesson.teacherId,
                'subjectId': lesson.subjectId,
                'reason': 'no_matching_room_type',
                'attemptedSlots': 0,
            })
            continue

        candidate_slots = ordered_slots
        if lesson.fixedDay and lesson.fixedPeriod:
            candidate_slots = [Slot(lesson.fixedDay, lesson.fixedPeriod)]

        placed = False
        failure_reasons = Counter()

        for slot in candidate_slots:
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
                class_subject_day_count,
                req.constraints.subjectDailyLimit,
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
                    class_subject_day_count,
                    req.constraints.subjectDailyLimit,
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
                    class_subject_day_count[(lesson.classId, lesson.subjectId, s.day)] += 1
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
            class_subject_day_count[(lesson.classId, lesson.subjectId, slot.day)] += 1
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
            unscheduled_reasons[reason] += 1
            hard_violations.append({
                'type': 'unscheduled_lesson',
                'lessonId': lesson.id,
                'classId': lesson.classId,
                'teacherId': lesson.teacherId,
                'subjectId': lesson.subjectId,
                'reason': reason,
                'attemptedSlots': len(candidate_slots),
            })

    assignments, optimization = _optimize_assignments(assignments, req, availability, rounds=2)

    penalties = _soft_penalties(
        assignments,
        req.periodsPerDay,
        req.constraints.teacherMaxConsecutivePeriods,
        req.constraints.classMaxConsecutivePeriods,
        req.constraints.teacherNoLastPeriodMaxPerWeek,
    )
    soft_penalty = _score_penalties(penalties)

    status = 'success' if not hard_violations else 'partial'
    score = -1_000_000_000 * len(hard_violations) - soft_penalty

    return SolveResponse(
        schoolId=req.schoolId,
        status=status,
        hardViolations=hard_violations,
        softPenaltyBreakdown=penalties,
        assignments=assignments,
        diagnostics={
            'solverVersion': app.version,
            'unscheduledReasonCounts': dict(unscheduled_reasons),
            'optimization': optimization,
            'totals': {
                'lessonsRequested': len(req.lessons),
                'assignedEntries': len(assignments),
                'hardViolations': len(hard_violations),
            },
        },
        score=score,
    )
