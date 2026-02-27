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
- Functions Jest suites: 5 passed, 12 tests total.
- Solver Pytest suites: 2 passed.

## Completed additionally
- Repository service tests added (`repositories.test.ts`) for Firestore-facing service layer via db mocks.
- Admin solver page now shows published badge and polls solver jobs/versions.
- Android app initializes Firebase in `main.dart` and includes email/password sign-in + account creation flow.

## Next
1. Replace db mocks with Firestore emulator-backed integration tests.
2. Add Google sign-in flow and sign-out UX in Android.
3. Add admin-level conflict dashboard UI wired to solver diagnostics.
