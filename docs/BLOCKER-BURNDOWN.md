# SmartTime AI — Blocker Burndown

Date: 2026-02-27

## Current Blockers

### B1 — Emulator CI run confirmation evidence
- Severity: High
- Status: Open
- Owner: DevOps/Engineering
- Action: Run GitHub Actions `functions-emulator-tests` and attach run URL in RC evidence pack.
- Local check note: emulator run currently blocked on this machine because Java Runtime is missing (`Unable to locate a Java Runtime`).

### B2 — Android staging Firebase production-like config validation
- Severity: High
- Status: Open
- Owner: Mobile
- Action: Validate `google-services.json`, package IDs, SHA fingerprints, Google Sign-In client IDs.

### B3 — Role-based UAT formal sign-off
- Severity: High
- Status: Open
- Owner: QA/Product
- Action: Execute `docs/UAT-SCRIPT.md` and mark sign-off table.

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
