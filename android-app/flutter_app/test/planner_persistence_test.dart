import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/core/database.dart';
import 'package:smarttime_ai/features/admin/planner_state.dart';

void main() {
  test('pinned lesson survives reload and is exported to solver payload',
      () async {
    final db = AppDatabase(NativeDatabase.memory());

    final p1 = PlannerState(db);
    p1.draftName = 'Test';
    p1.addClass(ClassItem(id: 'C1', name: 'Class 1', abbr: 'C1'));
    p1.addTeacher(
        TeacherItem(id: 'T1', firstName: 'A', lastName: 'B', abbr: 'T1'));
    p1.addSubject(
        SubjectItem(id: 'S1', name: 'Math', abbr: 'MATH', color: 0xFF0B3D91));
    p1.addLesson(
      subjectId: 'S1',
      teacherIds: const ['T1'],
      classIds: const ['C1'],
      countPerWeek: 1,
      length: 'single',
      isPinned: true,
      fixedDay: 2,
      fixedPeriod: 3,
      relationshipType: 0,
      relationshipGroupKey: 'G1',
    );

    // wait for debounce
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // force save
    await p1.saveToDatabase();

    final p2 = PlannerState(db, dbId: p1.dbId);
    await p2.refreshFromDatabase();

    expect(p2.lessons.isNotEmpty, true);
    expect(p2.lessons.first.isPinned, true);
    expect(p2.lessons.first.fixedDay, 2);
    expect(p2.lessons.first.fixedPeriod, 3);

    final payload = p2.toSolverPayload();
    final lessons = payload['lessons'] as List;
    expect(lessons.isNotEmpty, true);
    expect((lessons.first as Map)['isPinned'], true);
    expect((lessons.first as Map)['fixedDay'], 2);
    expect((lessons.first as Map)['fixedPeriod'], 3);

    await db.close();
  });
}
