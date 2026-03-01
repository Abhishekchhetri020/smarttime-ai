import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smarttime_ai/features/timetable/offline_solver_diagnostics_view.dart';
import 'package:smarttime_ai/features/timetable/offline_solver_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('diagnostics section renders conflict list end-to-end',
      (tester) async {
    final result = OfflineSolverResult.fromJson({
      'status': 'partial',
      'diagnostics': {
        'solverVersion': 'kotlin-csp-1.0.0',
        'unscheduledReasonCounts': {
          'class_conflict': 1,
        },
        'totals': {
          'lessonsRequested': 3,
          'assignedEntries': 2,
          'hardViolations': 1,
        },
        'search': {
          'nodesVisited': 9,
          'backtracks': 2,
          'branchesPrunedByForwardCheck': 1,
        },
      },
      'hardViolations': [
        {
          'lessonId': 'L3',
          'classId': 'VIII-A',
          'teacherId': 'T9',
          'subjectId': 'history',
          'reason': 'class_conflict',
          'attemptedSlots': 15,
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OfflineSolverDiagnosticsView(result: result),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2/3 assigned'), findsOneWidget);
    expect(find.textContaining('Class Conflict'), findsWidgets);
    expect(find.textContaining('L3 • VIII-A • history'), findsOneWidget);
  });
}
