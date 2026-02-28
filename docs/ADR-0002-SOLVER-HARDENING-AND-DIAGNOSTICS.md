# ADR-0002: Solver Hardening + Diagnostics-First Backend Controls

## Status
Accepted (2026-02-28)

## Context
SmartTime solver was functional but minimal:
- single-pass greedy assignment
- limited hard constraints
- coarse diagnostics
- weak operational metadata for solver jobs

Open-source references (FET, OptaPlanner quickstarts, UniTime) consistently show:
1. richer, explicit constraints,
2. hard/soft score separation,
3. iterative optimization after construction,
4. operational diagnostics as first-class outputs.

## Decision
We implement an incremental, production-safe hardening pass:

1. **Data model extensions**
   - Add request-level room catalog (`rooms`) with optional `roomType`.
   - Add new constraint maps:
     - `subjectDailyLimit`
     - `teacherMaxConsecutivePeriods`
     - `classMaxConsecutivePeriods`
     - `teacherNoLastPeriodMaxPerWeek`

2. **Hard constraint expansion**
   - Enforce room type compatibility (`requiredRoomType` -> matching room).
   - Enforce subject daily limits (`classId:subjectId` keyed).

3. **Soft scoring expansion**
   - Add penalties for teacher/class consecutive overload and teacher last-period overflow.

4. **Optimization pass**
   - Add safe swap-based local improvement (conflict-validated, non-destructive, small bounded rounds).

5. **Diagnostics and operations**
   - Include solver diagnostics in response (reason counters, optimization summary, totals).
   - Persist run metadata (`startedAt`, `completedAt`, `runDurationMs`) and solver diagnostics in backend jobs.
   - Add API endpoints:
     - `GET /schools/:schoolId/solver/jobs/:jobId/diagnostics`
     - `POST /schools/:schoolId/solver/jobs/:jobId/requeue`

## Consequences
### Positive
- Better failure explainability and safer rerun workflows.
- Higher-quality schedules without replacing architecture.
- Stronger basis for admin and mobile quality surfaces.

### Trade-offs
- Slightly higher solve time due to optimization pass.
- Additional constraint maps increase payload complexity.

### Risk controls
- Deterministic behavior preserved via seed and bounded rounds.
- New logic covered with unit tests and existing API tests.
- All changes preserve project structure and backward compatibility defaults.
