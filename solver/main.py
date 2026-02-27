from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Any

app = FastAPI(title='SmartTime Solver', version='0.1.0')

class SolveRequest(BaseModel):
    schoolId: str
    periodsPerWeek: int
    lessons: List[Dict[str, Any]]
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
    return {'ok': True, 'service': 'solver'}

@app.post('/solve', response_model=SolveResponse)
def solve(req: SolveRequest):
    # Phase 1 stub: deterministic placeholder output
    assignments = []
    for i, lesson in enumerate(req.lessons[: min(len(req.lessons), req.periodsPerWeek)]):
        assignments.append({
            'lessonId': lesson.get('id', f'L{i+1}'),
            'day': (i % 5) + 1,
            'period': (i % max(1, req.periodsPerWeek // 5)) + 1,
            'roomId': lesson.get('preferredRoomId')
        })

    return SolveResponse(
        schoolId=req.schoolId,
        status='phase1_stubbed',
        hardViolations=[],
        softPenaltyBreakdown=[{'type': 'load_balance', 'penalty': 0}],
        assignments=assignments,
        score=0
    )
