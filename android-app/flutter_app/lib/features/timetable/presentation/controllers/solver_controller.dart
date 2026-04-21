import 'package:flutter/foundation.dart';

import 'dart:async';

import '../../../../core/solver/dart_solver_payload_mapper.dart';
import '../../../../core/solver/solver_engine.dart';
import '../../../../core/solver/solver_models.dart';
import '../../../admin/planner_state.dart';
import '../../data/conflict_service.dart';
import '../../data/native_solver_client.dart';
import '../../data/solver_payload_mapper.dart';
import '../../data/solver_progress_stream.dart';

class TimetableAssignment {
  final String lessonId;
  final int day;
  final int period;
  final String subjectId;
  final List<String> classIds;
  final List<String> teacherIds;
  final String roomId;

  const TimetableAssignment({
    required this.lessonId,
    required this.day,
    required this.period,
    required this.subjectId,
    required this.classIds,
    required this.teacherIds,
    this.roomId = '',
  });

  TimetableAssignment copyWith({
    int? day,
    int? period,
  }) {
    return TimetableAssignment(
      lessonId: lessonId,
      day: day ?? this.day,
      period: period ?? this.period,
      subjectId: subjectId,
      classIds: classIds,
      teacherIds: teacherIds,
      roomId: roomId,
    );
  }
}

class SolverController extends ChangeNotifier {
  SolverController({
    required this.client,
    required this.mapper,
    required this.conflictService,
  });

  final NativeSolverClient client;
  final SolverPayloadMapper mapper;
  final ConflictService conflictService;

  bool isLoading = false;
  String? status;
  String? error;
  String? lastMoveError;
  final List<TimetableAssignment> assignments = [];
  List<String> failureHints = const [];

  // ── Dart solver fields ──
  final _dartMapper = DartSolverPayloadMapper();
  SolverResult? lastResult;
  List<SolverVariant> variants = const [];
  SolverProgress? currentProgress;

  // ── Native solver progress stream ──
  final _progressStream = SolverProgressStream();
  NativeSolverProgress? nativeProgress;
  StreamSubscription<NativeSolverProgress>? _nativeProgressSub;

  /// Primary solver: Pure-Dart engine (Isolate-based, with variants).
  Future<void> runDartSolver(
    PlannerState planner, {
    int variantCount = 3,
    int timeoutMs = 60000,
  }) async {
    isLoading = true;
    error = null;
    status = 'Initializing Dart solver...';
    failureHints = const [];
    assignments.clear();
    variants = const [];
    lastResult = null;
    notifyListeners();

    try {
      final payload = _dartMapper.fromPlanner(
        planner,
        timeoutMs: timeoutMs,
        variantCount: variantCount,
      );

      debugPrint('--- DART SOLVER: ${payload.lessons.length} lessons, '
          '${payload.rooms.length} rooms, ${payload.days}d × ${payload.periodsPerDay}p ---');

      final result = await SolverEngine.solve(payload, onProgress: (progress) {
        currentProgress = progress;
        status = '${progress.phase}: ${progress.message}';
        notifyListeners();
      });

      lastResult = result;
      variants = result.variants;
      status = result.status;

      if (result.isOk && result.best != null) {
        _mapDartAssignments(result.best!, planner);
        debugPrint(
            '--- DART SOLVER: ${result.status} in ${result.elapsedMs}ms, '
            'score: ${result.best!.totalScore.toStringAsFixed(1)}, '
            '${result.variants.length} variant(s) ---');
      } else {
        error = result.errorMessage ?? 'Solver failed: ${result.status}';
        final warnings = conflictService.preflight(planner);
        failureHints = [
          if (result.errorMessage != null) result.errorMessage!,
          if (warnings.isNotEmpty) ...warnings.take(3).map((w) => w.message),
        ];
      }
    } catch (e) {
      error = e.toString();
      debugPrint('--- DART SOLVER ERROR: $e ---');
    } finally {
      isLoading = false;
      currentProgress = null;
      notifyListeners();
    }
  }

  /// Select a specific variant by index and apply its assignments.
  void selectVariant(int index, PlannerState planner) {
    if (index < 0 || index >= variants.length) return;
    assignments.clear();
    _mapDartAssignments(variants[index], planner);
    notifyListeners();
  }

  void _mapDartAssignments(SolverVariant variant, PlannerState planner) {
    final lessonMap = <String, dynamic>{};
    for (final l in planner.lessons) {
      for (int k = 0; k < l.countPerWeek; k++) {
        lessonMap['${l.id}_$k'] = l;
      }
    }

    for (final a in variant.assignments) {
      final plannerLesson = lessonMap[a.lessonId];
      if (plannerLesson == null) continue;

      assignments.add(TimetableAssignment(
        lessonId: a.lessonId,
        day: a.day, // 0-indexed; persisted as-is by generation_progress_screen
        period: a.period,
        subjectId: plannerLesson.subjectId,
        classIds: List<String>.from(plannerLesson.classIds),
        teacherIds: List<String>.from(plannerLesson.teacherIds),
        roomId: a.roomId,
      ));
    }
  }

  /// Fallback: Kotlin native solver (legacy).
  Future<void> run(PlannerState planner) async {
    isLoading = true;
    error = null;
    status = 'Initializing native solver...';
    failureHints = const [];
    assignments.clear();
    nativeProgress = null;
    notifyListeners();

    // Subscribe to the EventChannel progress stream before invoking the solver.
    _nativeProgressSub?.cancel();
    _nativeProgressSub = _progressStream.listen(
      (progress) {
        nativeProgress = progress;
        status = progress.displayMessage;
        notifyListeners();
      },
      onDone: () {
        _nativeProgressSub = null;
      },
      onError: (_) {
        // Progress stream errors are non-fatal; solver result still arrives via MethodChannel.
        _nativeProgressSub = null;
      },
    );

    try {
      final payload = await mapper.fromCanonicalState(planner);

      final sw = Stopwatch()..start();
      final res = await client.solve(payload);
      sw.stop();
      debugPrint(
          '--- NATIVE SOLVER COMPLETED IN: ${sw.elapsedMilliseconds}ms ---');
      debugPrint('--- SOLVER STATUS: ${res.rawStatus} ---');

      status = res.rawStatus;
      if (!res.isOk) {
        final diagnostics = res.raw['diagnostics'] is Map
            ? Map<String, dynamic>.from(res.raw['diagnostics'] as Map)
            : const <String, dynamic>{};
        final reasonCounts = diagnostics['unscheduledReasonCounts'] is Map
            ? Map<String, dynamic>.from(
                diagnostics['unscheduledReasonCounts'] as Map)
            : const <String, dynamic>{};
        final topReason =
            reasonCounts.entries.isEmpty ? null : reasonCounts.entries.first;
        if (res.rawStatus == 'SEED_TIMEOUT' && topReason != null) {
          error =
              'Timeout: dominant bottleneck ${topReason.key} (${topReason.value})';
        } else {
          error = res.errorMessage ?? 'Solver error: ${res.rawStatus}';
        }
        if (res.rawStatus == 'SEED_NOT_FOUND' ||
            res.rawStatus == 'SEED_INFEASIBLE_INPUT' ||
            res.rawStatus == 'SEED_TIMEOUT') {
          final warnings = conflictService.preflight(planner);
          failureHints = [
            if (topReason != null)
              'Dominant bottleneck: ${topReason.key} (${topReason.value})',
            if (warnings.isEmpty)
              'No obvious preflight issue detected. Check pinned slots, teacher availability, and room/class capacity.'
            else
              ...warnings.take(3).map((w) => w.message),
          ];
        }
      } else {
        _mapAssignments(res.raw);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      _nativeProgressSub?.cancel();
      _nativeProgressSub = null;
      nativeProgress = null;
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _nativeProgressSub?.cancel();
    _progressStream.dispose();
    super.dispose();
  }

  Future<bool> canManualMove({
    required PlannerState planner,
    required String lessonId,
    required int targetDay,
    required int targetPeriod,
  }) async {
    final result = conflictService.validateManualMove(
      planner: planner,
      lessonId: lessonId,
      targetDay: targetDay,
      targetPeriod: targetPeriod,
      currentAssignments: assignments,
    );
    return result.isValid;
  }

  Future<void> applyManualMove({
    required PlannerState planner,
    required String lessonId,
    required int targetDay,
    required int targetPeriod,
  }) async {
    final result = conflictService.validateManualMove(
      planner: planner,
      lessonId: lessonId,
      targetDay: targetDay,
      targetPeriod: targetPeriod,
      currentAssignments: assignments,
    );

    if (!result.isValid) {
      lastMoveError = result.reason;
      notifyListeners();
      return;
    }

    final i = assignments.indexWhere((a) => a.lessonId == lessonId);
    if (i >= 0) {
      assignments[i] =
          assignments[i].copyWith(day: targetDay, period: targetPeriod);
    }

    await planner.pinLessonToSlot(
      lessonId: lessonId,
      day: targetDay,
      period: targetPeriod,
    );

    lastMoveError = null;
    notifyListeners();
  }

  void _mapAssignments(Map<String, dynamic> raw) {
    final rows = (raw['assignments'] as List?) ?? const [];
    for (final row in rows) {
      if (row is! Map) continue;
      assignments.add(
        TimetableAssignment(
          lessonId: row['lessonId']?.toString() ?? 'unknown',
          day: (row['day'] as num?)?.toInt() ?? 1,
          period: (row['period'] as num?)?.toInt() ?? 1,
          subjectId: row['subjectId']?.toString() ?? 'SUB',
          classIds:
              (row['classIds'] as List?)?.map((e) => e.toString()).toList() ??
                  [if (row['classId'] != null) row['classId'].toString()],
          teacherIds:
              (row['teacherIds'] as List?)?.map((e) => e.toString()).toList() ??
                  [if (row['teacherId'] != null) row['teacherId'].toString()],
          roomId: row['roomId']?.toString() ?? '',
        ),
      );
    }
  }
}
