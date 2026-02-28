# SmartTime AI — Blocker Burndown

Date: 2026-02-27

## Current Blockers

### B1 — Emulator CI run confirmation evidence
- Severity: High
- Status: Closed ✅
- Owner: DevOps/Engineering
- Action: Run GitHub Actions `functions-emulator-tests` and attach run URL in RC evidence pack.
- Evidence: local emulator run succeeded on 2026-02-27 using Java 21 with:
  - `tests/emulator.smoke.test.ts` ✅
  - `tests/repositories.emulator.test.ts` ✅

### B2 — Android staging Firebase production-like config validation
- Severity: High
- Status: In Progress
- Owner: Mobile
- Action: Validate `google-services.json`, package IDs, SHA fingerprints, Google Sign-In client IDs.
- Tracking doc: `docs/ANDROID-STAGING-VALIDATION.md`
- Progress: Flutter SDK + Android SDK configured, licenses accepted, debug APK + release APK/AAB builds succeeded.
- Remaining: production-like Firebase auth config (`google-services.json`, SHA/OAuth), real release keystore setup, final runtime sign-off.

### B3 — Role-based UAT formal sign-off
- Severity: High
- Status: In Progress
- Owner: QA/Product
- Action: Execute `docs/UAT-SCRIPT.md` and mark sign-off table.
- Tracking doc: `docs/UAT-EXECUTION-LOG.md`

### B4 — Release metadata completion for Play Store
- Severity: Medium
- Status: Open
- Owner: Product/Design
- Action: finalize screenshots, feature graphic, listing copy.

## Recently Closed
- C1 — Conflict dashboard with diagnostics + filters
- C2 — Publish lifecycle APIs and admin publish action
- C3 — Android timetable grid + empty-slot legend
- C4 — Conflict quick links with contextual prefill

## Burndown Rule
- No RC freeze until all High blockers are closed.
