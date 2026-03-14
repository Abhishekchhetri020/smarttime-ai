// Greedy seed algorithm — Phase 1 of the solver pipeline.
//
// Produces a fast initial feasible solution using:
// 1. Priority ordering: pinned → double → most-constrained first (MRV)
// 2. Slot assignment via "least-conflicting" heuristic
// 3. Room assignment via "best-fit" (required room → least-used room)

import 'dart:math';

import 'constraint_checker.dart';
import 'solver_models.dart';

class GreedySeed {
  final SolverPayload payload;
  final ConstraintChecker checker;
  final void Function(SolverProgress)? onProgress;

  GreedySeed({
    required this.payload,
    required this.checker,
    this.onProgress,
  });

  /// Run the greedy seed, returns a list of assignments + unscheduled IDs.
  GreedyResult run() {
    final assignments = <SolverAssignment>[];
    final unscheduled = <String>[];

    // Sort lessons by priority
    final sorted = _prioritySort(payload.lessons);
    final total = sorted.length;

    // Room usage tracker: slot → set of occupied roomIds
    final roomUsage = <SolverSlot, Set<String>>{};

    for (int i = 0; i < sorted.length; i++) {
      final lesson = sorted[i];

      if (i % 10 == 0) {
        onProgress?.call(SolverProgress(
          phase: 'greedy',
          percent: i / total,
          message: 'Placing lesson ${i + 1} of $total',
        ));
      }

      // Pinned lessons go directly
      if (lesson.isPinned && lesson.pinnedSlot != null) {
        final roomId = _assignRoom(lesson, lesson.pinnedSlot!, roomUsage);
        final check = checker.checkHard(lesson, lesson.pinnedSlot!, roomId, assignments);
        if (!check.hardViolation) {
          final assignment = SolverAssignment(
            lessonId: lesson.id,
            day: lesson.pinnedSlot!.day,
            period: lesson.pinnedSlot!.period,
            roomId: roomId,
          );
          assignments.add(assignment);
          _trackRoom(roomUsage, lesson.pinnedSlot!, roomId);
          if (lesson.isDouble) {
            final nextSlot = SolverSlot(lesson.pinnedSlot!.day, lesson.pinnedSlot!.period + 1);
            _trackRoom(roomUsage, nextSlot, roomId);
          }
        } else {
          unscheduled.add(lesson.id);
        }
        continue;
      }

      // Find all valid slots
      final candidateSlots = <_ScoredSlot>[];
      for (int d = 0; d < payload.days; d++) {
        for (int p = 0; p < payload.periodsPerDay; p++) {
          final slot = SolverSlot(d, p);
          final roomId = _assignRoom(lesson, slot, roomUsage);
          final check = checker.checkHard(lesson, slot, roomId, assignments);
          if (!check.hardViolation) {
            // Score this slot using soft heuristics
            final score = _slotHeuristic(lesson, slot, assignments);
            candidateSlots.add(_ScoredSlot(slot, roomId, score));
          }
        }
      }

      if (candidateSlots.isEmpty) {
        unscheduled.add(lesson.id);
        continue;
      }

      // Pick best slot (lowest score)
      candidateSlots.sort((a, b) => a.score.compareTo(b.score));
      final best = candidateSlots.first;

      final assignment = SolverAssignment(
        lessonId: lesson.id,
        day: best.slot.day,
        period: best.slot.period,
        roomId: best.roomId,
      );
      assignments.add(assignment);
      _trackRoom(roomUsage, best.slot, best.roomId);
      if (lesson.isDouble) {
        final nextSlot = SolverSlot(best.slot.day, best.slot.period + 1);
        _trackRoom(roomUsage, nextSlot, best.roomId);
      }
    }

    onProgress?.call(const SolverProgress(
      phase: 'greedy',
      percent: 1.0,
      message: 'Greedy seed complete',
    ));

    return GreedyResult(
      assignments: assignments,
      unscheduledIds: unscheduled,
    );
  }

  /// Priority sort: pinned first, then doubles, then by constraint tightness (MRV).
  List<SolverLesson> _prioritySort(List<SolverLesson> lessons) {
    final sorted = [...lessons];
    sorted.sort((a, b) {
      // Pinned lessons first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Double lessons next (harder to place)
      if (a.isDouble && !b.isDouble) return -1;
      if (!a.isDouble && b.isDouble) return 1;

      // Then by constraint tightness (fewer available teachers = harder)
      final aTeachers = a.teacherIds.length;
      final bTeachers = b.teacherIds.length;
      if (aTeachers != bTeachers) return aTeachers.compareTo(bTeachers);

      // More classes = harder
      final aClasses = a.classIds.length;
      final bClasses = b.classIds.length;
      if (aClasses != bClasses) return bClasses.compareTo(aClasses);

      // Required room = harder
      if (a.requiredRoomId != null && b.requiredRoomId == null) return -1;
      if (a.requiredRoomId == null && b.requiredRoomId != null) return 1;

      // Teachers with more time-off constraints = harder
      final aUnavail = a.teacherIds
          .map((tid) => payload.teacherProfiles[tid]?.unavailableSlots.length ?? 0)
          .fold<int>(0, (sum, v) => sum + v);
      final bUnavail = b.teacherIds
          .map((tid) => payload.teacherProfiles[tid]?.unavailableSlots.length ?? 0)
          .fold<int>(0, (sum, v) => sum + v);
      return bUnavail.compareTo(aUnavail);
    });
    return sorted;
  }

  /// Assign the best available room for a lesson at a given slot.
  String _assignRoom(
    SolverLesson lesson,
    SolverSlot slot,
    Map<SolverSlot, Set<String>> roomUsage,
  ) {
    // If lesson requires a specific room, use it
    if (lesson.requiredRoomId != null && lesson.requiredRoomId!.isNotEmpty) {
      return lesson.requiredRoomId!;
    }

    // Find rooms not in use at this slot
    final slotsToCheck = <SolverSlot>[slot];
    if (lesson.isDouble) {
      slotsToCheck.add(SolverSlot(slot.day, slot.period + 1));
    }

    // Merge used rooms across all required slots
    final allUsed = <String>{};
    for (final s in slotsToCheck) {
      allUsed.addAll(roomUsage[s] ?? <String>{});
    }

    for (final room in payload.rooms) {
      if (!allUsed.contains(room.id)) {
        return room.id;
      }
    }

    // Fallback: return a synthetic room ID
    return 'AUTO_ROOM_${slot.day}_${slot.period}';
  }

  void _trackRoom(Map<SolverSlot, Set<String>> usage, SolverSlot slot, String roomId) {
    usage.putIfAbsent(slot, () => <String>{}).add(roomId);
  }

  /// Heuristic score for placing a lesson at a slot. Lower = better.
  double _slotHeuristic(
    SolverLesson lesson,
    SolverSlot slot,
    List<SolverAssignment> assignments,
  ) {
    double score = 0;

    // Prefer distributing across days evenly
    final sameDayCount = assignments
        .where((a) => a.day == slot.day)
        .where((a) {
          final l = payload.lessons.firstWhere(
            (l) => l.id == a.lessonId,
            orElse: () => lesson,
          );
          return l.teacherIds.any(lesson.teacherIds.contains);
        })
        .length;
    score += sameDayCount * 2.0;

    // Prefer minimizing gaps for the teacher
    for (final tid in lesson.teacherIds) {
      final teacherPeriods = assignments
          .where((a) => a.day == slot.day)
          .where((a) {
            final l = payload.lessons.firstWhere(
              (l) => l.id == a.lessonId,
              orElse: () => lesson,
            );
            return l.teacherIds.contains(tid);
          })
          .map((a) => a.period)
          .toList()
        ..add(slot.period)
        ..sort();

      if (teacherPeriods.length >= 2) {
        final gaps = teacherPeriods.last - teacherPeriods.first - (teacherPeriods.length - 1);
        score += gaps * 1.5;
      }
    }

    // Avoid same subject on same day for same class
    for (final cid in lesson.classIds) {
      final sameDaySameSubject = assignments
          .where((a) => a.day == slot.day)
          .where((a) {
            final l = payload.lessons.firstWhere(
              (l) => l.id == a.lessonId,
              orElse: () => lesson,
            );
            return l.classIds.contains(cid) && l.subjectId == lesson.subjectId;
          })
          .length;
      score += sameDaySameSubject * 5.0;
    }

    // Prefer morning slots slightly for certain subjects
    final subProfile = payload.subjectProfiles[lesson.subjectId];
    if (subProfile != null) {
      if (subProfile.preferMorning && slot.period >= 4) {
        score += 1.0;
      }
      if (subProfile.avoidLastPeriod && slot.period == payload.periodsPerDay - 1) {
        score += 2.0;
      }
    }

    // Small random jitter to break ties and create variety
    score += Random().nextDouble() * 0.1;

    return score;
  }
}

class GreedyResult {
  final List<SolverAssignment> assignments;
  final List<String> unscheduledIds;

  const GreedyResult({
    required this.assignments,
    required this.unscheduledIds,
  });
}

class _ScoredSlot {
  final SolverSlot slot;
  final String roomId;
  final double score;

  const _ScoredSlot(this.slot, this.roomId, this.score);
}
