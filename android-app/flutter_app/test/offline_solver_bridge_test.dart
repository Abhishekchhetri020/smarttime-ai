import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/offline_solver_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Must match the channel name in OfflineSolverBridge and MainActivity.kt
  const MethodChannel channel = MethodChannel('smarttime/offline_solver');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          expect(call.method, 'solveTimetable');
          // The bridge passes the payload Map directly (not JSON-encoded)
          final payload = Map<String, dynamic>.from(call.arguments as Map);
          final lessons = payload['lessons'] as List? ?? const [];
          return <String, dynamic>{
            'status': 'SEED_FOUND',
            'assignments': <dynamic>[],
            'hardViolations': <dynamic>[],
            'diagnostics': <String, dynamic>{
              'solverVersion': 'mock-1.0.0',
              'unscheduledReasonCounts': <String, dynamic>{},
              'totals': <String, dynamic>{
                'lessonsRequested': lessons.length,
                'assignedEntries': lessons.length,
                'hardViolations': 0,
              },
              'search': <String, dynamic>{
                'nodesVisited': 1,
                'backtracks': 0,
                'branchesPrunedByForwardCheck': 0,
              },
            },
            'score': 0,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('solve sends JSON payload and decodes JSON result', () async {
    final response = await OfflineSolverBridge.solve(payload: {
      'requestId': 'req-1',
      'lessons': [
        {'id': 'L1', 'classId': 'A', 'teacherId': 'T1', 'subjectId': 'Math'}
      ]
    });

    expect(response['status'], 'SEED_FOUND');
    expect(
      (response['diagnostics'] as Map)['totals']['lessonsRequested'],
      1,
    );
  });
}
