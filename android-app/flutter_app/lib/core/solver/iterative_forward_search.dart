// Iterative Forward Search — Phase 1 of the Hybrid Solver Pipeline.
//
// Inspired by UniTime's IFS algorithm. Maintains a *valid but partial*
// timetable at all times. When a lesson cannot be placed cleanly, IFS
// force-places it into the least-disruptive slot and ejects conflicting
// lessons back into the unscheduled queue for Phase 2 to handle.
//
// NOW USES SolverState O(1) matrix for all conflict detection.

import 'dart:math';

import 'constraint_checker.dart';
import 'engine_constraints.dart';
import 'solver_models.dart';

class IterativeForwardSearch {
  final SolverPayload payload;
  final ConstraintChecker checker;
  final void Function(SolverProgress)? onProgress;

  late final Map<String, SolverLesson> _lessonById;

  IterativeForwardSearch({
    required this.payload,
    required this.checker,
    this.onProgress,
  }) {
    _lessonById = {for (final l in payload.lessons) l.id: l};
  }

  /// Run IFS. Returns assignments placed so far + IDs still unscheduled.
  IFSResult run() {
    // Build the SolverState O(1) matrix
    final state = SolverState(payload);

    // Sort by difficulty — hardest lessons first
    final queue = _difficultySortedQueue(payload.lessons);
    final total = queue.length;

    // Conflict-based statistics: track how many times a lesson was ejected
    final conflictStats = <String, int>{};

    int placed = 0;
    int ejections = 0;
    int maxPasses = 2;

    for (int pass = 0; pass < maxPasses && queue.isNotEmpty; pass++) {
      final thisPass = List<String>.from(queue);
      queue.clear();

      for (int i = 0; i < thisPass.length; i++) {
        final lessonId = thisPass[i];
        final lesson = _lessonById[lessonId];
        if (lesson == null) continue;

        if (placed % 10 == 0) {
          onProgress?.call(SolverProgress(
            phase: 'ifs',
            percent: placed / total,
            message:
                'IFS pass ${pass + 1}: placing ${placed + 1}/$total (${queue.length} queued)',
          ));
        }

        // 1. Handle pinned lessons
        if (lesson.isPinned && lesson.pinnedSlot != null) {
          final roomId = _assignRoom(lesson, lesson.pinnedSlot!, state);
          final check = checker.checkHardWithState(
              state, lesson, lesson.pinnedSlot!, roomId);
          if (!check.hardViolation) {
            _placeLesson(state, lesson, lesson.pinnedSlot!, roomId);
            placed++;
          } else {
            queue.add(lessonId);
          }
          continue;
        }

        // 2. Find all valid slots using O(1) SolverState queries
        final validSlots = <_ScoredSlot>[];
        for (int d = 0; d < payload.days; d++) {
          for (int p = 0; p < payload.periodsPerDay; p++) {
            final slot = SolverSlot(d, p);
            final roomId = _assignRoom(lesson, slot, state);
            final check =
                checker.checkHardWithState(state, lesson, slot, roomId);
            if (!check.hardViolation) {
              final score = _slotScore(lesson, slot, state, conflictStats);
              validSlots.add(_ScoredSlot(slot, roomId, score));
            }
          }
        }

        if (validSlots.isNotEmpty) {
          validSlots.sort((a, b) => a.score.compareTo(b.score));
          final best = validSlots.first;
          _placeLesson(state, lesson, best.slot, best.roomId);
          placed++;
          continue;
        }

        // 3. NO valid slot found — find least-disruptive ejection
        final ejectionCandidates = <_EjectionCandidate>[];
        for (int d = 0; d < payload.days; d++) {
          for (int p = 0; p < payload.periodsPerDay; p++) {
            final slot = SolverSlot(d, p);

            if (_hasIntrinsicHardBlock(lesson, slot)) continue;

            // Use O(1) SolverState to find conflicts
            final conflicts = _findConflicts(lesson, slot, state);
            if (conflicts.isEmpty) continue;

            if (conflicts.any((c) {
              final cl = _lessonById[c.lessonId];
              return cl != null && cl.isPinned;
            })) continue;

            final costKey = '${lessonId}_${slot.day}_${slot.period}';
            final repeatPenalty = (conflictStats[costKey] ?? 0) * 5.0;
            final cost = conflicts.length.toDouble() + repeatPenalty;
            ejectionCandidates.add(_EjectionCandidate(slot, conflicts, cost));
          }
        }

        if (ejectionCandidates.isNotEmpty) {
          ejectionCandidates.sort((a, b) => a.cost.compareTo(b.cost));
          final best = ejectionCandidates.first;

          for (final conflict in best.conflicts) {
            state.remove(conflict.lessonId);
            queue.add(conflict.lessonId);
            final cKey =
                '${conflict.lessonId}_${conflict.day}_${conflict.period}';
            conflictStats[cKey] = (conflictStats[cKey] ?? 0) + 1;
            ejections++;
          }

          final roomId = _assignRoom(lesson, best.slot, state);
          _placeLesson(state, lesson, best.slot, roomId);
          placed++;
        } else {
          queue.add(lessonId);
        }
      }
    }

    onProgress?.call(SolverProgress(
      phase: 'ifs',
      percent: 1.0,
      message:
          'IFS complete: placed $placed/${total}, ${queue.length} remaining, $ejections ejections',
    ));

    return IFSResult(
      assignments: state.allAssignments,
      unscheduledIds: queue,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DIFFICULTY SORTING
  // ═══════════════════════════════════════════════════════════════════

  List<String> _difficultySortedQueue(List<SolverLesson> lessons) {
    final scored = lessons.map((l) {
      double difficulty = 0;

      if (l.isPinned) difficulty -= 1000;
      if (l.isDouble) difficulty += 50;
      if (l.requiredRoomId != null) difficulty += 30;
      difficulty += l.teacherIds.length * 10;
      difficulty += l.classIds.length * 10;

      for (final tid in l.teacherIds) {
        final profile = payload.teacherProfiles[tid];
        if (profile != null) {
          difficulty += profile.unavailableSlots.length * 2;
          if (profile.maxPeriodsPerDay != null) difficulty += 15;
        }
      }

      if (l.relationshipType > 0) difficulty += 20;

      return MapEntry(l.id, difficulty);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SLOT SCORING (uses SolverState O(1) queries)
  // ═══════════════════════════════════════════════════════════════════

  double _slotScore(
    SolverLesson lesson,
    SolverSlot slot,
    SolverState state,
    Map<String, int> conflictStats,
  ) {
    double score = 0;

    // Teacher day load — O(periodsPerDay) via SolverState
    for (final tid in lesson.teacherIds) {
      score += state.teacherDayLoad(tid, slot.day) * 2.0;
    }

    // Minimize teacher gaps via SolverState
    for (final tid in lesson.teacherIds) {
      final periods = state.teacherPeriodsOnDay(tid, slot.day);
      if (periods.isNotEmpty) {
        final allPeriods = [...periods, slot.period]..sort();
        final gaps =
            allPeriods.last - allPeriods.first - (allPeriods.length - 1);
        score += gaps * 1.5;
      }
    }

    // Avoid same subject on same day for same class
    for (final cid in lesson.classIds) {
      int sameSubjectCount = 0;
      final periodsOnDay = state.classPeriodsOnDay(cid, slot.day);
      for (final p in periodsOnDay) {
        for (final lid in state.lessonsAt(slot.day, p)) {
          final l = _lessonById[lid];
          if (l != null &&
              l.classIds.contains(cid) &&
              l.subjectId == lesson.subjectId) {
            sameSubjectCount++;
          }
        }
      }
      score += sameSubjectCount * 5.0;
    }

    // Subject preferences
    final subProfile = payload.subjectProfiles[lesson.subjectId];
    if (subProfile != null) {
      if (subProfile.preferMorning && slot.period >= 4) score += 1.0;
      if (subProfile.avoidLastPeriod &&
          slot.period == payload.periodsPerDay - 1) {
        score += 2.0;
      }
    }

    // Penalize slots where this lesson was previously ejected from
    final cKey = '${lesson.id}_${slot.day}_${slot.period}';
    score += (conflictStats[cKey] ?? 0) * 3.0;

    // Small random jitter
    score += Random().nextDouble() * 0.1;

    return score;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CONFLICT DETECTION (O(1) via SolverState)
  // ═══════════════════════════════════════════════════════════════════

  bool _hasIntrinsicHardBlock(SolverLesson lesson, SolverSlot slot) {
    if (slot.day < 0 || slot.day >= payload.days) return true;
    if (slot.period < 0 || slot.period >= payload.periodsPerDay) return true;
    if (lesson.isDouble && slot.period + 1 >= payload.periodsPerDay)
      return true;
    for (final tid in lesson.teacherIds) {
      final profile = payload.teacherProfiles[tid];
      if (profile != null && profile.unavailableSlots.contains(slot)) {
        return true;
      }
      if (lesson.isDouble) {
        final nextSlot = SolverSlot(slot.day, slot.period + 1);
        if (profile != null && profile.unavailableSlots.contains(nextSlot)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Find conflicts using SolverState O(1) grid lookups.
  List<SolverAssignment> _findConflicts(
    SolverLesson lesson,
    SolverSlot slot,
    SolverState state,
  ) {
    final conflicts = <String>{};
    final slotsToCheck = <SolverSlot>[slot];
    if (lesson.isDouble) {
      slotsToCheck.add(SolverSlot(slot.day, slot.period + 1));
    }

    for (final checkSlot in slotsToCheck) {
      if (checkSlot.period >= payload.periodsPerDay) continue;

      // Teacher clashes
      for (final tid in lesson.teacherIds) {
        if (state.isTeacherBusy(tid, checkSlot.day, checkSlot.period)) {
          for (final lid in state.lessonsAt(checkSlot.day, checkSlot.period)) {
            final existing = _lessonById[lid];
            if (existing != null && existing.teacherIds.contains(tid)) {
              conflicts.add(lid);
            }
          }
        }
      }

      // Class clashes
      for (final cid in lesson.classIds) {
        if (state.isClassBusy(cid, checkSlot.day, checkSlot.period)) {
          for (final lid in state.lessonsAt(checkSlot.day, checkSlot.period)) {
            final existing = _lessonById[lid];
            if (existing == null) continue;
            if (!existing.classIds.contains(cid)) continue;

            // Division exception
            if (lesson.divisionId != null &&
                existing.divisionId != null &&
                lesson.divisionId != existing.divisionId &&
                lesson.classIds.length == 1 &&
                existing.classIds.length == 1 &&
                lesson.classIds.first == existing.classIds.first) {
              continue;
            }
            conflicts.add(lid);
          }
        }
      }

      // Room clashes
      if (lesson.requiredRoomId != null) {
        if (state.isRoomOccupied(
            lesson.requiredRoomId!, checkSlot.day, checkSlot.period)) {
          for (final lid in state.lessonsAt(checkSlot.day, checkSlot.period)) {
            final a = state.assignmentFor(lid);
            if (a != null && a.roomId == lesson.requiredRoomId) {
              conflicts.add(lid);
            }
          }
        }
      }
    }

    return conflicts
        .map((lid) => state.assignmentFor(lid))
        .whereType<SolverAssignment>()
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ASSIGNMENT MANAGEMENT (via SolverState)
  // ═══════════════════════════════════════════════════════════════════

  void _placeLesson(
    SolverState state,
    SolverLesson lesson,
    SolverSlot slot,
    String roomId,
  ) {
    state.place(SolverAssignment(
      lessonId: lesson.id,
      day: slot.day,
      period: slot.period,
      roomId: roomId,
    ));
  }

  /// Assign the best available room using SolverState O(1) lookups.
  String _assignRoom(
    SolverLesson lesson,
    SolverSlot slot,
    SolverState state,
  ) {
    if (lesson.requiredRoomId != null && lesson.requiredRoomId!.isNotEmpty) {
      return lesson.requiredRoomId!;
    }

    if (payload.rooms.isEmpty) return '';

    final slotsToCheck = <SolverSlot>[slot];
    if (lesson.isDouble) {
      slotsToCheck.add(SolverSlot(slot.day, slot.period + 1));
    }

    final allUsed = <String>{};
    for (final s in slotsToCheck) {
      if (s.period < payload.periodsPerDay) {
        allUsed.addAll(state.roomsAt(s.day, s.period));
      }
    }

    for (final room in payload.rooms) {
      if (!allUsed.contains(room.id)) return room.id;
    }

    return '';
  }
}

class IFSResult {
  final List<SolverAssignment> assignments;
  final List<String> unscheduledIds;

  const IFSResult({
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

class _EjectionCandidate {
  final SolverSlot slot;
  final List<SolverAssignment> conflicts;
  final double cost;

  const _EjectionCandidate(this.slot, this.conflicts, this.cost);
}
