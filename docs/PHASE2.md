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
1. Replace temporary fire-and-forget trigger with Pub/Sub worker execution (current: async immediate run).
2. Firebase custom claims management flow (admin utility).
3. Expand admin UI from baseline pages to full CRUD forms with validation.
4. Wire Android auth gate to FirebaseAuth stream + role claims.
5. CI pipeline for integration tests (solver tests added; functions tests pending).
