// Core data models for the pure-Dart timetable solver.
//
// These are solver-internal representations, decoupled from Drift entities
// and PlannerState UI models. The SolverPayloadMapper converts between
// them.

/// A single schedulable time slot: one (day, period) coordinate.
class SolverSlot {
  final int day;    // 0-indexed
  final int period; // 0-indexed

  const SolverSlot(this.day, this.period);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolverSlot && day == other.day && period == other.period;

  @override
  int get hashCode => day * 97 + period;

  @override
  String toString() => 'D$day:P$period';
}

/// A lesson that the solver must place on the grid.
class SolverLesson {
  final String id;
  final String subjectId;
  final List<String> teacherIds;
  final List<String> classIds;
  final String? divisionId;
  final String? requiredRoomId;
  final bool isDouble;        // requires 2 consecutive periods
  final bool isPinned;
  final SolverSlot? pinnedSlot;

  /// Relationship constraints
  final int relationshipType; // 0=none, 1=consecutive, 2=same-day
  final String? relationshipGroupKey;

  const SolverLesson({
    required this.id,
    required this.subjectId,
    required this.teacherIds,
    required this.classIds,
    this.divisionId,
    this.requiredRoomId,
    this.isDouble = false,
    this.isPinned = false,
    this.pinnedSlot,
    this.relationshipType = 0,
    this.relationshipGroupKey,
  });
}

/// A room available for scheduling.
class SolverRoom {
  final String id;
  final String roomType; // 'standard', 'lab', 'computer', etc.
  final int capacity;

  const SolverRoom({
    required this.id,
    this.roomType = 'standard',
    this.capacity = 40,
  });
}

/// Teacher-level constraint profile.
class SolverTeacherProfile {
  final String id;
  final Set<SolverSlot> unavailableSlots;
  final Set<SolverSlot> conditionalSlots; // prefer not, but possible
  final int? maxPeriodsPerDay;
  final int? maxGapsPerDay;
  final int? maxConsecutivePeriods;
  final Set<int>? preferredDaysOff; // 0-indexed day numbers

  const SolverTeacherProfile({
    required this.id,
    this.unavailableSlots = const {},
    this.conditionalSlots = const {},
    this.maxPeriodsPerDay,
    this.maxGapsPerDay,
    this.maxConsecutivePeriods,
    this.preferredDaysOff,
  });
}

/// Class-level constraint profile.
class SolverClassProfile {
  final String id;
  final int? maxPeriodsPerDay;
  final int? maxGapsPerDay;

  const SolverClassProfile({
    required this.id,
    this.maxPeriodsPerDay,
    this.maxGapsPerDay,
  });
}

/// Subject-level preferences.
class SolverSubjectProfile {
  final String id;
  final bool preferMorning;     // prefer first 3 periods
  final bool avoidLastPeriod;
  final int? minGapBetweenSameSubject; // minimum periods gap for same class

  const SolverSubjectProfile({
    required this.id,
    this.preferMorning = false,
    this.avoidLastPeriod = false,
    this.minGapBetweenSameSubject,
  });
}

/// One placed lesson assignment in the solution.
class SolverAssignment {
  final String lessonId;
  final int day;
  final int period;
  final String roomId;

  const SolverAssignment({
    required this.lessonId,
    required this.day,
    required this.period,
    required this.roomId,
  });

  SolverSlot get slot => SolverSlot(day, period);

  SolverAssignment copyWith({int? day, int? period, String? roomId}) {
    return SolverAssignment(
      lessonId: lessonId,
      day: day ?? this.day,
      period: period ?? this.period,
      roomId: roomId ?? this.roomId,
    );
  }

  @override
  String toString() => '$lessonId@D$day:P$period($roomId)';
}

/// Soft constraint weights configuration.
class SoftWeights {
  final double teacherGaps;
  final double classGaps;
  final double subjectDistribution;
  final double teacherRoomStability;
  final double teacherConsecutive;
  final double morningPreference;
  final double lastPeriodAvoidance;
  final double workloadBalance;
  final double orphanPeriodPenalty;

  const SoftWeights({
    this.teacherGaps = 5.0,
    this.classGaps = 5.0,
    this.subjectDistribution = 3.0,
    this.teacherRoomStability = 1.0,
    this.teacherConsecutive = 4.0,
    this.morningPreference = 1.0,
    this.lastPeriodAvoidance = 1.5,
    this.workloadBalance = 2.0,
    this.orphanPeriodPenalty = 2.0,
  });
}

/// Complete solver input payload.
class SolverPayload {
  final int days;
  final int periodsPerDay;
  final int timeoutMs;
  final List<SolverLesson> lessons;
  final List<SolverRoom> rooms;
  final Map<String, SolverTeacherProfile> teacherProfiles;
  final Map<String, SolverClassProfile> classProfiles;
  final Map<String, SolverSubjectProfile> subjectProfiles;
  final SoftWeights softWeights;
  final int variantCount; // how many variants to generate

  const SolverPayload({
    required this.days,
    required this.periodsPerDay,
    this.timeoutMs = 60000,
    required this.lessons,
    required this.rooms,
    this.teacherProfiles = const {},
    this.classProfiles = const {},
    this.subjectProfiles = const {},
    this.softWeights = const SoftWeights(),
    this.variantCount = 3,
  });
}

/// A complete timetable solution variant.
class SolverVariant {
  final int variantIndex;
  final List<SolverAssignment> assignments;
  final double totalScore;         // lower is better
  final int hardViolations;
  final Map<String, double> scoreBreakdown; // per-constraint scores
  final List<String> unscheduledLessonIds;

  const SolverVariant({
    required this.variantIndex,
    required this.assignments,
    required this.totalScore,
    this.hardViolations = 0,
    this.scoreBreakdown = const {},
    this.unscheduledLessonIds = const [],
  });

  bool get isComplete => unscheduledLessonIds.isEmpty;
  bool get isFeasible => hardViolations == 0;
}

/// Progress callback data sent from Isolate to main thread.
class SolverProgress {
  final String phase;    // 'greedy', 'backtrack', 'optimize'
  final double percent;  // 0.0 .. 1.0
  final String message;
  final int? currentVariant;

  const SolverProgress({
    required this.phase,
    required this.percent,
    this.message = '',
    this.currentVariant,
  });
}

/// Final solver result.
class SolverResult {
  final List<SolverVariant> variants;
  final int elapsedMs;
  final String status; // 'SUCCESS', 'PARTIAL', 'TIMEOUT', 'INFEASIBLE'
  final String? errorMessage;

  const SolverResult({
    required this.variants,
    required this.elapsedMs,
    required this.status,
    this.errorMessage,
  });

  SolverVariant? get best {
    if (variants.isEmpty) return null;
    final feasible = variants.where((v) => v.isFeasible).toList();
    if (feasible.isEmpty) return variants.first;
    feasible.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    return feasible.first;
  }

  bool get isOk => status == 'SUCCESS' || status == 'PARTIAL';
}
