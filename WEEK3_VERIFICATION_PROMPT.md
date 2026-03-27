# Week 3 UI Integration — Build & Analysis Verification

Run these steps in order. Report pass/fail for each. Do NOT modify any source files.

## Step 1: Flutter Analyze

```bash
cd android-app/flutter_app
flutter analyze --no-fatal-infos
```

**Pass criteria:** No errors. Warnings are acceptable.

## Step 2: Verify changed files compile

These 4 files were modified — confirm they are analysis-clean:

1. `lib/features/timetable/presentation/widgets/timetable_grid_view.dart`
2. `lib/features/timetable/presentation/screens/solver_debug_screen.dart`
3. `lib/features/timetable/presentation/screens/cockpit_screen.dart`
4. `lib/features/timetable/data/timetable_pdf_service.dart` (Week 2, still valid)

## Step 3: Verify ExportOption.excel enum

```bash
grep -n "ExportOption.excel" lib/features/timetable/presentation/widgets/timetable_grid_view.dart
grep -n "ExportOption.excel" lib/features/timetable/presentation/screens/solver_debug_screen.dart
```

**Pass criteria:** Both greps return at least one match.

## Step 4: Verify solver debug screen uses new export paths

```bash
grep -n "buildFromAssignments" lib/features/timetable/presentation/screens/solver_debug_screen.dart
grep -n "exportAndShareFromAssignments" lib/features/timetable/presentation/screens/solver_debug_screen.dart
grep -n "_buildCatalog" lib/features/timetable/presentation/screens/solver_debug_screen.dart
grep -n "schoolName" lib/features/timetable/presentation/screens/solver_debug_screen.dart
```

**Pass criteria:** Each grep returns at least one match.

## Step 5: Verify cockpit screen export menu

```bash
grep -n "showModalBottomSheet" lib/features/timetable/presentation/screens/cockpit_screen.dart
grep -n "_showExportMenu" lib/features/timetable/presentation/screens/cockpit_screen.dart
grep -n "ExcelExportService" lib/features/timetable/presentation/screens/cockpit_screen.dart
grep -n "Share as PDF" lib/features/timetable/presentation/screens/cockpit_screen.dart
grep -n "Share as Excel" lib/features/timetable/presentation/screens/cockpit_screen.dart
```

**Pass criteria:** Each grep returns at least one match.

## Step 6: Build debug APK

```bash
cd android-app/flutter_app
flutter build apk --debug
```

**Pass criteria:** BUILD SUCCESSFUL.

## Step 7: Run existing tests

```bash
cd android-app/flutter_app
flutter test
```

**Pass criteria:** All tests pass.

## Step 8: Install on emulator and smoke test

```bash
flutter install
```

Then manually verify:
1. Open the Cockpit screen → tap the share icon in app bar → bottom sheet appears with PDF/Excel/Print options
2. Open the Solver Debug screen → run solver → tap Export Options → see PDF/Excel/CSV/Print menu

**Pass criteria:** Both screens show the new export menus.

## Summary

```
Step 1 (analyze):       PASS/FAIL
Step 2 (files clean):   PASS/FAIL
Step 3 (excel enum):    PASS/FAIL
Step 4 (solver paths):  PASS/FAIL
Step 5 (cockpit menu):  PASS/FAIL
Step 6 (build):         PASS/FAIL
Step 7 (tests):         PASS/FAIL
Step 8 (smoke test):    PASS/FAIL
```

If any step fails, report the error but do NOT fix it.
