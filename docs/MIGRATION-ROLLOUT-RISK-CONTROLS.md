# Migration Notes, Rollout Strategy, and Risk Controls (Solver Hardening v0.4)

## Migration Notes

### API / Payload compatibility
- Existing solver payloads remain valid.
- New fields are optional:
  - `rooms[]`
  - `constraints.subjectDailyLimit`
  - `constraints.teacherMaxConsecutivePeriods`
  - `constraints.classMaxConsecutivePeriods`
  - `constraints.teacherNoLastPeriodMaxPerWeek`
- Backend default-merges payloads to avoid null/shape issues.

### Firestore job documents
- New optional fields on solver job docs:
  - `startedAt`, `completedAt`, `runDurationMs`
  - `diagnostics.solverDiagnostics`

No destructive migration required.

## Rollout Strategy

### Phase A — Shadow diagnostics (recommended first)
1. Deploy backend + solver.
2. Continue current job triggering paths.
3. Read new diagnostics endpoint in admin tooling only.
4. Verify runtime and score distributions for 1 week.

### Phase B — Policy activation
1. Enable `subjectDailyLimit` for pilot schools/classes.
2. Add room catalog for schools with lab specialization.
3. Introduce consecutive/last-period penalties with conservative values.

### Phase C — UI exposure
1. Add admin diagnostics panel for top unscheduled reasons.
2. Add mobile quality snapshot (latest run summary).
3. Define acceptance thresholds per school.

## Risk Controls

### Operational
- Keep requeue endpoint restricted to `super_admin`/`incharge`.
- Track regression signals:
  - increase in `hardViolations`
  - `runDurationMs` outliers
  - downgrade in score trend

### Functional
- Roll out constraints gradually (per school / per term).
- For strict room-type schools, preload room catalog before enabling.
- Maintain fallback runbook: submit job without new constraints if critical scheduling deadline is at risk.

### Testing gate
- Required checks before promoting:
  - `solver/.venv/bin/pytest -q`
  - `backend/functions npm test`
  - `backend/functions npm run build`
  - `android-app/flutter_app flutter test`

## Not feasible in this pass (and why)
- Full OptaPlanner-grade metaheuristics (tabu/late acceptance/simulated annealing): requires larger redesign and calibration infrastructure.
- UniTime-level institutional policy engine (exams, buildings, student sectioning coupling): outside current domain model and would risk destabilizing current release scope.

### Next phased plan
1. Add configurable weights persisted per school.
2. Add multi-start solve strategy and keep best score.
3. Introduce constraint contribution heatmap for admin debugging.
