# SmartTime AI Project Handover

## Project Overview
You are taking over the development of **SmartTime AI**, a Flutter application designed for complex school timetable generation and scheduling. 
Your counterpart AI agent has been working on the UI/UX Polish phases. We are currently on **Phase 10**, focusing on the setup screens for the scheduling engine.

## Project Location & Environment
- **Root Directory:** `/Users/abhishekchhetri/.openclaw_backup/workspace/smarttime-ai/android-app/flutter_app`
- **Framework:** Flutter (Dart)
- **State Management:** Provider (`lib/features/admin/planner_state.dart`)
- **Database:** Drift (SQLite)

## What Has Been Achieved So Far
The previous agent has successfully completely revamped several setup screens to feature a professional, robust UI:
1. **Teacher Setup Screen (Phase 9):** Implemented inline-editable DataTables, horizontal scrollbars, "Keyboard shortcuts" legends, and a `_ManageAvailabilityDialog` grid for setting time-off constraints.
2. **Grades & Divisions Screen (Phase 10/11):** Mirrored the sophisticated architecture of the Teacher screen. Implemented the `_ClassCard`, inline editing, and the Class Teacher assignment bottom sheet (Phase 11).
3. **Buildings & Rooms (Phase 12-14):** Revamped the Rooms screen with horizontal scrollbars, expanded the `ClassroomItem` model, added grouping/entity assignment features, and built a custom Bulk Import CSV dialog.
4. **Timetable Details (Phase 13):** Added a required "School Name" field (stored in `planner.schoolName`) and implemented a professional bottom navigation bar with "Back" and "Save" buttons.
5. **Subjects & Activities (Phase 15):** Completely rewrote `subject_setup_screen.dart` with inline-editable DataTable, Show/Hide Columns, Manage Availability dialog, Bulk Import CSV dialog, and an Available Subjects catalog with "Add to Timetable" buttons.

**Current Task:** Phase 15 (Subjects & Activities) has just been implemented and verified via APK build.

## Your Methodology & Guidelines
1. **Understand the UI Pattern:** We are heavily utilizing `StatefulWidget` wrappers around horizontal `DataTable`s, wrapped in `Scrollbar`s with `thumbVisibility: true`. We use custom `DataCell` widgets (like `_ClassCell` or `_FacultyCell`) that toggle into `TextField`s for inline editing.
2. **Data Model Updates:** When adding features like availability constraints, we update the core data classes (e.g., `ClassItem`, `TeacherItem`) in `planner_state.dart`, add corresponding `updateConstraints` methods, and ensure the changes are serialized/deserialized in `_persist` and `_hydrate`.
3. **The Role of Gemini CLI:** The user utilizes a specific toolchain referred to as "Gemini CLI" to install, run, and test the APKs built by the agent on their local emulator. You will often be asked to write "Verification Prompts" (like `GEMINI_VERIFICATION_PROMPT.md`) instructing this CLI/secondary agent on *exactly* what steps to take in the UI to verify your code changes.

## Continuity Instructions (CRITICAL)
When you complete a significant chunk of work or when handing the session back, you **MUST** document your progress so the primary agent can resume smoothly.

1. **Update `task.md`:** Maintain the project checklist. Mark completed items with `[x]` and add new phases/tasks as they arise.
2. **Update `implementation_plan.md`:** If you are planning new features, write out the proposed architecture in this file *before* coding.
3. **Update this Handover File (`GEMINI_HANDOVER_PROMPT.md`):** Append a "Latest Status" section at the bottom of this document. Briefly summarize the files you edited, the exact bugs you fixed, and what the immediate next step is. This ensures bidirectional context sharing.

---
### Latest Status updates:
- **Phase 10 Verified:** The Gemini CLI successfully tested the APK. Inline editing, scrollbar, Manage Availability Dialog, and Bulk Importer are stable.
- **Phase 11 (Class Teacher Assignment):** Verified.
- **Phase 12 (Buildings & Rooms Polish):** 
  - Just completed. I expanded `ClassroomItem` to store `abbr`, `buildingName`, `groupId`, and assignments (`assignedTeacherIds`, `assignedClassIds`).
  - Rewrote `room_setup_screen.dart` featuring a horizontal DataTable, interactive checkboxes for column visibility, an expanding `_AddRoomDialog`, and complex `_AssignEntitiesDialog` (TabBar) and `_AddRoomGroupDialog` flows.
- **Timetable Details Update:**
  - Added "School Name" field (required).
  - Replaced the top-bar save button with a professional bottom-bar featuring "Back" and "Save" buttons.
- **Phase 14 (Rooms Bulk Import):**
  - Implemented `_BulkImportRoomsDialog` in `room_setup_screen.dart` with `file_picker`, `csv`, and `share_plus`.
  - Parses `Room Name`, `Short Name`, and `Room Group Name` from CSV and adds to the database.
- **Phase 15 (Subjects & Activities):**
  - Completely rewrote `subject_setup_screen.dart` (~1280 lines).
  - Expanded `SubjectItem` model with `timeOff`, `copyWith` in `planner_state.dart`.
  - Added `updateSubject` and `updateSubjectConstraints` methods to `PlannerState`.
  - Updated `_persist`/`_hydrate` to serialize/deserialize subject `timeOff`.
  - Features: DataTable inline editing, Show/Hide Columns, Add Subject dialog, Manage Availability dialog, Bulk Import CSV dialog, Available Subjects catalog.
- **Phase 16 (Lessons):**
  - Completely rewrote `lesson_setup_screen.dart` (~960 lines) with 4-tab view (Classes/Faculty/Subjects/Rooms), sort controls, grouped lesson cards with expand/collapse, edit/duplicate/delete actions, Export CSV dialog, Bulk Import dialog.
  - Completely rewrote `lesson_editor_sheet.dart` (~520 lines) as a 3-step wizard dialog: Step 1 (Sections with multi-select + faculty-only option), Step 2 (Subject search + Faculty/Room multi-select), Step 3 (Frequency counter × duration with multiple configs and preview chips).
  - Added `removeLesson` method to `PlannerState`.
- **Phase 17 (Auto-Abbreviations, Unique Colors & Bulk Import Fixes):**
  - Added `color` field to `TeacherItem` and `ClassItem` models in `planner_state.dart`.
  - Added Color column with colored circle swatch to both Teacher and Class DataTables (curated 20-color palette, auto-assigned by index).
  - Added `_classAutoAbbr` for real-time abbreviation generation in Add Class dialog.
  - Fixed broken `_BulkImportClassesDialog` — now has working Download Sample + file picker (CSV/Excel).
  - Updated Teacher bulk import to accept CSV + Excel (xlsx/xls).
- **Phase 18 (My Timetables, System Settings, Workload Analysis & Cleanup):**
  - Added `TimetableDraft` model to `planner_state.dart` with draft management.
  - Added `softWeights` field (user-configurable optimization weights).
  - Created `system_settings_screen.dart` and `workload_analysis_screen.dart`.
  - Updated `timetable_dashboard_screen.dart` with drafts list and action cards.
- **Phase 19 (Drafts Complete Overhaul & Card Relationships):**
  - Database architecture rewritten for true draft isolation, saving independent rows in `AppState`.
  - Scaled `PlannerState` to operate via an active `dbId`, completely abandoning the nested `drafts` array.
  - Created `my_timetables_screen.dart` as the new app root (removed `ChangeNotifierProvider` from `main.dart`). Supports Draft/Published tabs and "New Timetable" logic.
  - Formulated the "Card Relationships" (Global Constraints) engine.
  - Authored `CardRelationship` data model, `card_relationships_screen.dart`, and an advanced `card_relationship_builder.dart` handling multi-selects and custom rules.
  - Wired Card Relationships directly into the Setup Wizard (replacing old System Settings) and Dashboard. 
- **Phase 20 (Timetable Generation Engine Integrations):**
  - Updated `SolverPayloadMapper.dart` to extract the user's custom `softWeights` from `PlannerState` and map them directly into the solver payload (replacing hardcoded values).
  - Wrote constraint extraction logic linking `CardRelationship` strings ("Max consecutive periods = 2", "Card distribution over the week") into native json limits (`classMaxConsecutivePeriods`, `subjectDailyLimit`).
  - Enhanced `_friendlyError` in `generation_progress_screen.dart` to intercept custom constraint violations dynamically and display descriptive UI reports.
- **Next Step:** Both Phase 19 and 20 have been verified via emulator. Please provide instructions or specs for Phase 21.
- **Phase 21 (Enhanced Card Relationships & Setup Shell Polish):**
  - Merged card relationship conditions: 25 total (16 from reference app + 9 SmartTime-specific) in `card_relationship_builder.dart`.
  - Added **System Settings** entry alongside **Conditions & Constraints** in `timetable_setup_shell.dart` under "Settings & Conditions".
  - Added **Warnings & Errors** card to the Pre-generation Review section using `PreflightService`, with teacher/room workload overflow details and "View detailed analysis" link.
  - Updated `solver_payload_mapper.dart` to pass-through active `cardRelationships` in both `fromPlanner` and `fromCanonicalState`.
  - Fixed pre-existing bug in `admin_dashboard_screen.dart` (`file` → `workbookFile`).
- **Next Step:** Verify Phase 21 on the emulator. All tests pass and APK builds successfully.
