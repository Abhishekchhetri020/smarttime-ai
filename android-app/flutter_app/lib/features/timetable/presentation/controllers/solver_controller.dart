import 'package:flutter/foundation.dart';

import '../../../admin/planner_state.dart';
import '../../data/conflict_service.dart';
import '../../data/native_solver_client.dart';
import '../../data/solver_payload_mapper.dart';

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

  Future<void> run(PlannerState planner) async {
    isLoading = true;
    error = null;
    status = null;
    failureHints = const [];
    assignments.clear();
    notifyListeners();

    try {
      final payload = await mapper.fromCanonicalState(planner);
      final res = await client.solve(payload);
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
      isLoading = false;
      notifyListeners();
    }
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
