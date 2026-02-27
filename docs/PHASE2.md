# Phase 2 Implementation (In Progress Baseline)

## Delivered in this step
- Auth middleware upgraded for bearer token + dev fallback headers.
- Role-enforced API routes with real Firestore-backed list/upsert for key entities.
- Solver jobs persisted to Firestore (`solverJobs` collection).
- Solver upgraded from static stub to conflict-aware greedy allocator with unscheduled diagnostics.
- Admin web got data client + school page + teachers CRUD page.
- Android Flutter app initialized with read-only timetable screen placeholder.
- Firestore security rules and indexes templates added.

## Phase 2 completion status
### Completed
1. Pub/Sub-based solver queue + worker trigger (`solverWorker`).
2. Firebase custom claims utility script (`setRoleClaims.ts`).
3. Admin baseline CRUD pages for teachers/classes/subjects/constraints + solver run page.
4. Android auth gate wired to FirebaseAuth stream and token role claims.
5. CI workflow added for solver tests + functions TypeScript build.

### Remaining (carry to Phase 3 hardening)
1. End-to-end functions integration tests (API + Firestore emulator).
2. Full form validation/UX polish on admin screens.
3. Android full Firebase initialization + role-based navigation screens.
