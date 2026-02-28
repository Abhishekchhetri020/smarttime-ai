# SmartTime AI — Timetabling Upgrade PRD

## Goal
Upgrade SmartTime's timetable engine and app workflow to be robust, diagnosable, and production-ready, inspired by FET/OptaPlanner constraint patterns.

## Reference Study Notes
- **fet-cli / FET**: strong school-specific constraints + deterministic generation with rich conflict explanations.
- **OptaPlanner school-timetabling**: explicit hard/soft constraint split and score-based optimization.
- **UniTime (high-level)**: enterprise timetabling model with heavy diagnostics and policy-driven scheduling.

## Current Model (repo)
- Entities: teachers, classes, subjects, rooms, constraints, solverJobs, timetables, entries
- Solver contract (`POST /solve`):
  - Input: schoolId, days, periodsPerDay, lessons, constraints, pinned, seed
  - Output: assignments, hardViolations, softPenaltyBreakdown, score, status

## Must-Have Constraints
### Hard constraints
1. Teacher clash (same teacher, same slot)
2. Class clash (same class, same slot)
3. Room clash (same room, same slot)
4. Teacher availability
5. Max periods/day for teacher
6. Max periods/day for class
7. Fixed periods (lesson-level fixed day/period)
8. Lab double periods (consecutive periods required)

### Soft constraints
1. Teacher free-period gaps (minimize)
2. Class free-period gaps (minimize)
3. Subject distribution (avoid concentration of same subject in one day)
4. Teacher room stability (prefer fewer rooms)

## Architecture (target)
- **FastAPI Solver**: deterministic greedy placement + hard check + soft scoring + diagnostics
- **Firebase Functions**:
  - create solver jobs
  - enqueue/run solver
  - persist timetable versions + diagnostics
  - publish latest version
- **Firestore**:
  - source entities and constraints
  - solverJobs (status + diagnostics)
  - timetables and entries
- **Android**:
  - Incharge/Super Admin console: setup + generate + publish
  - Teacher/Student/Parent read-only timetable views

## Acceptance Criteria
1. Solver output reproducible with same seed.
2. Hard violations always reported with reason.
3. Soft penalties returned as weighted breakdown.
4. Android Generate button triggers backend job without 404.
5. Published timetable is visible in teacher/student/parent views.
