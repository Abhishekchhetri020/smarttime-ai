import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/core/database.dart';

void main() {
  test('streamed analytics counts joint class lesson as single lesson', () async {
    final db = AppDatabase(NativeDatabase.memory());

    await db.savePlannerSnapshot({
      'schoolName': 'Demo',
      'workingDays': 5,
      'bellTimes': ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'],
      'teachers': [
        {
          'id': 'T1',
          'maxGapsPerDay': 2,
          'timeOff': {'1-1': 0}
        }
      ],
      'lessons': [
        {
          'id': 'L1',
          'subjectId': 'S1',
          'teacherIds': ['T1'],
          'classIds': ['C1', 'C2'], // joint class
          'countPerWeek': 1,
          'isPinned': false,
        }
      ]
    });

    final snap = await db.watchAnalytics().first;
    expect(snap.totalAssignedLessons, 1);

    await db.close();
  });
}
