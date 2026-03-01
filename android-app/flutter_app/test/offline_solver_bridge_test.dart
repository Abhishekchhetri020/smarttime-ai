import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/offline_solver_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.smarttime.ai/offline_solver');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          expect(call.method, 'solve');
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final payload = jsonDecode(args['payload'] as String) as Map<String, dynamic>;
          return jsonEncode(<String, dynamic>{
            'status': 'success',
            'diagnostics': {
              'totals': {'lessonsRequested': payload['lessons'] is List ? (payload['lessons'] as List).length : 0}
            }
          });
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

    expect(response['status'], 'success');
    expect((response['diagnostics'] as Map)['totals']['lessonsRequested'], 1);
  });
}
