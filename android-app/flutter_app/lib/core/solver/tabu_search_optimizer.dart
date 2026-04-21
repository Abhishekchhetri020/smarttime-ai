// Tabu Search Optimizer — Phase 3 of the Hybrid Solver Pipeline.
//
// Inspired by Timefold/OptaPlanner's metaheuristic approach.
// Takes a fully-placed (or near-fully-placed) timetable and optimizes
// soft constraints using Entity Tabu Search.
//
// NOW USES SolverState O(1) matrix for all feasibility checks.

import 'dart:math';

import 'constraint_checker.dart';
import 'engine_constraints.dart';
import 'solver_models.dart';

class TabuSearchOptimizer {
  final SolverPayload payload;
  final ConstraintChecker checker;
  final void Function(SolverProgress)? onProgress;

  /// Tabu parameters
  final int tabuTenure;
  final int maxIterations;

  TabuSearchOptimizer({
    required this.payload,
    required this.checker,
    this.onProgress,
    this.tabuTenure = 15,
    this.maxIterations = 60000,
  });

  /// Optimize the given solution. Returns improved assignments.
  TabuSearchResult run(
    List<SolverAssignment> initialAssignments,
    List<String> unscheduledIds,
    int variantIndex,
  ) {
    final rng = Random(variantIndex * 42 + 7);
    final sw = Stopwatch()..start();
    final lessonById = {for (final l in payload.lessons) l.id: l};

    // Build SolverState from initial assignments
    var state = SolverState.fromAssignments(payload, initialAssignments);
    var currentScore = checker
        .scoreSolutionWithState(state, unscheduledIds, variantIndex)
        .totalScore;
    var bestState = state.clone();
    var bestScore = currentScore;

    // Entity Tabu list: maps lesson ID → iteration when it becomes non-tabu
    final entityTabu = <String, int>{};

    // Late Acceptance list (for LAHC fallback)
    const lahcSize = 500;
    final lahcList = List<double>.filled(lahcSize, currentScore);

    int improved = 0;
    int accepted = 0;

    for (int iter = 0; iter < maxIterations; iter++) {
      // Timeout: use 30% of total budget
      if (sw.elapsedMilliseconds > payload.timeoutMs * 0.3) break;

      if (iter % 3000 == 0) {
        onProgress?.call(SolverProgress(
          phase: 'optimize',
          percent: iter / maxIterations,
          message:
              'Tabu iter $iter, score: ${currentScore.toStringAsFixed(1)}, best: ${bestScore.toStringAsFixed(1)}',
          currentVariant: variantIndex,
        ));
      }

      // Generate neighborhood move
      final move = _generateMove(state, lessonById, rng);
      if (move == null) continue;

      // Apply move onto a cloned state
      final neighborState = state.clone();
      final feasible = _applyMoveToState(neighborState, move, lessonById);
      if (!feasible) continue;

      // Verify hard constraints for all affected lessons.
      // Build a CLEAN verification state from neighbor's assignments,
      // excluding each affected lesson in turn, as the gold-standard check.
      bool valid = true;
      final neighborAssignments = neighborState.allAssignments;

      for (final affectedLid in move.affectedLessonIds) {
        final lesson = lessonById[affectedLid];
        final assignment = neighborState.assignmentFor(affectedLid);
        if (lesson == null || assignment == null) {
          valid = false;
          break;
        }

        // Build state without this lesson
        final checkState = SolverState(payload);
        for (final a in neighborAssignments) {
          if (a.lessonId != affectedLid) {
            checkState.place(a);
          }
        }

        final code = checker.checkHardFast(
          checkState,
          lesson,
          SolverSlot(assignment.day, assignment.period),
          assignment.roomId,
        );
        if (code != 0) {
          valid = false;
          break;
        }
      }
      if (!valid) continue;

      // Score neighbor using SolverState
      final neighborScore = checker
          .scoreSolutionWithState(neighborState, unscheduledIds, variantIndex)
          .totalScore;

      // Is any affected entity Tabu?
      final isTabu = move.affectedLessonIds
          .any((lid) => entityTabu.containsKey(lid) && entityTabu[lid]! > iter);

      // Aspiration criterion: accept Tabu move if it beats global best
      final aspirationMet = neighborScore < bestScore;

      // Late Acceptance criterion
      final lahcIdx = iter % lahcSize;
      final lateScore = lahcList[lahcIdx];
      final lahcAccept = neighborScore <= lateScore;

      // Accept move?
      final delta = neighborScore - currentScore;
      final accept = aspirationMet || (!isTabu && (delta < 0 || lahcAccept));

      if (accept) {
        state = neighborState;
        currentScore = neighborScore;
        lahcList[lahcIdx] = currentScore;
        accepted++;

        // Add moved entities to Tabu
        for (final lid in move.affectedLessonIds) {
          entityTabu[lid] = iter + tabuTenure;
        }

        // Track global best
        if (currentScore < bestScore) {
          bestState = state.clone();
          bestScore = currentScore;
          improved++;
        }
      }
    }

    sw.stop();

    onProgress?.call(SolverProgress(
      phase: 'optimize',
      percent: 1.0,
      message:
          'Tabu search complete. Accepted $accepted moves, $improved improvements in ${sw.elapsedMilliseconds}ms',
      currentVariant: variantIndex,
    ));

    return TabuSearchResult(
      assignments: bestState.allAssignments,
      score: bestScore,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MOVE GENERATION
  // ═══════════════════════════════════════════════════════════════════

  _Move? _generateMove(
    SolverState state,
    Map<String, SolverLesson> lessonById,
    Random rng,
  ) {
    final assignments = state.allAssignments;
    if (assignments.isEmpty) return null;

    final moveType = rng.nextInt(3);

    switch (moveType) {
      case 0: // Relocate
        final idx = rng.nextInt(assignments.length);
        final assignment = assignments[idx];
        final lesson = lessonById[assignment.lessonId];
        if (lesson == null || lesson.isPinned) return null;

        final newDay = rng.nextInt(payload.days);
        final newPeriod = rng.nextInt(payload.periodsPerDay);
        if (newDay == assignment.day && newPeriod == assignment.period) {
          return null;
        }

        return _RelocateMove(
          lessonId: assignment.lessonId,
          newDay: newDay,
          newPeriod: newPeriod,
          newRoomId: assignment.roomId,
        );

      case 1: // Swap
        if (assignments.length < 2) return null;
        final i = rng.nextInt(assignments.length);
        var j = rng.nextInt(assignments.length);
        if (i == j) j = (j + 1) % assignments.length;

        final a = assignments[i];
        final b = assignments[j];
        final la = lessonById[a.lessonId];
        final lb = lessonById[b.lessonId];
        if (la == null || lb == null || la.isPinned || lb.isPinned) return null;

        return _SwapMove(lessonIdA: a.lessonId, lessonIdB: b.lessonId);

      case 2: // Room change
        if (payload.rooms.length < 2) return null;
        final idx = rng.nextInt(assignments.length);
        final assignment = assignments[idx];
        final lesson = lessonById[assignment.lessonId];
        if (lesson == null || lesson.isPinned) return null;
        if (lesson.requiredRoomId != null) return null;

        final newRoom = payload.rooms[rng.nextInt(payload.rooms.length)];
        if (newRoom.id == assignment.roomId) return null;

        return _RoomChangeMove(
            lessonId: assignment.lessonId, newRoomId: newRoom.id);

      default:
        return null;
    }
  }

  /// Apply a move to a SolverState, returning false if the move is invalid.
  bool _applyMoveToState(
    SolverState state,
    _Move move,
    Map<String, SolverLesson> lessonById,
  ) {
    if (move is _RelocateMove) {
      final current = state.assignmentFor(move.lessonId);
      if (current == null) return false;
      state.remove(move.lessonId);
      state.place(SolverAssignment(
        lessonId: move.lessonId,
        day: move.newDay,
        period: move.newPeriod,
        roomId: move.newRoomId,
      ));
    } else if (move is _SwapMove) {
      final aAssign = state.assignmentFor(move.lessonIdA);
      final bAssign = state.assignmentFor(move.lessonIdB);
      if (aAssign == null || bAssign == null) return false;

      state.remove(move.lessonIdA);
      state.remove(move.lessonIdB);

      state.place(SolverAssignment(
        lessonId: move.lessonIdA,
        day: bAssign.day,
        period: bAssign.period,
        roomId: bAssign.roomId,
      ));
      state.place(SolverAssignment(
        lessonId: move.lessonIdB,
        day: aAssign.day,
        period: aAssign.period,
        roomId: aAssign.roomId,
      ));
    } else if (move is _RoomChangeMove) {
      final current = state.assignmentFor(move.lessonId);
      if (current == null) return false;
      state.remove(move.lessonId);
      state.place(SolverAssignment(
        lessonId: move.lessonId,
        day: current.day,
        period: current.period,
        roomId: move.newRoomId,
      ));
    }
    return true;
  }
}

class TabuSearchResult {
  final List<SolverAssignment> assignments;
  final double score;

  const TabuSearchResult({
    required this.assignments,
    required this.score,
  });
}

// ── Move types ──

abstract class _Move {
  List<String> get affectedLessonIds;
}

class _RelocateMove extends _Move {
  final String lessonId;
  final int newDay;
  final int newPeriod;
  final String newRoomId;

  _RelocateMove({
    required this.lessonId,
    required this.newDay,
    required this.newPeriod,
    required this.newRoomId,
  });

  @override
  List<String> get affectedLessonIds => [lessonId];
}

class _SwapMove extends _Move {
  final String lessonIdA;
  final String lessonIdB;

  _SwapMove({required this.lessonIdA, required this.lessonIdB});

  @override
  List<String> get affectedLessonIds => [lessonIdA, lessonIdB];
}

class _RoomChangeMove extends _Move {
  final String lessonId;
  final String newRoomId;

  _RoomChangeMove({required this.lessonId, required this.newRoomId});

  @override
  List<String> get affectedLessonIds => [lessonId];
}
