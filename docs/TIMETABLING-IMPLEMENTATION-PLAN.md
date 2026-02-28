# Timetabling Upgrade — Step-by-Step Plan

## Step 1: Solver core hardening (done)
- Added richer constraint-aware solver contract and evaluation:
  - teacher/class/room clash
  - teacher availability
  - max periods/day (teacher/class)
  - fixed periods
  - lab double periods
- Added deterministic slot ordering via `seed`.

## Step 2: Scoring and diagnostics (done)
- Soft scoring implemented:
  - teacher gaps
  - class gaps
  - subject distribution
  - teacher room stability
- Hard diagnostics implemented per unscheduled lesson with most-likely reason.

## Step 3: Reproducible tests + dataset (done)
- Tests:
  - reproducible solve behavior
  - conflict diagnostics
  - lab double period handling
- Added sample dataset JSON for repeatable checks.

## Step 4: Android Generate/Publish wiring (done)
- Incharge/Super Admin now use mobile admin console to:
  - add teacher/class/subject
  - generate timetable (calls backend endpoint)
  - publish latest timetable
- Requires deployed backend endpoint in `AppConfig.apiBase`.

## Step 5: Ops closure (in progress)
- Ensure backend API deployed and reachable.
- Ensure Firestore API enabled.
- Complete role claim assignment for admin users.

## Next improvements
1. Add rooms + constraints forms in Android admin console.
2. Add conflict dashboard in Android (not only web).
3. Add meta-heuristic improvement phase (swap/move local search).
4. Add backend endpoint to build lessons from full entity model automatically.
