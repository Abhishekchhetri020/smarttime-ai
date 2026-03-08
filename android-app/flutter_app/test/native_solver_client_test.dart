import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/data/native_solver_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('smarttime/offline_solver');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'solveTimetable') {
        return {
          'status': 'SEED_FOUND',
          'assignments': [
            {
              'lessonId': 'L1',
              'subjectId': 'MATH',
              'day': 1,
              'period': 1,
              'classIds': ['C1'],
              'teacherIds': ['T1']
            }
          ]
        };
      }
      return {'status': 'INVALID_PAYLOAD'};
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('native solver client maps status correctly', () async {
    final client = NativeSolverClient();
    final res = await client.solve({'days': 5, 'periodsPerDay': 8, 'lessons': []});

    expect(res.rawStatus, 'SEED_FOUND');
    expect(res.status, SolverStatus.seedFound);
    expect(res.isOk, isTrue);
  });
}
