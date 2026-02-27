from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Any, Tuple, Optional

app = FastAPI(title='SmartTime Solver', version='0.2.0')

class Lesson(BaseModel):
    id: str
    classId: str
    teacherId: str
    subjectId: str
    preferredRoomId: Optional[str] = None

class SolveRequest(BaseModel):
    schoolId: str
    days: int = 5
    periodsPerDay: int = 8
    lessons: List[Lesson]
    constraints: List[Dict[str, Any]] = []
    pinned: List[Dict[str, Any]] = []

class SolveResponse(BaseModel):
    schoolId: str
    status: str
    hardViolations: List[Dict[str, Any]]
    softPenaltyBreakdown: List[Dict[str, Any]]
    assignments: List[Dict[str, Any]]
    score: int

@app.get('/health')
def health():
    return {'ok': True, 'service': 'solver', 'phase': 2}

@app.post('/solve', response_model=SolveResponse)
def solve(req: SolveRequest):
    slots = [(d, p) for d in range(1, req.days + 1) for p in range(1, req.periodsPerDay + 1)]

    teacher_slot: set[Tuple[str, int, int]] = set()
    class_slot: set[Tuple[str, int, int]] = set()
    room_slot: set[Tuple[str, int, int]] = set()

    assignments: List[Dict[str, Any]] = []
    hard_violations: List[Dict[str, Any]] = []

    # Apply pinned first
    for pin in req.pinned:
        assignments.append(pin)
        tid = pin.get('teacherId')
        cid = pin.get('classId')
        rid = pin.get('roomId')
        d = int(pin.get('day'))
        p = int(pin.get('period'))
        if tid: teacher_slot.add((tid, d, p))
        if cid: class_slot.add((cid, d, p))
        if rid: room_slot.add((rid, d, p))

    slot_idx = 0
    for lesson in req.lessons:
        placed = False
        for _ in range(len(slots)):
            d, p = slots[slot_idx % len(slots)]
            slot_idx += 1

            t_key = (lesson.teacherId, d, p)
            c_key = (lesson.classId, d, p)
            r_key = (lesson.preferredRoomId or f"room_{lesson.classId}", d, p)

            if t_key in teacher_slot or c_key in class_slot or r_key in room_slot:
                continue

            teacher_slot.add(t_key)
            class_slot.add(c_key)
            room_slot.add(r_key)
            assignments.append({
                'lessonId': lesson.id,
                'classId': lesson.classId,
                'teacherId': lesson.teacherId,
                'subjectId': lesson.subjectId,
                'day': d,
                'period': p,
                'roomId': lesson.preferredRoomId or f"room_{lesson.classId}",
                'pinned': False,
            })
            placed = True
            break

        if not placed:
            hard_violations.append({
                'type': 'unscheduled_lesson',
                'lessonId': lesson.id,
                'reason': 'no_free_slot_without_conflict'
            })

    soft_penalty = 0
    soft_breakdown = [{'type': 'load_balance', 'penalty': soft_penalty}]

    status = 'success' if not hard_violations else 'partial'
    score = -1000000000 * len(hard_violations) - soft_penalty

    return SolveResponse(
        schoolId=req.schoolId,
        status=status,
        hardViolations=hard_violations,
        softPenaltyBreakdown=soft_breakdown,
        assignments=assignments,
        score=score,
    )
