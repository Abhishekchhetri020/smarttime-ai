# Phase 3 Hardening Progress

## Completed in this pass
- Added timetable publish service (`publishTimetable`) with archive-previous behavior.
- Added routes:
  - `POST /schools/:schoolId/timetables/:versionId/publish`
  - `GET /schools/:schoolId/timetables/published/latest`
- Added route-level tests for timetable publish/latest APIs.
- Expanded backend test suite to 7 passing tests total.
- Android role-based screen routing from auth claims now returns role-specific screens.

## Current test status
- Functions Jest suites: 3 passed, 7 tests total.
- Solver Pytest suites: 2 passed.

## Next
1. Hook Android timetable screen to `published/latest` API payload and render grid.
2. Add Firestore emulator-run tests for repository services.
3. Add admin publish button + published version indicator.
4. Add API error-handling middleware and standardized error format.
