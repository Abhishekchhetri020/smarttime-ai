# SmartTime AI — Product Requirements Document (V1)

## 1) Product Summary
SmartTime AI is an Android-first school timetable platform with a constraint-based auto-generator, manual overrides, and role-based views for school operations.

## 2) Goals (V1)
- Generate valid school timetables quickly with hard + soft constraints.
- Let timetable admins edit and re-run with conflict diagnostics.
- Provide clear timetable views for teachers/students/parents.
- Export publish-ready timetable files (PDF/Excel).

## 3) Non-Goals (V1)
- Full ERP replacement
- Fee management, attendance workflows
- Multi-tenant white-label SaaS billing

## 4) Users & Roles
- Super Admin: org setup, role assignment, global rules
- Timetable In-Charge: data input, constraint config, generation, publish
- Teacher: read-only timetable, availability submission (optional write)
- Student: read-only timetable
- Parent: read-only timetable (optional V1 toggle)

## 5) Must-Have Features (V1)
1. Timetable auto-generation with hard/soft constraints
2. Manual edit + re-run solver with conflict diagnostics
3. Teacher availability management
4. Subject period allocation rules
5. Class-section management
6. Conflict detection dashboard
7. Admin override system
8. Export timetable (PDF + Excel)
9. Android teacher view (read-only timetable)
10. Basic analytics (free periods, load distribution, teacher workload)

## 6) Core Functional Requirements
### FR-1 Data Setup
- Manage academic year, terms, working days, periods, breaks.
- CRUD for teachers, subjects, classes, sections, rooms.

### FR-2 Constraint Configuration
- Hard constraints: no teacher/class/room clash, availability, room capacity/type.
- Soft constraints: max gaps/day, spread of subject periods, consecutive limits, load balance.
- Priority/weight support for soft constraints.

### FR-3 Solver Run
- Start generation job with selected scope.
- Track status: queued/running/failed/succeeded.
- Store score + diagnostics.

### FR-4 Manual Operations
- Drag/drop or form-based slot move.
- Pin/lock periods and re-run around pinned decisions.
- Admin override with audit trail.

### FR-5 Conflict Dashboard
- List violations by severity (hard first, then weighted soft).
- Explain reason + suggested corrective action.

### FR-6 Publishing & Export
- Publish approved version.
- Export class-wise/teacher-wise PDFs and XLSX.

### FR-7 Android App
- Auth + role-aware read-only timetable screens for teacher/student/parent.
- Offline cache for latest published timetable.

### FR-8 Analytics
- Teacher workload heatmap.
- Free period summary by class/teacher.
- Load distribution variance.

## 7) Quality Requirements
- Generation for medium school dataset (up to ~60 teachers, ~40 sections) under 2–5 min target.
- P95 API read latency < 400ms (cached views).
- Auditability for all override actions.
- Recovery from failed solver jobs.

## 8) Acceptance Criteria (V1)
- Timetable can be generated and published for one school end-to-end.
- No hard conflicts in published timetable.
- At least 3 export formats/views work (class, teacher, room summary).
- Android teacher app fetches and renders published timetable reliably.

## 9) Launch Deliverables
- Backend + admin web panel + Android app APK/AAB.
- Test report (unit/integration/UAT checklist).
- Ops runbook + rollback plan.
