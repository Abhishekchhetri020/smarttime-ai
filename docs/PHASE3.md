# Phase 3 Hardening Progress

## Completed in this pass
- Added timetable publish service (`publishTimetable`) with archive-previous behavior.
- Added routes:
  - `POST /schools/:schoolId/timetables/:versionId/publish`
  - `GET /schools/:schoolId/timetables/published/latest`
- Added route-level tests for timetable publish/latest APIs.
- Added standardized API error middleware and 404 error format test.
- Added admin solver page support for listing versions and publishing a selected version.
- Android role-based screen routing now maps to role screens and renders published timetable entries via Firestore query.

## Current test status
- Functions Jest suites: 4 passed, 8 tests total.
- Solver Pytest suites: 2 passed.

## Next
1. Firestore emulator-run tests for repository services (`firestoreRepo`, `timetableRepo`).
2. Admin published-version badge + richer status polling UX.
3. Android Firebase init + auth flows (email/password or Google) and production-safe error handling.
