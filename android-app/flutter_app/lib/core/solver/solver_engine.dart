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

import 'backtrack_solver.dart';
import 'constraint_checker.dart';
import 'greedy_seed.dart';
import 'local_search.dart';
import 'solver_models.dart';

/// Run the solver synchronously (for use inside an Isolate).
SolverResult _solveSync(
  SolverPayload payload,
  void Function(SolverProgress)? onProgress,
) {
  final sw = Stopwatch()..start();
  final checker = ConstraintChecker(payload);
  final variants = <SolverVariant>[];

  for (int v = 0; v < payload.variantCount; v++) {
    onProgress?.call(SolverProgress(
      phase: 'greedy',
      percent: 0.0,
      message: 'Starting variant ${v + 1} of ${payload.variantCount}',
      currentVariant: v,
    ));

    // Phase 1: Greedy Seed
    final greedy = GreedySeed(
      payload: payload,
      checker: checker,
      onProgress: onProgress,
    );
    final seedResult = greedy.run();

    onProgress?.call(SolverProgress(
      phase: 'backtrack',
      percent: 0.0,
      message: 'Greedy placed ${seedResult.assignments.length}/${payload.lessons.length} lessons. Backtracking ${seedResult.unscheduledIds.length} remaining...',
      currentVariant: v,
    ));

    // Phase 2: Backtracking (only if there are unscheduled lessons)
    List<SolverAssignment> assignments;
    List<String> unscheduled;

    if (seedResult.unscheduledIds.isNotEmpty) {
      final backtracker = BacktrackSolver(
        payload: payload,
        checker: checker,
        onProgress: onProgress,
      );
      final btResult = backtracker.run(
        seedResult.assignments,
        seedResult.unscheduledIds,
      );
      assignments = btResult.assignments;
      unscheduled = btResult.unscheduledIds;
    } else {
      assignments = seedResult.assignments;
      unscheduled = const [];
    }

    onProgress?.call(SolverProgress(
      phase: 'optimize',
      percent: 0.0,
      message: 'Scheduled ${assignments.length}/${payload.lessons.length}. Optimizing soft constraints...',
      currentVariant: v,
    ));

    // Phase 3: Local Search Optimization
    final optimizer = LocalSearch(
      payload: payload,
      checker: checker,
      onProgress: onProgress,
    );
    final optimized = optimizer.run(assignments, unscheduled, v);

    // Score final solution
    final variant = checker.scoreSolution(optimized.assignments, unscheduled, v);
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
  }) {
    return _solveSync(payload, onProgress);
  }
}
