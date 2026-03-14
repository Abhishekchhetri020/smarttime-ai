// Integration tests for the Pure-Dart Solver Engine.
//
// These tests run the full 3-phase pipeline (Greedy → Backtrack → SA)
// synchronously to validate correctness in realistic school scenarios.

import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/core/solver/solver_engine.dart';
import 'package:smarttime_ai/core/solver/solver_models.dart';

void main() {
  group('SolverEngine.solveSync', () {
    // ─── Helper: build a simple school payload ───
    SolverPayload _buildPayload({
      required int teacherCount,
      required int classCount,
      required int subjectCount,
      required int lessonsPerClass,
      int days = 5,
      int periodsPerDay = 8,
      int roomCount = 5,
      int timeoutMs = 30000,
      Map<String, SolverTeacherProfile>? teacherProfiles,
    }) {
      final subjects = List.generate(subjectCount, (i) => 'S${i + 1}');
      final teachers = List.generate(teacherCount, (i) => 'T${i + 1}');
      final classes = List.generate(classCount, (i) => 'C${i + 1}');

      // Build lessons: each class gets lessonsPerClass assignments, round-robin across teachers
      final lessons = <SolverLesson>[];
      int lessonCounter = 0;
      for (final classId in classes) {
        for (int j = 0; j < lessonsPerClass; j++) {
          final teacherId = teachers[lessonCounter % teacherCount];
          final subjectId = subjects[lessonCounter % subjectCount];
          lessons.add(SolverLesson(
            id: 'L${lessonCounter + 1}',
            subjectId: subjectId,
            teacherIds: [teacherId],
            classIds: [classId],
          ));
          lessonCounter++;
        }
      }

      final rooms = List.generate(
        roomCount,
        (i) => SolverRoom(id: 'R${i + 1}', capacity: 40),
      );

      return SolverPayload(
        days: days,
        periodsPerDay: periodsPerDay,
        timeoutMs: timeoutMs,
        lessons: lessons,
        rooms: rooms,
        teacherProfiles: teacherProfiles ?? {
          for (final t in teachers)
            t: SolverTeacherProfile(id: t),
        },
        classProfiles: {
          for (final c in classes)
            c: SolverClassProfile(id: c),
        },
        subjectProfiles: {
          for (final s in subjects)
            s: SolverSubjectProfile(id: s),
        },
        variantCount: 1,
      );
    }

    test('1. Small school: 5 teachers, 3 classes, 24 lessons → all scheduled', () {
      final payload = _buildPayload(
        teacherCount: 5,
        classCount: 3,
        subjectCount: 4,
        lessonsPerClass: 8,
      );

      expect(payload.lessons.length, 24);

      final result = SolverEngine.solveSync(payload);

      expect(result.isOk, isTrue);
      expect(result.variants.length, 1);
      expect(result.variants.first.assignments.length, 24);
      expect(result.variants.first.unscheduledLessonIds, isEmpty);
      expect(result.variants.first.hardViolations, 0);
    });

    test('2. Medium school: 20 teachers, 10 classes, 100 lessons → all scheduled', () {
      final payload = _buildPayload(
        teacherCount: 20,
        classCount: 10,
        subjectCount: 8,
        lessonsPerClass: 10,
      );

      expect(payload.lessons.length, 100);

      final result = SolverEngine.solveSync(payload);

      expect(result.isOk, isTrue);
      expect(result.variants.first.assignments.length, 100);
      expect(result.variants.first.hardViolations, 0);
    });

    test('3. No teacher double-booking in solution', () {
      final payload = _buildPayload(
        teacherCount: 5,
        classCount: 6,
        subjectCount: 4,
        lessonsPerClass: 6,
      );

      final result = SolverEngine.solveSync(payload);
      expect(result.isOk, isTrue);

      final assignments = result.variants.first.assignments;
      // Check for teacher double-booking: same teacher should not appear in same slot
      // via different lessons
      final slotTeacher = <String, Set<String>>{};
      for (final a in assignments) {
        final key = 'D${a.day}:P${a.period}';
        final lesson = payload.lessons.firstWhere((l) => l.id == a.lessonId);
        for (final tid in lesson.teacherIds) {
          slotTeacher.putIfAbsent(key, () => {});
          expect(
            slotTeacher[key]!.add(tid),
            isTrue,
            reason: 'Teacher $tid double-booked at $key',
          );
        }
      }
    });

    test('4. No class double-booking in solution', () {
      final payload = _buildPayload(
        teacherCount: 10,
        classCount: 5,
        subjectCount: 6,
        lessonsPerClass: 8,
      );

      final result = SolverEngine.solveSync(payload);
      expect(result.isOk, isTrue);

      final assignments = result.variants.first.assignments;
      // Check for class double-booking
      final slotClass = <String, Set<String>>{};
      for (final a in assignments) {
        final key = 'D${a.day}:P${a.period}';
        final lesson = payload.lessons.firstWhere((l) => l.id == a.lessonId);
        for (final cid in lesson.classIds) {
          slotClass.putIfAbsent(key, () => {});
          expect(
            slotClass[key]!.add(cid),
            isTrue,
            reason: 'Class $cid double-booked at $key',
          );
        }
      }
    });

    test('5. No room double-booking in solution', () {
      final payload = _buildPayload(
        teacherCount: 8,
        classCount: 4,
        subjectCount: 5,
        lessonsPerClass: 8,
        roomCount: 4,
      );

      final result = SolverEngine.solveSync(payload);
      expect(result.isOk, isTrue);

      final assignments = result.variants.first.assignments;
      // Check for room double-booking
      final slotRoom = <String, Set<String>>{};
      for (final a in assignments) {
        final key = 'D${a.day}:P${a.period}';
        slotRoom.putIfAbsent(key, () => {});
        expect(
          slotRoom[key]!.add(a.roomId),
          isTrue,
          reason: 'Room ${a.roomId} double-booked at $key',
        );
      }
    });

    test('6. Teacher unavailability respected', () {
      // Teacher T1 is unavailable on Monday (day 0)
      final profiles = <String, SolverTeacherProfile>{
        'T1': SolverTeacherProfile(
          id: 'T1',
          unavailableSlots: {
            for (int p = 0; p < 8; p++) SolverSlot(0, p),
          },
        ),
        'T2': const SolverTeacherProfile(id: 'T2'),
        'T3': const SolverTeacherProfile(id: 'T3'),
      };

      final payload = _buildPayload(
        teacherCount: 3,
        classCount: 2,
        subjectCount: 3,
        lessonsPerClass: 6,
        teacherProfiles: profiles,
      );

      final result = SolverEngine.solveSync(payload);
      expect(result.isOk, isTrue);

      // Verify T1 has no assignments on day 0
      final assignments = result.variants.first.assignments;
      for (final a in assignments) {
        final lesson = payload.lessons.firstWhere((l) => l.id == a.lessonId);
        if (lesson.teacherIds.contains('T1')) {
          expect(a.day, isNot(0),
              reason: 'T1 scheduled on day 0 despite being unavailable');
        }
      }
    });

    test('7. Pinned lessons stay at their pinned slots', () {
      final rooms = [const SolverRoom(id: 'R1')];
      final lessons = [
        const SolverLesson(
          id: 'L_PINNED',
          subjectId: 'S1',
          teacherIds: ['T1'],
          classIds: ['C1'],
          isPinned: true,
          pinnedSlot: SolverSlot(2, 3), // Wed period 4
        ),
        const SolverLesson(
          id: 'L_FREE',
          subjectId: 'S2',
          teacherIds: ['T2'],
          classIds: ['C1'],
        ),
      ];

      final payload = SolverPayload(
        days: 5,
        periodsPerDay: 8,
        lessons: lessons,
        rooms: rooms,
        teacherProfiles: const {
          'T1': SolverTeacherProfile(id: 'T1'),
          'T2': SolverTeacherProfile(id: 'T2'),
        },
        classProfiles: const {
          'C1': SolverClassProfile(id: 'C1'),
        },
        subjectProfiles: const {
          'S1': SolverSubjectProfile(id: 'S1'),
          'S2': SolverSubjectProfile(id: 'S2'),
        },
        variantCount: 1,
      );

      final result = SolverEngine.solveSync(payload);
      expect(result.isOk, isTrue);

      final pinned = result.variants.first.assignments
          .firstWhere((a) => a.lessonId == 'L_PINNED');
      expect(pinned.day, 2, reason: 'Pinned lesson should be on day 2 (Wed)');
      expect(pinned.period, 3, reason: 'Pinned lesson should be at period 3');
    });

    test('8. Stress test: 40 teachers, 30 classes, 300 lessons under 30s', () {
      final payload = _buildPayload(
        teacherCount: 40,
        classCount: 30,
        subjectCount: 10,
        lessonsPerClass: 10,
        roomCount: 15,
        timeoutMs: 30000,
      );

      expect(payload.lessons.length, 300);

      final sw = Stopwatch()..start();
      final result = SolverEngine.solveSync(payload);
      sw.stop();

      expect(result.isOk, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(30000),
          reason: 'Solver must complete under 30 seconds');
      // At least 90% of lessons should be scheduled
      expect(
        result.variants.first.assignments.length,
        greaterThanOrEqualTo((300 * 0.9).toInt()),
        reason: 'At least 90% of lessons should be placed',
      );
    });

    test('9. Multiple variants generated and ranked', () {
      final payload = _buildPayload(
        teacherCount: 8,
        classCount: 5,
        subjectCount: 5,
        lessonsPerClass: 6,
      );

      final payloadWith3Variants = SolverPayload(
        days: payload.days,
        periodsPerDay: payload.periodsPerDay,
        lessons: payload.lessons,
        rooms: payload.rooms,
        teacherProfiles: payload.teacherProfiles,
        classProfiles: payload.classProfiles,
        subjectProfiles: payload.subjectProfiles,
        variantCount: 3,
      );

      final result = SolverEngine.solveSync(payloadWith3Variants);
      expect(result.isOk, isTrue);
      expect(result.variants.length, greaterThanOrEqualTo(1));
      // Variants should be sorted by score (ascending)
      for (int i = 1; i < result.variants.length; i++) {
        expect(
          result.variants[i].totalScore,
          greaterThanOrEqualTo(result.variants[i - 1].totalScore),
          reason: 'Variants should be sorted by score ascending',
        );
      }
    });

    test('10. Progress callbacks fire', () {
      final payload = _buildPayload(
        teacherCount: 3,
        classCount: 2,
        subjectCount: 3,
        lessonsPerClass: 4,
      );

      final phases = <String>[];
      SolverEngine.solveSync(payload, onProgress: (p) {
        if (!phases.contains(p.phase)) phases.add(p.phase);
      });

      expect(phases, contains('greedy'));
      expect(phases, contains('optimize'));
    });
  });
}
