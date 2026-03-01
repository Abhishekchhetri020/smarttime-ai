import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/admin/admin_console.dart';
import 'package:smarttime_ai/features/admin/planner_state.dart';

void main() {
  testWidgets('setup wizard renders required 3-step flow', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminConsole(role: 'Timetable In-Charge')));

    expect(find.text('School Settings'), findsOneWidget);
    expect(find.text('Days Configuration'), findsOneWidget);
    expect(find.text('Bell Times & Breaks'), findsOneWidget);
    expect(find.byKey(const Key('wizard_continue_btn')), findsWidgets);
    expect(find.byKey(const Key('school_name_field')), findsOneWidget);
    expect(find.byKey(const Key('days_count_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('periods_dropdown')), findsOneWidget);
  });

  testWidgets('subjects tab renders with add FAB after setup complete', (tester) async {
    final state = PlannerState()..setupComplete = true;

    await tester.pumpWidget(
      MaterialApp(home: AdminConsole(role: 'Timetable In-Charge', plannerState: state)),
    );

    expect(find.text('SmartTime Builder'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.byKey(const Key('subjects_fab')), findsOneWidget);
    expect(find.text('Add Subject'), findsOneWidget);
  });
}
