// Iterative Swap Solver — Phase 2 of the Hybrid Solver Pipeline.
//
// Replaces the old recursive _recursivePlace() with an explicit stack-based
// iterative DFS. This eliminates Dart stack overflow risk at depth 14+
// and enables deeper search without growing the call stack.
//
// Key improvements:
//   - Iterative DFS with explicit _SwapFrame stack
//   - Uses SolverState O(1) matrix for conflict detection
//   - Bitmask-based empty slot scanning
//   - "Least disruption" slot selection via SolverState queries
//   - Short-term Tabu memory to prevent cyclic ejections

import 'dart:math';

import 'constraint_checker.dart';
import 'engine_constraints.dart';
import 'solver_models.dart';

class RecursiveSwapSolver {
  final SolverPayload payload;
  final ConstraintChecker checker;
  final void Function(SolverProgress)? onProgress;

  late final Map<String, SolverLesson> _lessonById;

  /// Max DFS depth (iterative, so no stack overflow risk)
  static const int _maxDepth = 14;

  /// Max total DFS iterations per unscheduled lesson
  late final int _maxIterations;

  /// Short-term Tabu memory
  final Set<String> _tabuList = {};
  static const int _tabuTenure = 20;
  final Map<String, int> _tabuAge = {};
  int _globalStep = 0;

  /// Bitmask: bit i set → period i is free for this entity on this day.
  /// Rebuilt per-query from SolverState for O(1) slot scanning.
  int _emptySlotMask(SolverState state, SolverLesson lesson, int day) {
    int mask = 0;
    for (int p = 0; p < payload.periodsPerDay; p++) {
      bool free = true;
      for (final tid in lesson.teacherIds) {
        if (state.isTeacherBusy(tid, day, p)) {
          free = false;
          break;
        }
      }
      if (!free) continue;
      for (final cid in lesson.classIds) {
        if (state.isClassBusy(cid, day, p)) {
          free = false;
          break;
        }
      }
      if (free) mask |= (1 << p);
    }
    return mask;
  }

  RecursiveSwapSolver({
    required this.payload,
    required this.checker,
    this.onProgress,
  }) {
    _lessonById = {for (final l in payload.lessons) l.id: l};
    _maxIterations = payload.lessons.length * 3;
  }

  /// Attempt to place all [unscheduledIds] using iterative DFS swapping.
  RecursiveSwapResult run(
    List<SolverAssignment> currentAssignments,
    List<String> unscheduledIds,
  ) {
    if (unscheduledIds.isEmpty) {
      return RecursiveSwapResult(
        assignments: currentAssignments,
        unscheduledIds: const [],
      );
    }

    final sw = Stopwatch()..start();

    // Build SolverState from current assignments for O(1) lookups
    final state = SolverState.fromAssignments(payload, currentAssignments);
    final remaining = <String>[];

    int placedCount = 0;
    final total = unscheduledIds.length;

    for (int i = 0; i < unscheduledIds.length; i++) {
      final lessonId = unscheduledIds[i];
      final lesson = _lessonById[lessonId];
      if (lesson == null) continue;

      // Timeout: use 40% of total budget for Phase 2
      if (sw.elapsedMilliseconds > payload.timeoutMs * 0.4) {
        remaining.add(lessonId);
        continue;
      }

      if (i % 5 == 0) {
        onProgress?.call(SolverProgress(
          phase: 'swap',
          percent: i / total,
          message:
              'Iterative swap: ${i + 1}/$total (placed $placedCount so far)',
        ));
      }

      _ageTabuList();

      final success = _iterativePlace(lesson, state);
      if (success) {
        placedCount++;
      } else {
        remaining.add(lessonId);
      }
    }

    sw.stop();

    onProgress?.call(SolverProgress(
      phase: 'swap',
      percent: 1.0,
      message:
          'Iterative swap complete: placed $placedCount/$total in ${sw.elapsedMilliseconds}ms. ${remaining.length} still unscheduled.',
    ));

    return RecursiveSwapResult(
      assignments: state.allAssignments,
      unscheduledIds: remaining,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ITERATIVE DFS PLACEMENT (replaces recursive _recursivePlace)
  // ═══════════════════════════════════════════════════════════════════

  /// Try to place [lesson] using iterative DFS with an explicit stack.
  /// Returns true if the lesson was successfully placed.
  bool _iterativePlace(SolverLesson lesson, SolverState state) {
    _globalStep++;

    // 1. Try clean slot first (no ejection needed)
    final cleanSlot = _findCleanSlot(lesson, state);
    if (cleanSlot != null) {
      state.place(SolverAssignment(
        lessonId: lesson.id,
        day: cleanSlot.slot.day,
        period: cleanSlot.slot.period,
        roomId: cleanSlot.roomId,
      ));
      return true;
    }

    // 2. No clean slot — iterative DFS with explicit stack
    final stack = <_SwapFrame>[];
    final snapshotStack = <Map<String, SolverAssignment>>[];

    // Find initial ejection candidates
    final candidates = _findSwapCandidates(lesson, state);
    if (candidates.isEmpty) return false;

    // Push the first frame: try to place the original lesson
    stack.add(_SwapFrame(
      lessonToPlace: lesson,
      candidates: candidates,
      candidateIndex: 0,
    ));

    // Save initial snapshot for backtracking
    snapshotStack.add({for (final a in state.allAssignments) a.lessonId: a});

    int iterations = 0;

    while (stack.isNotEmpty && iterations < _maxIterations) {
      iterations++;
      final frame = stack.last;

      // If we've exhausted all candidates at this depth, backtrack
      if (frame.candidateIndex >= frame.candidates.length) {
        stack.removeLast();
        if (snapshotStack.length > stack.length + 1) {
          // Restore snapshot
          _restoreState(state, snapshotStack.last);
          snapshotStack.removeLast();
        }
        // Move to next candidate in parent frame
        if (stack.isNotEmpty) {
          stack.last.candidateIndex++;
        }
        continue;
      }

      // Depth limit check
      if (stack.length > _maxDepth) {
        stack.removeLast();
        if (snapshotStack.length > stack.length + 1) {
          _restoreState(state, snapshotStack.last);
          snapshotStack.removeLast();
        }
        if (stack.isNotEmpty) {
          stack.last.candidateIndex++;
        }
        continue;
      }

      final candidate = frame.candidates[frame.candidateIndex];

      // Save state before modifications
      snapshotStack.add({for (final a in state.allAssignments) a.lessonId: a});

      // Eject conflicts
      final ejectedLessons = <SolverLesson>[];
      for (final conflict in candidate.conflicts) {
        state.remove(conflict.lessonId);
        _addToTabu(conflict.lessonId, candidate.slot);
        final ejectedLesson = _lessonById[conflict.lessonId];
        if (ejectedLesson != null) ejectedLessons.add(ejectedLesson);
      }

      // Place current lesson
      final roomId = _findBestRoom(frame.lessonToPlace, candidate.slot, state);
      state.place(SolverAssignment(
        lessonId: frame.lessonToPlace.id,
        day: candidate.slot.day,
        period: candidate.slot.period,
        roomId: roomId,
      ));

      // Try to place all ejected lessons
      bool allPlaced = true;
      for (final ejected in ejectedLessons) {
        final cleanForEjected = _findCleanSlot(ejected, state);
        if (cleanForEjected != null) {
          state.place(SolverAssignment(
            lessonId: ejected.id,
            day: cleanForEjected.slot.day,
            period: cleanForEjected.slot.period,
            roomId: cleanForEjected.roomId,
          ));
        } else {
          // Need to go deeper — push a new frame for this ejected lesson
          final subCandidates = _findSwapCandidates(ejected, state);
          if (subCandidates.isEmpty) {
            allPlaced = false;
            break;
          }
          stack.add(_SwapFrame(
            lessonToPlace: ejected,
            candidates: subCandidates,
            candidateIndex: 0,
          ));
          allPlaced = false; // Not yet placed — need to recurse
          break;
        }
      }

      if (allPlaced && ejectedLessons.isNotEmpty) {
        // Everything placed! Clean up snapshot stack and return success.
        return true;
      }

      if (allPlaced && ejectedLessons.isEmpty) {
        return true; // Original lesson placed with no ejections needed
      }

      // If allPlaced is false and we pushed a new frame, continue DFS.
      // If allPlaced is false and we didn't push a new frame, backtrack.
      if (stack.last == frame) {
        // We didn't push a new frame — backtrack
        _restoreState(state, snapshotStack.last);
        snapshotStack.removeLast();
        frame.candidateIndex++;
      }
    }

    // Failed: restore to initial state
    if (snapshotStack.isNotEmpty) {
      _restoreState(state, snapshotStack.first);
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CLEAN SLOT FINDING (with bitmask acceleration)
  // ═══════════════════════════════════════════════════════════════════

  _ScoredSlot? _findCleanSlot(SolverLesson lesson, SolverState state) {
    final cleanSlots = <_ScoredSlot>[];

    for (int d = 0; d < payload.days; d++) {
      // Use bitmask to quickly find free periods
      final freeMask = _emptySlotMask(state, lesson, d);
      if (freeMask == 0) continue;

      for (int p = 0; p < payload.periodsPerDay; p++) {
        if ((freeMask & (1 << p)) == 0) continue; // Period not free
        if (_isTabu(lesson.id, SolverSlot(d, p))) continue;

        final slot = SolverSlot(d, p);
        final roomId = _findBestRoom(lesson, slot, state);
        final check = checker.checkHardWithState(state, lesson, slot, roomId);
        if (!check.hardViolation) {
          final score = _quickSlotScore(lesson, slot, state);
          cleanSlots.add(_ScoredSlot(slot, roomId, score));
        }
      }
    }

    if (cleanSlots.isEmpty) return null;
    cleanSlots.sort((a, b) => a.score.compareTo(b.score));
    return cleanSlots.first;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SWAP CANDIDATE FINDING
  // ═══════════════════════════════════════════════════════════════════

  List<_SwapCandidate> _findSwapCandidates(
      SolverLesson lesson, SolverState state) {
    final candidates = <_SwapCandidate>[];

    for (int d = 0; d < payload.days; d++) {
      for (int p = 0; p < payload.periodsPerDay; p++) {
        final slot = SolverSlot(d, p);
        if (_isTabu(lesson.id, slot)) continue;
        if (_hasIntrinsicBlock(lesson, slot)) continue;

        final conflicts = _findConflictsAt(lesson, slot, state);
        if (conflicts.isEmpty) continue;

        // Skip if any conflict is pinned
        if (conflicts.any((c) {
          final cl = _lessonById[c.lessonId];
          return cl != null && cl.isPinned;
        })) continue;

        // Skip if any conflict is tabu for this slot
        if (conflicts.any((c) => _isTabu(c.lessonId, slot))) continue;

        candidates.add(_SwapCandidate(
          slot: slot,
          conflicts: conflicts,
          cost: conflicts.length.toDouble(),
        ));
      }
    }

    // Sort by cost (fewest ejections first)
    candidates.sort((a, b) => a.cost.compareTo(b.cost));

    // Limit to top 5 candidates for performance
    if (candidates.length > 5) {
      return candidates.sublist(0, 5);
    }
    return candidates;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STATE RESTORATION
  // ═══════════════════════════════════════════════════════════════════

  void _restoreState(
      SolverState state, Map<String, SolverAssignment> snapshot) {
    // Remove all current assignments
    final currentIds = state.allAssignments.map((a) => a.lessonId).toList();
    for (final lid in currentIds) {
      state.remove(lid);
    }
    // Re-place from snapshot
    for (final a in snapshot.values) {
      state.place(a);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TABU MEMORY
  // ═══════════════════════════════════════════════════════════════════

  String _tabuKey(String lessonId, SolverSlot slot) =>
      '${lessonId}_${slot.day}_${slot.period}';

  bool _isTabu(String lessonId, SolverSlot slot) =>
      _tabuList.contains(_tabuKey(lessonId, slot));

  void _addToTabu(String lessonId, SolverSlot slot) {
    final key = _tabuKey(lessonId, slot);
    _tabuList.add(key);
    _tabuAge[key] = _globalStep;
  }

  void _ageTabuList() {
    final toRemove = <String>[];
    for (final entry in _tabuAge.entries) {
      if (_globalStep - entry.value > _tabuTenure) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _tabuList.remove(key);
      _tabuAge.remove(key);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS (using SolverState O(1) lookups)
  // ═══════════════════════════════════════════════════════════════════

  bool _hasIntrinsicBlock(SolverLesson lesson, SolverSlot slot) {
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

  /// Find conflicts using SolverState O(1) grid lookups instead of
  /// scanning the entire assignments list.
  List<SolverAssignment> _findConflictsAt(
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

      // Teacher clashes — O(1) per teacher
      for (final tid in lesson.teacherIds) {
        if (state.isTeacherBusy(tid, checkSlot.day, checkSlot.period)) {
          // Find which lessons cause the clash
          for (final lid in state.lessonsAt(checkSlot.day, checkSlot.period)) {
            final existingLesson = _lessonById[lid];
            if (existingLesson != null &&
                existingLesson.teacherIds.contains(tid)) {
              conflicts.add(lid);
            }
          }
        }
      }

      // Class clashes — O(1) per class
      for (final cid in lesson.classIds) {
        if (state.isClassBusy(cid, checkSlot.day, checkSlot.period)) {
          for (final lid in state.lessonsAt(checkSlot.day, checkSlot.period)) {
            final existingLesson = _lessonById[lid];
            if (existingLesson == null) continue;
            if (!existingLesson.classIds.contains(cid)) continue;

            // Division exception
            if (lesson.divisionId != null &&
                existingLesson.divisionId != null &&
                lesson.divisionId != existingLesson.divisionId &&
                lesson.classIds.length == 1 &&
                existingLesson.classIds.length == 1 &&
                lesson.classIds.first == existingLesson.classIds.first) {
              continue;
            }
            conflicts.add(lid);
          }
        }
      }
    }

    // Convert to assignments
    return conflicts
        .map((lid) => state.assignmentFor(lid))
        .whereType<SolverAssignment>()
        .toList();
  }

  double _quickSlotScore(
      SolverLesson lesson, SolverSlot slot, SolverState state) {
    double score = 0;
    for (final tid in lesson.teacherIds) {
      score += state.teacherDayLoad(tid, slot.day) * 2.0;
    }
    score += Random().nextDouble() * 0.1;
    return score;
  }

  String _findBestRoom(
      SolverLesson lesson, SolverSlot slot, SolverState state) {
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

class RecursiveSwapResult {
  final List<SolverAssignment> assignments;
  final List<String> unscheduledIds;

  const RecursiveSwapResult({
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

class _SwapCandidate {
  final SolverSlot slot;
  final List<SolverAssignment> conflicts;
  final double cost;

  const _SwapCandidate({
    required this.slot,
    required this.conflicts,
    required this.cost,
  });
}

/// Stack frame for iterative DFS — replaces recursive calls.
class _SwapFrame {
  final SolverLesson lessonToPlace;
  final List<_SwapCandidate> candidates;
  int candidateIndex;

  _SwapFrame({
    required this.lessonToPlace,
    required this.candidates,
    required this.candidateIndex,
  });
}
