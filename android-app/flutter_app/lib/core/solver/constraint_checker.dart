// Constraint checker for the pure-Dart timetable solver.
//
// Delegates to a registered list of EngineConstraint plugins.
// Provides both single-assignment hard-check (used millions of times
// during Phase 1 & 2) and full-solution soft-scoring (Phase 3).
//
// IMPORTANT: This file is the bridge between the old API (used by IFS,
// RecursiveSwapSolver, and TabuSearchOptimizer) and the new extensible
// constraint engine. All three pipeline phases call `checkHard()` and
// `scoreSolution()` via this class.

import 'engine_constraints.dart';
import 'solver_models.dart';

/// Result of checking a single proposed assignment against the current state.
class ConstraintCheckResult {
  final bool hardViolation;
  final String? hardReason;
  final double softPenalty;
  final Map<String, double> penaltyBreakdown;

  const ConstraintCheckResult({
    this.hardViolation = false,
    this.hardReason,
    this.softPenalty = 0.0,
    this.penaltyBreakdown = const {},
  });

  static const ok = ConstraintCheckResult();
}

class ConstraintChecker {
  final SolverPayload payload;
  final List<EngineConstraint> constraints;


  /// Hard constraint violation reason codes → human-readable messages
  static const _violationMessages = <int, String>{
    1: 'Slot out of bounds',
    2: 'Double lesson does not fit — no consecutive period available',
    3: 'Teacher already teaching at this slot',
    4: 'Class already has a lesson at this slot',
    5: 'Room already occupied at this slot',
    6: 'Teacher unavailable at this slot',
    7: 'Teacher exceeds max periods per day',
    8: 'Class exceeds max periods per day',
    9: 'Lesson requires a specific room',
    10: 'Pinned lesson must be at its designated slot',
  };

  ConstraintChecker(this.payload, {List<EngineConstraint>? constraints})
      : constraints = constraints ?? defaultConstraints();

  // ═══════════════════════════════════════════════════════════════════
  //  HARD CONSTRAINT CHECKS (delegated to plugins)
  // ═══════════════════════════════════════════════════════════════════

  /// Check if placing [lesson] at [slot] with [roomId] would violate
  /// any hard constraint given current [assignments].
  ///
  /// This method builds a temporary SolverState from the assignments list
  /// for backward compatibility. For performance-critical paths, prefer
  /// using [checkHardFast] with a pre-built SolverState.
  ConstraintCheckResult checkHard(
    SolverLesson lesson,
    SolverSlot slot,
    String roomId,
    List<SolverAssignment> assignments,
  ) {
    // Build a temporary state from the flat list (compatibility bridge)
    final state = SolverState.fromAssignments(payload, assignments);
    return checkHardWithState(state, lesson, slot, roomId);
  }

  /// Performance-optimized hard check using a pre-built SolverState.
  /// Use this in tight loops (IFS, RecursiveSwap) to avoid rebuilding
  /// the state on every call.
  ConstraintCheckResult checkHardWithState(
    SolverState state,
    SolverLesson lesson,
    SolverSlot slot,
    String roomId,
  ) {
    for (final constraint in constraints) {
      if (!constraint.isHard) continue;
      final code = constraint.checkHard(state, lesson, slot, roomId);
      if (code != 0) {
        return ConstraintCheckResult(
          hardViolation: true,
          hardReason: _violationMessages[code] ?? 'Constraint violated: ${constraint.name} (code $code)',
        );
      }
    }
    return ConstraintCheckResult.ok;
  }

  /// Ultra-fast hard check returning just an int (0 = OK, >0 = violation).
  /// Zero allocations. Use in the hottest loops.
  int checkHardFast(
    SolverState state,
    SolverLesson lesson,
    SolverSlot slot,
    String roomId,
  ) {
    for (final constraint in constraints) {
      if (!constraint.isHard) continue;
      final code = constraint.checkHard(state, lesson, slot, roomId);
      if (code != 0) return code;
    }
    return 0;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SOFT CONSTRAINT SCORING (delegated to plugins)
  // ═══════════════════════════════════════════════════════════════════

  /// Score an entire solution. Lower score = better.
  SolverVariant scoreSolution(
    List<SolverAssignment> assignments,
    List<String> unscheduledIds,
    int variantIndex,
  ) {
    final state = SolverState.fromAssignments(payload, assignments);
    return scoreSolutionWithState(state, unscheduledIds, variantIndex);
  }

  /// Score using a pre-built state (avoids rebuilding).
  SolverVariant scoreSolutionWithState(
    SolverState state,
    List<String> unscheduledIds,
    int variantIndex,
  ) {
    final breakdown = <String, double>{};
    double total = 0.0;

    // Heavy penalty for unscheduled lessons
    final unscheduledPenalty = unscheduledIds.length * 100.0;
    breakdown['unscheduled'] = unscheduledPenalty;
    total += unscheduledPenalty;

    // Weight mapping for backward compatibility with SoftWeights
    final weightMap = <String, double>{
      'Teacher Gaps': payload.softWeights.teacherGaps,
      'Class Gaps': payload.softWeights.classGaps,
      'Subject Distribution': payload.softWeights.subjectDistribution,
      'Room Stability': payload.softWeights.teacherRoomStability,
      'Teacher Consecutive': payload.softWeights.teacherConsecutive,
      'Workload Balance': payload.softWeights.workloadBalance,
      'Morning Preference': payload.softWeights.morningPreference,
      'Orphan Periods': payload.softWeights.orphanPeriodPenalty,
    };

    for (final constraint in constraints) {
      if (constraint.isHard) continue;
      final rawScore = constraint.scoreSoft(state);
      final weight = weightMap[constraint.name] ?? 1.0;
      final weighted = rawScore * weight;
      breakdown[constraint.name] = weighted;
      total += weighted;
    }

    return SolverVariant(
      variantIndex: variantIndex,
      assignments: state.allAssignments,
      totalScore: total,
      hardViolations: 0,
      scoreBreakdown: breakdown,
      unscheduledLessonIds: unscheduledIds,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UTILITY: Available slots for a given lesson
  // ═══════════════════════════════════════════════════════════════════

  /// Returns all slots where [lesson] could potentially be placed without
  /// hard constraint violations.
  List<SolverSlot> availableSlots(
    SolverLesson lesson,
    List<SolverAssignment> assignments,
    String roomId,
  ) {
    final state = SolverState.fromAssignments(payload, assignments);
    final available = <SolverSlot>[];
    for (int d = 0; d < payload.days; d++) {
      for (int p = 0; p < payload.periodsPerDay; p++) {
        final slot = SolverSlot(d, p);
        if (checkHardFast(state, lesson, slot, roomId) == 0) {
          available.add(slot);
        }
      }
    }
    return available;
  }
}
