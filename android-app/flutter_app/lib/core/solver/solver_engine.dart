// Solver Engine — Isolate-based orchestrator for the 3-phase pipeline.
//
// This is the main entry point for solving timetables. It runs entirely
// in a Dart Isolate so the UI thread stays responsive.
//
// Pipeline:
//   Phase 1: Greedy Seed  — fast initial solution
//   Phase 2: Backtracking — fill remaining gaps with AC-3 + MRV
//   Phase 3: Local Search — optimize soft constraints via Simulated Annealing
//
// Produces up to N variants by running the pipeline with different
// random seeds.

import 'dart:async';
import 'dart:isolate';

import 'constraint_checker.dart';
import 'engine_constraints.dart';
import 'iterative_forward_search.dart';
import 'recursive_swap_solver.dart';
import 'solver_models.dart';
import 'tabu_search_optimizer.dart';

/// Run the solver synchronously (for use inside an Isolate).
SolverResult _solveSync(
  SolverPayload payload,
  void Function(SolverProgress)? onProgress, [
  List<EngineConstraint>? customConstraints,
]) {
  final sw = Stopwatch()..start();
  final checker = ConstraintChecker(payload, constraints: customConstraints);
  final variants = <SolverVariant>[];

  for (int v = 0; v < payload.variantCount; v++) {
    onProgress?.call(SolverProgress(
      phase: 'ifs',
      percent: 0.0,
      message: 'Starting variant ${v + 1} of ${payload.variantCount}',
      currentVariant: v,
    ));

    // Phase 1: Iterative Forward Search (UniTime-style)
    final ifsSolver = IterativeForwardSearch(
      payload: payload,
      checker: checker,
      onProgress: onProgress,
    );
    final ifsResult = ifsSolver.run();

    onProgress?.call(SolverProgress(
      phase: 'swap',
      percent: 0.0,
      message: 'IFS placed ${ifsResult.assignments.length}/${payload.lessons.length}. Recursive swapping ${ifsResult.unscheduledIds.length} remaining...',
      currentVariant: v,
    ));

    // Phase 2: Recursive Swap Solver (FET-style)
    List<SolverAssignment> assignments;
    List<String> unscheduled;

    if (ifsResult.unscheduledIds.isNotEmpty) {
      final swapSolver = RecursiveSwapSolver(
        payload: payload,
        checker: checker,
        onProgress: onProgress,
      );
      final swapResult = swapSolver.run(
        ifsResult.assignments,
        ifsResult.unscheduledIds,
      );
      assignments = swapResult.assignments;
      unscheduled = swapResult.unscheduledIds;
    } else {
      assignments = ifsResult.assignments;
      unscheduled = const [];
    }

    onProgress?.call(SolverProgress(
      phase: 'optimize',
      percent: 0.0,
      message: 'Scheduled ${assignments.length}/${payload.lessons.length}. Optimizing with Tabu Search...',
      currentVariant: v,
    ));

    // Phase 3: Tabu Search Optimization (Timefold-style)
    final optimizer = TabuSearchOptimizer(
      payload: payload,
      checker: checker,
      onProgress: onProgress,
    );
    final optimized = optimizer.run(assignments, unscheduled, v);

    // ── VALIDATION FENCE (two-pass) ──
    // Pass 1: Atomic check — remove each assignment, verify against
    //         all others, re-add. Catches per-entity violations
    //         (max-consecutive, max-per-day) without ordering bias.
    final atomicState = SolverState.fromAssignments(payload, optimized.assignments);
    final pass1Invalid = <String>{};

    for (final a in optimized.assignments) {
      final lesson = atomicState.lessonById[a.lessonId];
      if (lesson == null) { pass1Invalid.add(a.lessonId); continue; }

      atomicState.remove(a.lessonId);
      final code = checker.checkHardFast(
        atomicState, lesson, SolverSlot(a.day, a.period), a.roomId);
      if (code != 0) {
        pass1Invalid.add(a.lessonId);
      } else {
        atomicState.place(a);
      }
    }

    // Pass 2: Incremental rebuild — adds surviving assignments one-by-one.
    //         This catches any pairwise conflicts (double-bookings) that
    //         the atomic pass couldn't detect.
    final rebuildState = SolverState(payload);
    final validAssignments = <SolverAssignment>[];
    final allInvalid = <String>{...pass1Invalid};

    for (final a in optimized.assignments) {
      if (pass1Invalid.contains(a.lessonId)) continue;
      final lesson = rebuildState.lessonById[a.lessonId];
      if (lesson == null) continue;

      final code = checker.checkHardFast(
        rebuildState, lesson, SolverSlot(a.day, a.period), a.roomId);
      if (code == 0) {
        rebuildState.place(a);
        validAssignments.add(a);
      } else {
        allInvalid.add(a.lessonId);
      }
    }

    final postUnscheduled = [...unscheduled, ...allInvalid];

    // Score final validated solution
    final variant = checker.scoreSolution(validAssignments, postUnscheduled, v);
    variants.add(variant);

    // Timeout check for total run
    if (sw.elapsedMilliseconds > payload.timeoutMs) break;
  }

  sw.stop();

  // Sort by score (lower is better)
  variants.sort((a, b) => a.totalScore.compareTo(b.totalScore));

  final allScheduled = variants.isNotEmpty && variants.first.isComplete;
  final status = allScheduled
      ? 'SUCCESS'
      : (variants.isNotEmpty ? 'PARTIAL' : 'INFEASIBLE');

  return SolverResult(
    variants: variants,
    elapsedMs: sw.elapsedMilliseconds,
    status: status,
    errorMessage: allScheduled
        ? null
        : 'Could not schedule ${variants.firstOrNull?.unscheduledLessonIds.length ?? payload.lessons.length} lesson(s)',
  );
}

/// Isolate entry point.
void _isolateEntryPoint(_IsolateMessage msg) {
  final result = _solveSync(msg.payload, (progress) {
    msg.progressPort.send(progress);
  });
  msg.resultPort.send(result);
}

class _IsolateMessage {
  final SolverPayload payload;
  final SendPort resultPort;
  final SendPort progressPort;

  const _IsolateMessage({
    required this.payload,
    required this.resultPort,
    required this.progressPort,
  });
}

/// Public API: run the solver in an Isolate with progress stream.
class SolverEngine {
  /// Solve the timetable in a background Isolate.
  ///
  /// Returns a [SolverResult] with up to [SolverPayload.variantCount]
  /// ranked variants.
  ///
  /// [onProgress] is called on the main thread with solver progress updates.
  static Future<SolverResult> solve(
    SolverPayload payload, {
    void Function(SolverProgress)? onProgress,
  }) async {
    final resultPort = ReceivePort();
    final progressPort = ReceivePort();

    // Listen for progress updates
    StreamSubscription? progressSub;
    if (onProgress != null) {
      progressSub = progressPort.listen((message) {
        if (message is SolverProgress) {
          onProgress(message);
        }
      });
    }

    // Spawn isolate
    final message = _IsolateMessage(
      payload: payload,
      resultPort: resultPort.sendPort,
      progressPort: progressPort.sendPort,
    );

    await Isolate.spawn(_isolateEntryPoint, message);

    // Wait for result
    final result = await resultPort.first as SolverResult;

    await progressSub?.cancel();
    resultPort.close();
    progressPort.close();

    return result;
  }

  /// Solve synchronously on the current thread (for testing or small datasets).
  static SolverResult solveSync(
    SolverPayload payload, {
    void Function(SolverProgress)? onProgress,
    List<EngineConstraint>? constraints,
  }) {
    return _solveSync(payload, onProgress, constraints);
  }
}
