import '../../admin/planner_state.dart';
import '../../admin/time_off_picker.dart';

class SolverPayloadMapper {
  Future<Map<String, dynamic>> fromCanonicalState(
    PlannerState planner, {
    int timeoutMs = 60000,
  }) async {
    final db = planner.db;
    if (db == null) {
      return fromPlanner(planner, timeoutMs: timeoutMs);
    }

    final teacherRows = await db.select(db.teachers).get();
    final classRows = await db.select(db.classes).get();
    final subjectRows = await db.select(db.subjects).get();
    final lessonRows = await db.select(db.lessons).get();

    final roomIds = <String>{
      for (final item in planner.classrooms) item.id,
      if (planner.classrooms.isEmpty) ...{
        for (var i = 101; i <= 108; i++) 'ROOM_$i'
      },
      for (final lesson in planner.lessons)
        if (lesson.requiredClassroomId != null &&
            lesson.requiredClassroomId!.isNotEmpty)
          lesson.requiredClassroomId!,
    };

    final roomRows = roomIds
        .map((r) => {'id': r, 'roomType': 'standard'})
        .toList(growable: false);
    final plannerLessonById = {for (final l in planner.lessons) l.id: l};

    return {
      'payloadVersion': 1,
      'timeoutMs': timeoutMs,
      'days': planner.workingDays,
      'periodsPerDay': planner.bellTimes.length,
      'dict': {
        'teacherIds': teacherRows.map((e) => e.id).toList(),
        'classIds': classRows.map((e) => e.id).toList(),
        'subjectIds': subjectRows.map((e) => e.id).toList(),
        'roomIds': roomIds.toList(),
      },
      'rooms': roomRows,
      'lessons': lessonRows
          .map((l) => {
                'id': l.id,
                'classIds': l.classIds,
                'teacherIds': l.teacherIds,
                'subjectId': l.subjectId,
                'preferredRoomId': plannerLessonById[l.id]?.requiredClassroomId,
                'isLabDouble': plannerLessonById[l.id]?.length == 'double',
                'isPinned': l.isPinned,
                'fixedDay': l.fixedDay,
                'fixedPeriod': l.fixedPeriod,
                'relationshipType': l.relationshipType,
                'relationshipGroupKey': l.relationshipGroupKey,
                'classDivisionId': l.classDivisionId,
                'syncGroupId': l.relationshipGroupKey,
              })
          .toList(growable: false),
      'constraints': {
        'teacherAvailability': {
          for (final t in planner.teachers)
            if (t.timeOff.isNotEmpty)
              t.id: [
                for (int d = 1; d <= planner.workingDays; d++)
                  for (int p = 1; p <= planner.bellTimes.length; p++)
                    if (t.timeOff['$d-$p'] != TimeOffState.unavailable)
                      {'day': d, 'period': p}
              ]
        },
        'teacherMaxConsecutivePeriods': {
          for (final t in planner.teachers)
            if (t.maxConsecutivePeriods != null) t.id: t.maxConsecutivePeriods!,
        },
        'softWeights': {
          'teacher_gaps': 5,
          'class_gaps': 5,
          'subject_distribution': 3,
          'teacher_room_stability': 1,
        },
      },
    };
  }

  Map<String, dynamic> fromPlanner(
    PlannerState planner, {
    int timeoutMs = 60000,
  }) {
    final teachers = [...planner.teachers]
      ..sort((a, b) => a.id.compareTo(b.id));
    final classes = [...planner.classes]..sort((a, b) => a.id.compareTo(b.id));
    final subjects = [...planner.subjects]
      ..sort((a, b) => a.id.compareTo(b.id));
    final rooms = [...planner.classrooms]..sort((a, b) => a.id.compareTo(b.id));
    if (rooms.isEmpty) {
      for (var i = 101; i <= 108; i++) {
        rooms.add(ClassroomItem(
            id: 'ROOM_$i', name: 'Room $i', roomType: 'standard'));
      }
    }

    final teacherIdx = _indexById(teachers.map((e) => e.id).toList());
    final classIdx = _indexById(classes.map((e) => e.id).toList());
    final subjectIdx = _indexById(subjects.map((e) => e.id).toList());

    final dict = {
      'teacherIds': teachers.map((e) => e.id).toList(),
      'classIds': classes.map((e) => e.id).toList(),
      'subjectIds': subjects.map((e) => e.id).toList(),
      'roomIds': rooms.map((e) => e.id).toList(),
    };

    final roomRows = <Map<String, dynamic>>[
      for (final r in rooms)
        {
          'id': r.id,
          'roomType': r.roomType,
        }
    ];

    final lessonRows = <Map<String, dynamic>>[];
    var lid = 1;

    if (planner.lessons.isNotEmpty) {
      for (final l in planner.lessons) {
        final sIdx = subjectIdx[l.subjectId];
        if (sIdx == null) continue;

        final cIds = l.classIds.where(classIdx.containsKey).toList();
        final tIds = l.teacherIds.where(teacherIdx.containsKey).toList();
        if (cIds.isEmpty || tIds.isEmpty) continue;

        for (var k = 0; k < l.countPerWeek; k++) {
          lessonRows.add({
            'id': 'L${lid++}',
            'classIds': cIds,
            'teacherIds': tIds,
            'subjectId': subjects[sIdx].id,
            'preferredRoomId': l.requiredClassroomId,
            'isLabDouble': l.length == 'double',
            'isPinned': l.isPinned,
            'fixedDay': l.fixedDay,
            'fixedPeriod': l.fixedPeriod,
            'relationshipType': l.relationshipType,
            'relationshipGroupKey': l.relationshipGroupKey,
            'classDivisionId': l.classDivisionId,
            'syncGroupId': l.relationshipGroupKey,
          });
        }
      }
    }

    // Build teacher availability map for the Kotlin solver.
    // The solver expects Map<teacherId, Set<SlotKey>> where the set
    // contains the slots the teacher IS available in.
    // We convert from the time-off map (unavailable/available/conditional)
    // to a flat availability map keyed by teacherId.
    final teacherMaxConsecutive = <String, int>{};
    final teacherAvailability = <String, List<Map<String, int>>>{};

    for (final t in teachers) {
      if (t.maxConsecutivePeriods != null) {
        teacherMaxConsecutive[t.id] = t.maxConsecutivePeriods!;
      }

      // If teacher has time-off data, compute available slots.
      if (t.timeOff.isNotEmpty) {
        final available = <Map<String, int>>[];
        for (int d = 1; d <= planner.workingDays; d++) {
          for (int p = 1; p <= planner.bellTimes.length; p++) {
            final key = '$d-$p';
            final state = t.timeOff[key];
            // Include slot unless explicitly unavailable.
            if (state != TimeOffState.unavailable) {
              available.add({'day': d, 'period': p});
            }
          }
        }
        teacherAvailability[t.id] = available;
      }
    }

    return {
      'payloadVersion': 1,
      'timeoutMs': timeoutMs,
      'days': planner.workingDays,
      'periodsPerDay': planner.bellTimes.length,
      'dict': dict,
      'rooms': roomRows,
      'lessons': lessonRows,
      'constraints': {
        'teacherMaxConsecutivePeriods': teacherMaxConsecutive,
        'teacherAvailability': teacherAvailability,
        'softWeights': {
          'teacher_gaps': 5,
          'class_gaps': 5,
          'subject_distribution': 3,
          'teacher_room_stability': 1,
        },
      },
    };
  }

  Map<String, int> _indexById(List<String> ids) {
    final m = <String, int>{};
    for (var i = 0; i < ids.length; i++) {
      m[ids[i]] = i;
    }
    return m;
  }
}
