import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/offline_solver_diagnostics_view.dart';
import 'package:smarttime_ai/features/timetable/offline_solver_models.dart';

void main() {
  testWidgets('renders diagnostics summary and per-lesson conflict reasons',
      (tester) async {
    final result = OfflineSolverResult.fromJson({
      'status': 'partial',
      'diagnostics': {
        'solverVersion': 'kotlin-csp-1.0.0',
        'unscheduledReasonCounts': {
          'teacher_conflict': 2,
          'no_feasible_slot': 1,
        },
        'totals': {
          'lessonsRequested': 12,
          'assignedEntries': 9,
          'hardViolations': 3,
        },
        'search': {
          'nodesVisited': 42,
          'backtracks': 5,
          'branchesPrunedByForwardCheck': 7,
        },
      },
      'hardViolations': [
        {
          'lessonId': 'L10',
          'classId': 'VII-A',
          'teacherId': 'T1',
          'subjectId': 'math',
          'reason': 'teacher_conflict',
          'attemptedSlots': 40,
        },
        {
          'lessonId': 'L11',
          'classId': 'VII-B',
          'teacherId': 'T2',
          'subjectId': 'science',
          'reason': 'no_feasible_slot',
          'attemptedSlots': 40,
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineSolverDiagnosticsView(result: result),
        ),
      ),
    );

    expect(find.byKey(const Key('offline-status')), findsOneWidget);
    expect(find.byKey(const Key('diagnostics-summary')), findsOneWidget);
    expect(find.textContaining('9/12 assigned'), findsOneWidget);
    expect(
        find.byKey(const Key('reason-count-teacher_conflict')), findsOneWidget);
    expect(
        find.byKey(const Key('reason-count-no_feasible_slot')), findsOneWidget);
    expect(find.textContaining('Teacher Conflict'), findsWidgets);
    expect(find.textContaining('No Feasible Slot'), findsWidgets);
    expect(find.textContaining('L10 • VII-A • math'), findsOneWidget);
    expect(find.textContaining('L11 • VII-B • science'), findsOneWidget);
  });
}
