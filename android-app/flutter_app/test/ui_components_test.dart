import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smarttime_ai/core/database.dart';
import 'package:smarttime_ai/core/theme/app_theme.dart';
import 'package:smarttime_ai/features/admin/planner_state.dart';
import 'package:smarttime_ai/features/admin/timetable_dashboard_screen.dart';
import 'package:smarttime_ai/features/admin/widgets/dashboard_analytics_widget.dart';

void main() {
  group('Phase 3 UI Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('DashboardAnalyticsWidget renders correctly with default data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: DashboardAnalyticsWidget(db: db),
          ),
        ),
      );

      // Verify basic text presence
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Conflicts'), findsOneWidget);
      expect(find.text('Avg Gaps'), findsOneWidget);

      // Wait for animations to complete by fast-forwarding mock clock
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Check values
      expect(find.text('0'), findsAtLeastNWidgets(1));

      // Unmount the widget tree to cancel StreamBuilder and animation timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('TimetableDashboardScreen renders all premium UI components', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PlannerState>(
          create: (_) => PlannerState(db),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TimetableDashboardScreen(),
          ),
        ),
      );

      // Verify SliverAppBar title
      expect(find.text('SmartTime AI'), findsOneWidget);
      expect(find.text('Timetable Generator'), findsOneWidget);

      // Verify Live Stats Row
      expect(find.text('Teachers'), findsOneWidget);
      expect(find.text('Classes'), findsOneWidget);
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Lessons'), findsOneWidget);

      // Verify Hero Action Card
      expect(find.text('Build Your Timetable'), findsOneWidget);
      expect(find.text('New Timetable'), findsOneWidget);
      expect(find.text('Import Data'), findsOneWidget);

      // Verify Quick Actions
      expect(find.text('Setup\nWizard'), findsOneWidget);
      expect(find.text('Import\nTemplate'), findsOneWidget);
      expect(find.text('Export\nExcel'), findsOneWidget);
      expect(find.text('Export\nPDF'), findsOneWidget);

      // Wait for the animations within DashboardAnalyticsWidget to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Unmount the widget tree
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}

