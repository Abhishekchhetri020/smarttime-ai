# SmartTime AI — RC Evidence Pack (Snapshot)

Date: 2026-02-27

## Test Evidence
- Backend Jest: 5 suites passed, 12 tests passed (plus emulator suites configured)
- Solver Pytest: 2 tests passed
- Emulator integration suites exist:
  - `emulator.smoke.test.ts`
  - `repositories.emulator.test.ts`

## CI Evidence
- CI workflow includes:
  - solver tests
  - functions build + tests
  - firestore emulator test job

## UX/Flow Evidence
- Conflict dashboard supports type filter, severity, suggestions.
- Conflict links now open target editors with prefilled context (`focus`, `hint`, `create`).
- Teachers/Classes/Constraints pages support quick-create mode and inline edit.
- Android timetable displays day×period grid with empty-slot highlighting and legend.

## Operational Evidence
- Launch checklist, test matrix, privacy policy draft, staging runbook, RC checklist present in `docs/`.

## Remaining before release freeze
1. Capture successful GitHub Actions emulator job URL (CI evidence link).
2. Complete role-based UAT sign-off (super admin/incharge/teacher/student/parent).
3. Validate Android production Firebase config and store signing flow.

## Latest execution note
- Emulator integration run executed successfully locally on 2026-02-27 after upgrading to Java 21.
- Command used:
  - `firebase-tools emulators:exec --only firestore "npm test -- --runInBand tests/emulator.smoke.test.ts tests/repositories.emulator.test.ts"`
- Result:
  - `tests/emulator.smoke.test.ts` ✅
  - `tests/repositories.emulator.test.ts` ✅
- Note: `lsof` missing warning appears in emulator startup logs, but run completed successfully.
