class OfflineSolverTotals {
  final int lessonsRequested;
  final int assignedEntries;
  final int hardViolations;

  const OfflineSolverTotals({
    required this.lessonsRequested,
    required this.assignedEntries,
    required this.hardViolations,
  });

  factory OfflineSolverTotals.fromJson(Map<String, dynamic>? json) {
    return OfflineSolverTotals(
      lessonsRequested: (json?['lessonsRequested'] as num?)?.toInt() ?? 0,
      assignedEntries: (json?['assignedEntries'] as num?)?.toInt() ?? 0,
      hardViolations: (json?['hardViolations'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfflineSolverSearchStats {
  final int nodesVisited;
  final int backtracks;
  final int branchesPrunedByForwardCheck;

  const OfflineSolverSearchStats({
    required this.nodesVisited,
    required this.backtracks,
    required this.branchesPrunedByForwardCheck,
  });

  factory OfflineSolverSearchStats.fromJson(Map<String, dynamic>? json) {
    return OfflineSolverSearchStats(
      nodesVisited: (json?['nodesVisited'] as num?)?.toInt() ?? 0,
      backtracks: (json?['backtracks'] as num?)?.toInt() ?? 0,
      branchesPrunedByForwardCheck:
          (json?['branchesPrunedByForwardCheck'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfflineSolverDiagnostics {
  final String solverVersion;
  final Map<String, int> unscheduledReasonCounts;
  final OfflineSolverTotals totals;
  final OfflineSolverSearchStats search;

  const OfflineSolverDiagnostics({
    required this.solverVersion,
    required this.unscheduledReasonCounts,
    required this.totals,
    required this.search,
  });

  factory OfflineSolverDiagnostics.fromJson(Map<String, dynamic>? json) {
    final countsRaw =
        (json?['unscheduledReasonCounts'] as Map?)?.cast<dynamic, dynamic>() ??
            const {};
    final counts = <String, int>{
      for (final entry in countsRaw.entries)
        entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    };

    return OfflineSolverDiagnostics(
      solverVersion: (json?['solverVersion'] ?? '').toString(),
      unscheduledReasonCounts: counts,
      totals: OfflineSolverTotals.fromJson(
          (json?['totals'] as Map?)?.cast<String, dynamic>()),
      search: OfflineSolverSearchStats.fromJson(
          (json?['search'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

class OfflineHardViolation {
  final String lessonId;
  final String classId;
  final String teacherId;
  final String subjectId;
  final String reason;
  final int attemptedSlots;

  const OfflineHardViolation({
    required this.lessonId,
    required this.classId,
    required this.teacherId,
    required this.subjectId,
    required this.reason,
    required this.attemptedSlots,
  });

  factory OfflineHardViolation.fromJson(Map<String, dynamic> json) {
    return OfflineHardViolation(
      lessonId: (json['lessonId'] ?? '').toString(),
      classId: (json['classId'] ?? '').toString(),
      teacherId: (json['teacherId'] ?? '').toString(),
      subjectId: (json['subjectId'] ?? '').toString(),
      reason: (json['reason'] ?? 'unknown').toString(),
      attemptedSlots: (json['attemptedSlots'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfflineSolverResult {
  final String status;
  final OfflineSolverDiagnostics diagnostics;
  final List<OfflineHardViolation> hardViolations;

  const OfflineSolverResult({
    required this.status,
    required this.diagnostics,
    required this.hardViolations,
  });

  factory OfflineSolverResult.fromJson(Map<String, dynamic> json) {
    final violations = ((json['hardViolations'] as List?) ?? const [])
        .whereType<Map>()
        .map((v) => OfflineHardViolation.fromJson(v.cast<String, dynamic>()))
        .toList();

    return OfflineSolverResult(
      status: (json['status'] ?? '').toString(),
      diagnostics: OfflineSolverDiagnostics.fromJson(
          (json['diagnostics'] as Map?)?.cast<String, dynamic>()),
      hardViolations: violations,
    );
  }
}
