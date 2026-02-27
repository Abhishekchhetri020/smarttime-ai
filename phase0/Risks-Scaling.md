# SmartTime AI — Risk Assessment & Scaling Strategy

## Top Risks
1. **Constraint explosion / infeasible datasets**
   - Mitigation: feasibility pre-check + priority tiers + diagnostics.

2. **Solver runtime too high for larger schools**
   - Mitigation: async jobs, time-bounded optimization, seeded reruns.

3. **Ambiguous school rules during onboarding**
   - Mitigation: constraint templates + guided setup wizard.

4. **Manual override breaking consistency**
   - Mitigation: pin constraints + validation on every edit + audit logs.

5. **Release risk on Android compatibility**
   - Mitigation: week-7 device matrix tests + crashlytics monitoring.

## Scaling Strategy
### Phase V1 (single-region, standard schools)
- Firestore + Cloud Functions + Cloud Run solver.
- Async job queue via Pub/Sub.

### Phase V1.5 (growth)
- Move heavy analytics to BigQuery.
- Cache published timetable snapshots.
- Separate solver workers by school/job size.

### Phase V2 (multi-school scale)
- Tenant-aware sharding strategy.
- Priority queues for solver jobs.
- SLA tiers (fast/standard generation lanes).

## Reliability Controls
- Retry policy for failed solver jobs.
- Versioned timetable publish/rollback.
- Daily backups/export snapshots.

## Observability
- Cloud Logging + Error Reporting + Crashlytics.
- Metrics: generation success rate, avg solve time, hard-conflict rate, publish latency.
