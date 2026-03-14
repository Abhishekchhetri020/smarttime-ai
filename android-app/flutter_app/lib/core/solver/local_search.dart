// Local search optimizer — Phase 3 of the solver pipeline.
//
// Takes a feasible solution and optimizes its soft constraint score
// using Simulated Annealing (SA).
//
// Moves:
// - Swap two lesson assignments
// - Relocate a single lesson to a different slot
// - Change room assignment

import 'dart:math';

import 'constraint_checker.dart';
import 'solver_models.dart';

class LocalSearch {
  final SolverPayload payload;
  final ConstraintChecker checker;
  final void Function(SolverProgress)? onProgress;

  /// SA parameters
  final double initialTemperature;
  final double coolingRate;
  final int maxIterations;

  LocalSearch({
    required this.payload,
    required this.checker,
    this.onProgress,
    this.initialTemperature = 100.0,
    this.coolingRate = 0.995,
    this.maxIterations = 50000,
  });

  /// Optimize the given solution and return an improved variant.
  LocalSearchResult run(
    List<SolverAssignment> initialAssignments,
    List<String> unscheduledIds,
    int variantIndex,
  ) {
    final rng = Random();
    final sw = Stopwatch()..start();

    var current = List<SolverAssignment>.from(initialAssignments);
    var currentVariant = checker.scoreSolution(current, unscheduledIds, variantIndex);
    var bestAssignments = List<SolverAssignment>.from(current);
    var bestScore = currentVariant.totalScore;

    double temperature = initialTemperature;
    int accepted = 0;
    int improved = 0;

    final lessonById = {for (final l in payload.lessons) l.id: l};

    for (int iter = 0; iter < maxIterations; iter++) {
      // Timeout check (use remaining 30% of budget)
      if (sw.elapsedMilliseconds > payload.timeoutMs * 0.3) break;

      if (iter % 2000 == 0) {
        onProgress?.call(SolverProgress(
          phase: 'optimize',
          percent: iter / maxIterations,
          message: 'SA iteration $iter, score: ${currentVariant.totalScore.toStringAsFixed(1)}, best: ${bestScore.toStringAsFixed(1)}',
          currentVariant: variantIndex,
        ));
      }

      // Generate neighbor
      final move = _generateMove(current, lessonById, rng);
      if (move == null) continue;

      // Apply move
      final neighbor = _applyMove(current, move);

      // Check hard constraints for the moved lesson(s)
      bool feasible = true;
      for (final movedLid in move.affectedLessonIds) {
        final movedAssignment = neighbor.firstWhere((a) => a.lessonId == movedLid);
        final lesson = lessonById[movedLid];
        if (lesson == null) continue;

        final otherAssignments = neighbor.where((a) => a.lessonId != movedLid).toList();
        final check = checker.checkHard(lesson, movedAssignment.slot, movedAssignment.roomId, otherAssignments);
        if (check.hardViolation) {
          feasible = false;
          break;
        }
      }

      if (!feasible) continue;

      // Score neighbor
      final neighborVariant = checker.scoreSolution(neighbor, unscheduledIds, variantIndex);
      final delta = neighborVariant.totalScore - currentVariant.totalScore;

      // Accept or reject
      if (delta < 0 || rng.nextDouble() < exp(-delta / temperature)) {
        current = neighbor;
        currentVariant = neighborVariant;
        accepted++;

        if (currentVariant.totalScore < bestScore) {
          bestAssignments = List<SolverAssignment>.from(current);
          bestScore = currentVariant.totalScore;
          improved++;
        }
      }

      temperature *= coolingRate;

      // Reheat if stuck
      if (iter > 0 && iter % 10000 == 0 && improved == 0) {
        temperature = initialTemperature * 0.5;
      }
    }

    sw.stop();

    onProgress?.call(SolverProgress(
      phase: 'optimize',
      percent: 1.0,
      message: 'SA complete. Accepted $accepted moves, $improved improvements in ${sw.elapsedMilliseconds}ms',
      currentVariant: variantIndex,
    ));

    return LocalSearchResult(
      assignments: bestAssignments,
      score: bestScore,
    );
  }

  _Move? _generateMove(
    List<SolverAssignment> assignments,
    Map<String, SolverLesson> lessonById,
    Random rng,
  ) {
    if (assignments.isEmpty) return null;

    final moveType = rng.nextInt(3);

    switch (moveType) {
      case 0: // Relocate a random lesson to a random valid slot
        final idx = rng.nextInt(assignments.length);
        final assignment = assignments[idx];
        final lesson = lessonById[assignment.lessonId];
        if (lesson == null || lesson.isPinned) return null;

        final newDay = rng.nextInt(payload.days);
        final newPeriod = rng.nextInt(payload.periodsPerDay);
        if (newDay == assignment.day && newPeriod == assignment.period) return null;

        return _RelocateMove(
          lessonId: assignment.lessonId,
          newDay: newDay,
          newPeriod: newPeriod,
          newRoomId: assignment.roomId,
        );

      case 1: // Swap two lessons
        if (assignments.length < 2) return null;
        final i = rng.nextInt(assignments.length);
        var j = rng.nextInt(assignments.length);
        if (i == j) j = (j + 1) % assignments.length;

        final a = assignments[i];
        final b = assignments[j];
        final la = lessonById[a.lessonId];
        final lb = lessonById[b.lessonId];
        if (la == null || lb == null || la.isPinned || lb.isPinned) return null;

        return _SwapMove(
          lessonIdA: a.lessonId,
          lessonIdB: b.lessonId,
        );

      case 2: // Change room for a lesson
        if (payload.rooms.length < 2) return null;
        final idx = rng.nextInt(assignments.length);
        final assignment = assignments[idx];
        final lesson = lessonById[assignment.lessonId];
        if (lesson == null || lesson.isPinned) return null;
        if (lesson.requiredRoomId != null) return null;

        final newRoom = payload.rooms[rng.nextInt(payload.rooms.length)];
        if (newRoom.id == assignment.roomId) return null;

        return _RoomChangeMove(
          lessonId: assignment.lessonId,
          newRoomId: newRoom.id,
        );

      default:
        return null;
    }
  }

  List<SolverAssignment> _applyMove(
    List<SolverAssignment> assignments,
    _Move move,
  ) {
    final result = List<SolverAssignment>.from(assignments);

    if (move is _RelocateMove) {
      final idx = result.indexWhere((a) => a.lessonId == move.lessonId);
      if (idx >= 0) {
        result[idx] = result[idx].copyWith(
          day: move.newDay,
          period: move.newPeriod,
          roomId: move.newRoomId,
        );
      }
    } else if (move is _SwapMove) {
      final iA = result.indexWhere((a) => a.lessonId == move.lessonIdA);
      final iB = result.indexWhere((a) => a.lessonId == move.lessonIdB);
      if (iA >= 0 && iB >= 0) {
        final dayA = result[iA].day;
        final periodA = result[iA].period;
        final roomA = result[iA].roomId;

        result[iA] = result[iA].copyWith(
          day: result[iB].day,
          period: result[iB].period,
          roomId: result[iB].roomId,
        );
        result[iB] = result[iB].copyWith(
          day: dayA,
          period: periodA,
          roomId: roomA,
        );
      }
    } else if (move is _RoomChangeMove) {
      final idx = result.indexWhere((a) => a.lessonId == move.lessonId);
      if (idx >= 0) {
        result[idx] = result[idx].copyWith(roomId: move.newRoomId);
      }
    }

    return result;
  }
}

class LocalSearchResult {
  final List<SolverAssignment> assignments;
  final double score;

  const LocalSearchResult({
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
