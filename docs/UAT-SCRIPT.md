# SmartTime AI — UAT Script (Role-Based)

## Scope
Validate end-to-end behavior across roles and core timetable lifecycle.

## Test Data Setup
- School: demo-school
- At least 5 teachers, 5 classes, 6 subjects, 3 rooms
- Constraints: min 3 active soft constraints

## Scenario A — Timetable In-Charge
1. Login as incharge
2. Create/edit teachers/classes/subjects/constraints
3. Run solver job
4. Open conflict dashboard and inspect diagnostics
5. Resolve at least one conflict via quick-create links
6. Re-run solver
7. Publish a timetable version

Expected:
- Solver job created and status updates visible
- Conflict diagnostics show counts/types
- Publish marks selected version as current

## Scenario B — Super Admin
1. Login as super admin
2. Review school summary and latest published version
3. Verify previous published version archived after republish

Expected:
- Correct role access
- Publish lifecycle consistent

## Scenario C — Teacher
1. Login as teacher (Android)
2. Open timetable view
3. Verify day x period grid renders
4. Verify empty slots highlighted

Expected:
- Read-only access
- Accurate timetable rows

## Scenario D — Student
1. Login as student (Android)
2. Open timetable view
3. Confirm role-specific routing and data visibility

Expected:
- Student read-only view

## Scenario E — Parent (Optional V1)
1. Login as parent
2. Open timetable view

Expected:
- Parent read-only access only

## Sign-off Table
- Super Admin: [ ] pass [ ] fail
- Incharge: [ ] pass [ ] fail
- Teacher: [ ] pass [ ] fail
- Student: [ ] pass [ ] fail
- Parent: [ ] pass [ ] fail

Notes:
- Capture screenshots for each role flow.
- Log defects with severity and reproduction steps.
