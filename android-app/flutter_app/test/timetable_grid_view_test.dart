import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/presentation/controllers/solver_controller.dart';
import 'package:smarttime_ai/features/timetable/presentation/widgets/timetable_grid_view.dart';

void main() {
  testWidgets('timetable grid renders at least one lesson card', (tester) async {
    const assignment = TimetableAssignment(
      lessonId: 'L1',
      day: 1,
      period: 1,
      subjectId: 'MATH',
      classIds: ['C1'],
      teacherIds: ['T1'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimetableGridView(
            assignments: [assignment],
            days: 5,
            periodsPerDay: 8,
          ),
        ),
      ),
    );

    expect(find.text('MATH'), findsOneWidget);
    expect(find.text('T:T1'), findsOneWidget);
    expect(find.text('C:C1'), findsOneWidget);
  });
}
