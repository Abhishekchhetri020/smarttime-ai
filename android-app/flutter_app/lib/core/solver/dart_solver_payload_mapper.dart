// Converts PlannerState into a SolverPayload for the pure-Dart solver engine.

import '../../features/admin/planner_state.dart';
import '../../features/admin/time_off_picker.dart';
import 'solver_models.dart';

class DartSolverPayloadMapper {
  /// Build a [SolverPayload] from the current [PlannerState].
  SolverPayload fromPlanner(
    PlannerState planner, {
    int timeoutMs = 60000,
    int variantCount = 3,
  }) {
    // ── Teacher profiles ──
    final teacherProfiles = <String, SolverTeacherProfile>{};
    for (final t in planner.teachers) {
      final unavailable = <SolverSlot>{};
      final conditional = <SolverSlot>{};

      for (final entry in t.timeOff.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 2) continue;
        final day = int.tryParse(parts[0]);
        final period = int.tryParse(parts[1]);
        if (day == null || period == null) continue;
        // Convert from 1-indexed (PlannerState) to 0-indexed (solver)
        final slot = SolverSlot(day - 1, period - 1);
        if (entry.value == TimeOffState.unavailable) {
          unavailable.add(slot);
        } else if (entry.value == TimeOffState.conditional) {
          conditional.add(slot);
        }
      }

      teacherProfiles[t.id] = SolverTeacherProfile(
        id: t.id,
        unavailableSlots: unavailable,
        conditionalSlots: conditional,
        maxGapsPerDay: t.maxGapsPerDay,
        maxConsecutivePeriods: t.maxConsecutivePeriods,
      );
    }

    // ── Class profiles ──
    final classProfiles = <String, SolverClassProfile>{};
    for (final c in planner.classes) {
      classProfiles[c.id] = SolverClassProfile(id: c.id);
    }

    // ── Subject profiles ──
    final subjectProfiles = <String, SolverSubjectProfile>{};
    for (final s in planner.subjects) {
      subjectProfiles[s.id] = SolverSubjectProfile(id: s.id);
    }

    // ── Rooms ──
    final rooms = <SolverRoom>[];
    if (planner.classrooms.isNotEmpty) {
      for (final r in planner.classrooms) {
        rooms.add(SolverRoom(
          id: r.id,
          roomType: r.roomType,
        ));
      }
    } else {
      // Default rooms
      for (int i = 101; i <= 108; i++) {
        rooms.add(SolverRoom(id: 'ROOM_$i'));
      }
    }

    // ── Lessons ──
    // Expand periodsPerWeek into individual solver lessons
    final lessons = <SolverLesson>[];
    for (final l in planner.lessons) {
      for (int k = 0; k < l.countPerWeek; k++) {
        final isPinned = l.isPinned && k == 0; // Only pin the first instance
        SolverSlot? pinnedSlot;
        if (isPinned && l.fixedDay != null && l.fixedPeriod != null) {
          // Convert from 1-indexed to 0-indexed
          pinnedSlot = SolverSlot(l.fixedDay! - 1, l.fixedPeriod! - 1);
        }

        lessons.add(SolverLesson(
          id: '${l.id}_$k',
          subjectId: l.subjectId,
          teacherIds: l.teacherIds,
          classIds: l.classIds,
          divisionId: l.classDivisionId,
          requiredRoomId: l.requiredClassroomId,
          isDouble: l.length == 'double',
          isPinned: isPinned,
          pinnedSlot: pinnedSlot,
          relationshipType: l.relationshipType,
          relationshipGroupKey: l.relationshipGroupKey,
        ));
      }
    }

    return SolverPayload(
      days: planner.workingDays,
      periodsPerDay: planner.bellTimes.isNotEmpty ? planner.bellTimes.length : 8,
      timeoutMs: timeoutMs,
      lessons: lessons,
      rooms: rooms,
      teacherProfiles: teacherProfiles,
      classProfiles: classProfiles,
      subjectProfiles: subjectProfiles,
      variantCount: variantCount,
    );
  }
}
