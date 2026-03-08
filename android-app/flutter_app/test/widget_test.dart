import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smarttime_ai/features/admin/admin_console.dart';
import 'package:smarttime_ai/features/admin/planner_state.dart';

void main() {
  testWidgets('admin console basic render smoke', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlannerState(),
        child: const MaterialApp(
          home: Scaffold(
            body: AdminConsole(role: 'Timetable In-Charge'),
          ),
        ),
      ),
    );

    expect(find.text('Timetable In-Charge Console'), findsOneWidget);
    expect(find.text('Add Teacher'), findsOneWidget);
    expect(find.text('Add Class'), findsOneWidget);
    expect(find.text('Add Subject'), findsOneWidget);
    expect(find.text('Generate Now'), findsOneWidget);
  });
}
