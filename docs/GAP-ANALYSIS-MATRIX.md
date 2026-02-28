# Gap Analysis Matrix — Open-Source Timetabling vs SmartTime AI

## Sources Reviewed
- `sisardor/fet-cli` (FET-compatible constraint-rich CLI workflows)
- `kiegroup/optaplanner-quickstarts` (hard/soft scoring, local search patterns, diagnostics)
- `unitime/unitime` (enterprise workflow breadth, multi-entity governance) — used as optional architecture reference

## Capability Matrix

| Capability (Reference) | Open-source baseline | SmartTime before this pass | Implemented in this pass | Remaining gap / phased plan |
|---|---|---|---|---|
| Deterministic seed-based solving (FET/Opta) | Reproducible runs with fixed seed | Present (basic seed offset) | Preserved and expanded with constrained lesson ordering | Phase 2: randomized multi-start with best-of-N selection |
| Constraint-rich hard rules (FET) | Large catalog: availability, fixed periods, room/subject constraints | Availability + daily caps + fixed slot + conflicts | Added `subjectDailyLimit` hard rule and strict `requiredRoomType` matching using room catalog | Phase 2: min-days-between-activities, subject spread by week |
| Room typing (FET/UniTime) | explicit room features and compatibility | `requiredRoomType` existed in lesson model but not enforced | Enforced room-type compatibility; unscheduled reason emitted when no room exists | Phase 2: room capacity/building distance penalties |
| Soft scoring with weighted penalties (OptaPlanner) | Multi-constraint weighted score | Basic penalties (gaps/distribution/stability) | Added teacher/class consecutive overload + last-period overflow penalties | Phase 2: configurable weights per school and tuning UI |
| Post-construction optimization (Opta local search) | Move evaluation (swap/change) | None (single-pass greedy) | Added safe swap-based local improvement pass (conflict-checked) | Phase 2: hill-climb with tabu / late acceptance |
| Failure diagnostics (FET verbose logs) | Detailed unsat/failure traces | Per-lesson failure reason only | Added aggregate reason counters + optimization summary in `diagnostics` | Phase 2: per-constraint contribution timeline |
| Job observability (Opta/enterprise schedulers) | run metadata, timing, score trends | score + violation counts | Added `startedAt/completedAt/runDurationMs`, persisted solver diagnostics | Phase 2: historical trend dashboard + alerts |
| Admin workflow controls (UniTime-style operations) | rerun/requeue, inspection tools | create job + run endpoint only | Added API endpoints for job diagnostics + requeue | Phase 2: cancel job, promote/rollback timetable policy gates |
| Mobile consumption of diagnostics | Often web-first in OSS, mobile optional | mobile reads published timetable entries only | Added Android repo method to fetch latest solver diagnostics | Phase 2: in-app diagnostics cards and quality indicators |
| Test safety net | Unit + integration in all references | basic API + solver tests | Added solver tests for new constraints/diagnostics + backend route tests | Phase 2: emulator CI for diagnostics routes and solver regression corpus |

## Net Assessment
- **Backend/solver maturity improved meaningfully** toward FET/Opta patterns while keeping current structure.
- SmartTime still lacks **advanced search strategies and full institutional policy modeling** (UniTime-level breadth), but now has a safer foundation for iterative rollout.
