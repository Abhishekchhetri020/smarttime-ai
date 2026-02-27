# Phase 2 Implementation (In Progress Baseline)

## Delivered in this step
- Auth middleware upgraded for bearer token + dev fallback headers.
- Role-enforced API routes with real Firestore-backed list/upsert for key entities.
- Solver jobs persisted to Firestore (`solverJobs` collection).
- Solver upgraded from static stub to conflict-aware greedy allocator with unscheduled diagnostics.
- Admin web got data client + school page + teachers CRUD page.
- Android Flutter app initialized with read-only timetable screen placeholder.
- Firestore security rules and indexes templates added.

## Remaining for full Phase 2 completion
1. Pub/Sub trigger from job create -> invoke solver -> persist timetable version.
2. Firebase custom claims management flow.
3. Admin pages for classes/subjects/constraints + solver run UI.
4. Android auth + published timetable Firestore read.
5. Integration tests (functions + solver contracts).
