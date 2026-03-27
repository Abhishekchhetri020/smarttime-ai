# Phase 12 Verification — Buildings & Rooms Polish

Please run the following instructions using the Gemini CLI to verify the Phase 12 integration for SmartTime AI.

## 1. Local Emulator Test

**Context**: You need to verify that the `RoomSetupScreen` has been completely revamped. It now supports inline editing, an advanced `ClassroomItem` data model (handling entity assignments and room groups), and dynamic column visibility.

**Action (Gemini)**: Use your local toolset to:
1. Ensure the emulator is running.
2. Install the newly built APK: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
3. Launch the application: `adb shell am start -n com.example.flutter_app/.MainActivity`

## 2. Walkthrough & Verification Steps

**Action (Gemini)**: Navigate to the **Buildings & Rooms** setup screen and verify the following features:

1. **Verify Screen Layout**:
   - The screen should have a blue info banner at the top explaining that "Rooms are optional...".
   - There should be an "Available Rooms" section at the bottom with a search bar and a "Bulk Import" button.

2. **Verify Add Room Dialog**:
   - Tap the "Add New Room" button.
   - **Verify**: A dialog named "Add New Room" appears.
   - Tap "Show Optional Settings".
   - **Verify**: The dialog expands to reveal "Building Name (Optional)" and "Capacity (Optional)".
   - Fill in a room name (e.g., "Science Lab 1"), a Short Name (e.g., "SL1"), and a building name (e.g., "Science Block"). Tap "Create Room".
   - **Verify**: The room is added to the DataTable.

3. **Verify Inline Editing**:
   - Tap the "Science Lab 1" text in the data table.
   - **Verify**: It transforms into an active text field. Modify it slightly and press Enter. The name should update in the table.

4. **Verify Groups and Assignment Dialogs**:
   - In the "GROUP" column for your room, tap "Add to group".
   - **Verify**: The "Add to Group" dialog opens. Create a group name and save. The column should now display your group name.
   - In the "ASSIGNED TO" column, tap "Assign to entities".
   - **Verify**: The "Fix Room For" dialog opens, revealing a TabBar with "Teachers" and "Classes".
   - Select a Teacher or Class (if any exist in your DB), and tap "Save".
   - **Verify**: The "ASSIGNED TO" cell now says "1 entities" (or however many you selected).

5. **Verify Column Visibility Picker**:
   - Tap the "Columns" button above the table.
   - **Verify**: A "Show/Hide Columns" menu opens with checkboxes.
   - Uncheck the "Group" and "Assigned To" checkboxes.
   - **Verify**: Those columns instantly disappear from the DataTable behind the menu. Re-check them to bring them back.

## 3. Report Generation

**Action (Gemini)**: After following the steps, provide a Verification Report detailing:
- The installation and launch status.
- A concise checklist confirming:
  - Add Room Dialog with Optional Settings works.
  - Inline editing works.
  - "Add to Group" and "Fix Room For" dialogs open and update the UI state.
  - The Column Show/Hide picker functions dynamically.
- Any bugs, UI clipping, or console errors encountered.

***

# Timetable Details — School Name & Save Navigation

Please verify the following updates to the **Timetable Details** screen.

## 1. Verify School Name Field
1. Navigate to **Basic Information** -> **Timetable Details**.
2. **Verify**: A new section "School Information" exists with a "School Name" field.
3. **Verify**: The field has a helper text: "Appears on the header of exported reports".
4. Clear the field and tap **Save**.
5. **Verify**: A validation error appears: "School name is required".
6. Enter a school name (e.g., "Evergreen High") and tap **Save**.
7. Re-open the screen.
8. **Verify**: "Evergreen High" is persisted.

## 2. Verify Bottom Navigation Bar
1. **Verify**: The top app-bar "Save" text button is gone.
2. **Verify**: A sticky bottom bar exists with "Back" and "Save" buttons.
3. Tap **Back**.
4. **Verify**: You return to the previous screen without saving changes.
5. Tap **Save**.
6. **Verify**: Changes are persisted and you return to the previous screen.

***

# Phase 14 — Rooms Bulk Import Dialog

Please verify the new Bulk Import feature for the **Buildings & Rooms** screen.

## 1. Verify Dialog UI Layout
1. Navigate to **Institute Data** -> **Buildings & Rooms**.
2. Scroll to the "Available Rooms" section at the bottom.
3. Tap **Bulk Import**.
4. **Verify**: The "Import Rooms" dialog opens.
5. **Verify**: The UI includes the "CSV Format" blue info banner (detailing Room Name, Short Name, Room Group Name).
6. **Verify**: If you previously added room groups in Phase 12, a purple "Existing Room Groups" banner displays the chips.

## 2. Verify Template Download
1. Inside the dialog, tap **Download Sample**.
2. **Verify**: The native OS Share/Save sheet appears, offering to save `rooms_import_template.csv`.

## 3. Verify File Picker & Import Logic
1. **Verify**: Initially, the bottom right button says "Import 0 Rooms" and is grayed out/disabled.
2. Tap **Select CSV File**.
3. **Verify**: The OS file picker opens (you may need to upload a dummy CSV to the emulator first).
4. Select a valid CSV with a header row matching the requirements.
5. **Verify**: The button updates to say "Import X Rooms" (where X is the number of rows minus the header) and turns blue/enabled.
6. The "Select CSV File" button should now say "Change File (filename.csv)".
7. Tap the **Import** button.
8. **Verify**: The dialog closes, a success snackbar appears, and the new rooms are immediately visible in the horizontal DataTable.

***

# Phase 15 — Subjects & Activities

Please verify the new **Subjects & Activities** screen.

## 1. Verify Screen Layout
1. Navigate to **Institute Data** -> **Subjects & Activities**.
2. **Verify**: The header shows icon + title "Subjects & Activities" with subtitle.
3. **Verify**: The "Subjects (N)" count label and "Columns" button are present.
4. **Verify**: If subjects exist, a horizontal DataTable with columns (NAME, SHORT NAME, AVAILABILITY, ACTIONS) is displayed.
5. **Verify**: Keyboard shortcuts legend is shown below the table.

## 2. Verify Show/Hide Columns
1. Tap **Columns**.
2. **Verify**: A dialog shows all 5 columns (Name, Short Name, Color, Availability, Actions).
3. **Verify**: Required columns (Name, Short Name, Availability, Actions) have checkmarks and cannot be unchecked.
4. Toggle **Color** on and off.
5. **Verify**: The DataTable updates to show/hide the Color column.

## 3. Verify Add New Subject Dialog
1. Tap **Add New Subject**.
2. **Verify**: Dialog with "Subject Name *" and "Short Name" fields, plus "Show Optional Settings" expander.
3. Enter a name like "Physics" and tap **Create Subject**.
4. **Verify**: Subject appears in the DataTable.

## 4. Verify Inline Editing
1. Tap a subject's name cell in the DataTable.
2. **Verify**: Cell turns into a TextField for inline editing.
3. Edit the name and press Enter.
4. **Verify**: The change is saved and reflected.

## 5. Verify Manage Availability
1. Tap the green availability badge for a subject.
2. **Verify**: "Manage Availability for [Subject]" dialog opens with a period/day grid.
3. Toggle some cells from green ✓ to red ✗.
4. Tap **Save Changes**.
5. **Verify**: The availability count updates in the DataTable.

## 6. Verify Bulk Import
1. Tap **Bulk Import**.
2. **Verify**: "Import Subjects" dialog opens with CSV format info (Subject Name, Short Name).
3. **Verify**: Step 1 (Download Sample) and Step 2 (Upload CSV) sections are present.
4. **Verify**: "Import 0 Subjects" button is disabled initially.

## 7. Verify Available Subjects Section
1. Scroll down to "Available Subjects".
2. **Verify**: Search bar and list of default subjects (AUDIO VISUAL, Art & Craft, CHEMISTRY, etc.) are visible.
3. Tap **Add to Timetable** on any subject.
4. **Verify**: The subject moves from the available list to the DataTable above.

***

# Phase 16 — Lessons

Please verify the new **Lessons** screen.

## 1. Verify Main Screen Layout
1. Navigate to the **Lessons** setup screen.
2. **Verify**: Header shows icon + title "Lessons" with description.
3. **Verify**: Tab bar with Classes, Faculty, Subjects, Rooms tabs.
4. **Verify**: Sort row with Name, Lessons, Periods options.
5. **Verify**: Empty state: "No lessons added yet."
6. **Verify**: Bottom action bar with Export CSV, Bulk Import, and "Add New Lesson" button.

## 2. Verify Add New Lesson Wizard — Step 1 (Sections)
1. Tap **Add New Lesson**.
2. **Verify**: Dialog titled "Add New Lesson" with 3-step stepper (Sections → Setup → Frequency).
3. **Verify**: "Search and select sections..." dropdown and "Add a faculty only activity" option.
4. Open the sections dropdown.
5. **Verify**: Search field and checkboxes for available classes (e.g., "1 A").
6. Select a section and tap **Next**.

## 3. Verify Add New Lesson Wizard — Step 2 (Setup)
1. **Verify**: Step 2 "Configure Activity" is shown with Subject/Activity, Faculty, and Room fields.
2. Tap the Subject field and type "Biology".
3. **Verify**: A searchable dropdown appears showing matching subjects with colored dots.
4. Expand the Faculty dropdown.
5. **Verify**: Search field and checkboxes for available teachers.
6. Expand the Room dropdown.
7. **Verify**: Rooms are listed with checkboxes. "Use room group" link is visible.

## 4. Verify Add New Lesson Wizard — Step 3 (Frequency)
1. Tap **Next** to proceed to Step 3.
2. **Verify**: "Frequency per week" section with −/+ counter, × symbol, and duration dropdown.
3. Tap the duration dropdown.
4. **Verify**: Options: Single, Double, Triple, 4-8 periods.
5. Increase the counter to 5.
6. **Verify**: Preview shows "5 periods / week" with 5 "1P" chips.
7. Tap **+ Add another configuration**.
8. **Verify**: A second frequency row appears.
9. **Verify**: Preview updates to show combined total.
10. **Verify**: Tip banner about fixing time slots in the Timetable Editor.
11. Tap **Create Lesson**.

## 5. Verify Grouped Lesson Cards
1. **Verify**: The lesson appears in a grouped card under the appropriate class/teacher name.
2. **Verify**: Stats show correct counts (Lessons, Total Periods, Classes, Subjects).
3. Tap the card to expand it.
4. **Verify**: Lesson detail tile shows section, subject, lesson formula, period count, and room.
5. **Verify**: Edit, Duplicate, and Delete icons are present.

## 6. Verify Tab Switching & Sort
1. Switch to the **Faculty** tab.
2. **Verify**: Lessons are now grouped by teacher name.
3. Toggle sort from "Name" to "Lessons".
4. **Verify**: Groups reorder accordingly.

## 7. Verify Edit & Duplicate
1. Tap the **Edit** icon on a lesson.
2. **Verify**: "Edit Lesson" wizard opens with pre-populated data.
3. Close and tap **Duplicate**.
4. **Verify**: A new lesson with the same settings is created.

## 8. Verify Export CSV
1. Tap **Export CSV**.
2. **Verify**: "Export Lessons to CSV" dialog shows lesson count, CSV columns preview.
3. Tap **Export CSV**.
4. **Verify**: Share sheet appears with the CSV file.

## 9. Verify Bulk Import
1. Tap **Bulk Import**.
2. **Verify**: "Bulk Import Lessons" dialog with CSV format instructions, Step 1 (Download Sample), Step 2 (Upload CSV).
3. **Verify**: "Import lessons" button is disabled initially.

***

# Phase 17 — Auto-Generated Abbreviations, Unique Colors & Bulk Import Fixes

## 1. Verify Color Column in Faculty Screen
1. Navigate to **Faculty** setup screen.
2. Add a teacher if none exist.
3. **Verify**: The DataTable now shows a **COLOR** column with a colored square swatch.
4. Add multiple teachers.
5. **Verify**: Each teacher has a **different color** (purple, blue, pink, green, amber, etc.).

## 2. Verify Auto-Abbreviation (Faculty)
1. Tap **Add User**.
2. Type "Jatin Das" in the Name field.
3. **Verify**: Short Name field auto-populates with **"JD"** in real-time.

## 3. Verify Color Column in Classes Screen
1. Navigate to **Grades & Divisions** setup screen.
2. **Verify**: The DataTable shows a **COLOR** column with colored swatches per class.
3. Each class has a unique color.

## 4. Verify Class Auto-Abbreviation
1. Tap **Add New Class**.
2. Type "Grade 10 A" in the Class Name field.
3. **Verify**: Short Name field auto-populates with **"G1A"** (or appropriate initials) in real-time.

## 5. Verify Class Bulk Import — Download Sample
1. Tap **Bulk Import** in the Classes section.
2. Tap **Download Sample**.
3. **Verify**: Share sheet appears with `classes_import_template.csv`.

## 6. Verify Class Bulk Import — Upload CSV
1. Tap **Select CSV / Excel File**.
2. Pick a CSV file.
3. **Verify**: File name appears with "X rows found" message.
4. **Verify**: Import button shows "Import X Classes" and is now enabled.
5. Tap **Import**.
6. **Verify**: Classes are added to the DataTable.

## 7. Verify Teacher Bulk Import — Excel Support
1. Navigate to **Faculty** setup. Tap **Bulk Import**.
2. **Verify**: File picker now allows selecting `.csv`, `.xlsx`, or `.xls` files.

***

# Phase 18 — My Timetables, System Settings, Workload Analysis & Cleanup

## 1. Verify My Timetables Section
1. Navigate to the **landing page** (Timetable Dashboard).
2. **Verify**: A new **"My Timetables"** section appears between the Hero Action Card and Quick Actions.
3. **Verify**: At least one draft card ("Draft 1") is shown with an **"Active"** badge.
4. **Verify**: The card shows teacher/class/lesson counts and a last-modified date.

## 2. Verify Draft Actions
1. Tap the **⋮** menu on a draft card.
2. **Verify**: Menu shows **Rename**, **Duplicate**, and **Delete** options.
3. Tap **Duplicate** → **Verify**: A new card "(Copy)" appears.
4. Tap **Rename** on the copy → **Verify**: Rename dialog pre-fills the current name. Change it and confirm.
5. Tap **Delete** on the copy → **Verify**: Card is removed (only works if > 1 draft exists).

## 3. Verify New Draft
1. Tap **"New Draft"** button in the header.
2. **Verify**: A dialog asks for a draft name, pre-filled with "Draft N".
3. Create the draft → **Verify**: New card appears in the horizontal list.

## 4. Verify System Settings
1. Tap **"System Settings"** mini-action card on the landing page.
2. **Verify**: System Settings screen opens with optimization weight sliders.
3. **Verify**: Four sliders: Teacher Gaps, Class Gaps, Subject Distribution, Room Stability.
4. Move the "Teacher Gaps" slider from 5 → 8.
5. **Verify**: The numeric badge updates to 8 and changes to red color.
6. Tap **"Reset to Defaults"** → **Verify**: All sliders reset to their defaults (5, 5, 3, 1).

## 5. Verify Workload Analysis
1. Tap **"Workload Analysis"** mini-action card on the landing page.
2. **Verify**: Screen has 3 tabs: **Teachers**, **Classes**, **Rooms**.
3. **Verify** (Teachers tab): Summary chips show Teachers count, Avg Load, Total Periods.
4. **Verify**: Each teacher has a utilization progress bar with percentage.
5. Switch to the **Classes** tab → **Verify**: Similar layout with class utilization.
6. Switch to **Rooms** tab → **Verify**: Shows room utilization with "In Use" count.

## 6. Verify Color Persistence
1. Add teachers and classes with auto-assigned colors.
2. Close the app completely and reopen.
3. **Verify**: Colors are preserved for both teachers and classes after restart.

***

# Phase 19 — My Timetables Root & Card Relationships

Please verify the new true draft isolation and Global Constraints features.

## 1. Verify New Application Root & Initialization
1. Completely close the app and re-launch it.
2. **Verify**: The app launches into a new **"My Timetables"** root screen (not the Timetable Dashboard directly).
3. **Verify**: A large "+ New Timetable" button is prominent at the top.
4. **Verify**: Tabs for "Draft Timetables" and "Published" are visible.
5. **Verify**: Metrics summary shows total, published, and drafted counts.

## 2. Verify True Timetable Isolation
1. Tap **+ New Timetable**.
2. **Verify**: You are navigated to an empty Basic Information / Setup wizard.
3. Add a new Teacher (e.g., "Mr. Anderson") and a new Class (e.g., "Grade 10").
4. Tap the **Back** arrow at the bottom or top left to return to "My Timetables".
5. **Verify**: A new draft card appears with the title you set (or "Untitled Timetable") and shows 1 T, 1 C.
6. Create another **+ New Timetable**.
7. **Verify**: The Teacher and Class setup lists are completely empty (proving isolation between drafts).
8. Go back to the Root screen.

## 3. Verify Draft Card Actions
1. On the root screen, tap the **⋮** menu on the first draft card.
2. **Verify**: Menu shows **Rename**, **Duplicate**, and **Delete**.
3. Tap **Duplicate**.
4. **Verify**: A new card "(Copy)" is created. Open it and verify "Mr. Anderson" exists inside.
5. Tap **Delete** on the copy.
6. **Verify**: The card is removed entirely.

## 4. Verify Card Relationships (Global Constraints)
1. Open any timetable draft.
2. Navigate to **Timetable Setup** -> **Settings & Conditions**.
3. **Verify**: The standalone option is now named "Global Constraints" (replacing System Settings).
4. Tap it and tap **Add Rule**.
5. **Verify**: The Card Relationship Builder opens.
6. Expand **Apply to Subjects** and **Apply to Classes**.
7. **Verify**: Bottom sheets open with checkboxes (and Select All / Clear for Classes). Select a few.
8. Expand the **Rule Condition** dropdown.
9. **Verify**: It contains 14 advanced constraints (e.g., "Max gaps per day = 0", "Cards cannot overlap").
10. Expand **Importance Level**.
11. **Verify**: It contains Low, Normal, High, Strict, Optimize with corresponding icon colors.
12. Enter a Note, and save the rule.
13. **Verify**: The rule appears in the list as a styled card, with a working Active toggle switch.

***

# Phase 20 — Timetable Generation Engine Integrations

Please verify that the new optimization weights and global constraints successfully intercept the solver algorithm.

## 1. Verify Solver Constraint Interpretation
1. Open any timetable draft.
2. Navigate to **Timetable Setup** -> **Global Constraints**.
3. Create a rule: **"Max consecutive periods = 2"** applied to **All Classes**, set to Strict.
4. Return to the dashboard and tap **Generate Timetable**.
5. Wait for the engine to Validate, Seed, Solve, and Optimize.
6. **Verify**: If the generated timetable is successful, open it in the **Cockpit** screen and verify visually that no class has 3 back-to-back lessons without a break/empty slot.
7. **Verify**: If the timetable is impossible, the Generation Progress ring should glow red and display the precise updated generic error message: `Constraint Violation: A class or teacher exceeded their maximum consecutive periods limit. Check your Global Constraints or add more breaks.`

***

# Phase 21 — Enhanced Card Relationships & Setup Shell Polish

Please verify the final additions to the Timetable Setup wizard and the Pre-generation error handling.

## 1. Verify Card Relationship Conditions
1. Open any timetable draft.
2. Navigate to **Timetable Setup** -> **Global Constraints**.
3. Tap **Add Rule**.
4. **Verify**: The Rule Condition dropdown contains exactly 25 merged conditions.
5. Create a condition and tap **Save**.
6. **Verify**: The rule is saved successfully and appears in the list.

## 2. Verify System Settings UI Placement
1. Navigate back to the **Timetable Setup** dashboard wizard.
2. **Verify**: Under the "Settings & Conditions" section, there are now entries for both **System Settings** and **Conditions & Constraints**.
3. Tap **System Settings**.
4. **Verify**: The system settings screen opens with the optimization sliders.

## 3. Verify Warnings & Errors Card (Blank White Screen Fix)
1. In the **Timetable Setup** dashboard, look at the bottom **Pre-generation Review** card.
2. Create a setup that forces a workload overflow (e.g., assign 50 periods to a single teacher like "Mr. Anderson").
3. **Verify**: The yellow "Warnings & Errors" banner appears inside the Pre-generation Review card showing "Workload Overflows".
4. Tap **View detailed analysis**.
5. **Verify**: You are successfully navigated to the **Workload Analysis** screen (with tabs for Teachers, Classes, Rooms) WITHOUT encountering a blank white screen.
6. **Verify**: The workload analysis screen correctly displays the progress bars and red 100%+ utilization indicators.
