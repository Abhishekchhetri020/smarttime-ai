// Extensible Constraint Engine — Plugin Architecture for SmartTime AI.
//
// Instead of hardcoding constraints inside nested if/else blocks, the
// engine iterates over a `List<EngineConstraint>` registered at startup.
// Adding a new constraint type (e.g., "class teacher must teach period 1")
// requires only implementing `EngineConstraint` — zero changes to IFS,
// RecursiveSwapSolver, or TabuSearchOptimizer.
//
// SolverState provides O(1) matrix lookups for conflict detection.

import 'solver_models.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SOLVER STATE — O(1) Matrix for Conflict Detection
// ═══════════════════════════════════════════════════════════════════════

/// Mutable snapshot of the current timetable during solving.
///
/// Maintains indexed data structures so that any constraint can ask
/// questions like "who is teaching at Day 2, Period 3?" in O(1).
class SolverState {
  final SolverPayload payload;

  /// [day][period] → set of lessonIds placed there
  late final List<List<Set<String>>> _grid;

  /// lessonId → SolverAssignment (current placement)
  final Map<String, SolverAssignment> _assignmentOf = {};

  /// [day][period] → set of teacherIds busy at that slot
  late final List<List<Set<String>>> _teacherGrid;

  /// [day][period] → set of classIds busy at that slot
  late final List<List<Set<String>>> _classGrid;

  /// [day][period] → set of roomIds occupied at that slot
  late final List<List<Set<String>>> _roomGrid;

  /// Pre-built lesson lookup
  late final Map<String, SolverLesson> lessonById;

  SolverState(this.payload) {
    lessonById = {for (final l in payload.lessons) l.id: l};
    _grid = List.generate(
      payload.days,
      (_) => List.generate(payload.periodsPerDay, (_) => <String>{}),
    );
    _teacherGrid = List.generate(
      payload.days,
      (_) => List.generate(payload.periodsPerDay, (_) => <String>{}),
    );
    _classGrid = List.generate(
      payload.days,
      (_) => List.generate(payload.periodsPerDay, (_) => <String>{}),
    );
    _roomGrid = List.generate(
      payload.days,
      (_) => List.generate(payload.periodsPerDay, (_) => <String>{}),
    );
  }

  // ── O(1) Queries ──────────────────────────────────────────────────

  Set<String> lessonsAt(int day, int period) => _grid[day][period];
  Set<String> teachersAt(int day, int period) => _teacherGrid[day][period];
  Set<String> classesAt(int day, int period) => _classGrid[day][period];
  Set<String> roomsAt(int day, int period) => _roomGrid[day][period];

  bool isTeacherBusy(String teacherId, int day, int period) =>
      _teacherGrid[day][period].contains(teacherId);

  bool isClassBusy(String classId, int day, int period) =>
      _classGrid[day][period].contains(classId);

  bool isRoomOccupied(String roomId, int day, int period) =>
      _roomGrid[day][period].contains(roomId);

  SolverAssignment? assignmentFor(String lessonId) => _assignmentOf[lessonId];

  List<SolverAssignment> get allAssignments => _assignmentOf.values.toList();

  int get assignmentCount => _assignmentOf.length;

  /// Get all lesson IDs for a teacher on a specific day, sorted by period.
  List<int> teacherPeriodsOnDay(String teacherId, int day) {
    final periods = <int>[];
    for (int p = 0; p < payload.periodsPerDay; p++) {
      if (_teacherGrid[day][p].contains(teacherId)) {
        periods.add(p);
      }
    }
    return periods;
  }

  /// Get all lesson IDs for a class on a specific day, sorted by period.
  List<int> classPeriodsOnDay(String classId, int day) {
    final periods = <int>[];
    for (int p = 0; p < payload.periodsPerDay; p++) {
      if (_classGrid[day][p].contains(classId)) {
        periods.add(p);
      }
    }
    return periods;
  }

  /// Count how many periods a teacher teaches on a given day.
  int teacherDayLoad(String teacherId, int day) {
    int count = 0;
    for (int p = 0; p < payload.periodsPerDay; p++) {
      if (_teacherGrid[day][p].contains(teacherId)) count++;
    }
    return count;
  }

  /// Count how many periods a class has on a given day.
  int classDayLoad(String classId, int day) {
    int count = 0;
    for (int p = 0; p < payload.periodsPerDay; p++) {
      if (_classGrid[day][p].contains(classId)) count++;
    }
    return count;
  }

  // ── Mutations ──────────────────────────────────────────────────────

  /// Place a lesson at a specific slot. Updates all index matrices.
  void place(SolverAssignment assignment) {
    final lesson = lessonById[assignment.lessonId];
    if (lesson == null) return;

    _assignmentOf[assignment.lessonId] = assignment;

    final slots = <SolverSlot>[SolverSlot(assignment.day, assignment.period)];
    if (lesson.isDouble && assignment.period + 1 < payload.periodsPerDay) {
      slots.add(SolverSlot(assignment.day, assignment.period + 1));
    }

    for (final s in slots) {
      _grid[s.day][s.period].add(assignment.lessonId);
      for (final tid in lesson.teacherIds) {
        _teacherGrid[s.day][s.period].add(tid);
      }
      for (final cid in lesson.classIds) {
        _classGrid[s.day][s.period].add(cid);
      }
      if (assignment.roomId.isNotEmpty) {
        _roomGrid[s.day][s.period].add(assignment.roomId);
      }
    }
  }

  /// Remove a lesson from its current slot. Updates all index matrices.
  void remove(String lessonId) {
    final assignment = _assignmentOf.remove(lessonId);
    if (assignment == null) return;

    final lesson = lessonById[lessonId];
    if (lesson == null) return;

    final slots = <SolverSlot>[SolverSlot(assignment.day, assignment.period)];
    if (lesson.isDouble && assignment.period + 1 < payload.periodsPerDay) {
      slots.add(SolverSlot(assignment.day, assignment.period + 1));
    }

    for (final s in slots) {
      _grid[s.day][s.period].remove(lessonId);
      for (final tid in lesson.teacherIds) {
        _teacherGrid[s.day][s.period].remove(tid);
      }
      for (final cid in lesson.classIds) {
        _classGrid[s.day][s.period].remove(cid);
      }
      if (assignment.roomId.isNotEmpty) {
        _roomGrid[s.day][s.period].remove(assignment.roomId);
      }
    }
  }

  /// Create a deep copy of this state (for backtracking).
  SolverState clone() {
    final copy = SolverState(payload);
    for (final entry in _assignmentOf.entries) {
      copy.place(entry.value);
    }
    return copy;
  }

  /// Rebuild state from a flat list of assignments.
  static SolverState fromAssignments(
      SolverPayload payload, List<SolverAssignment> assignments) {
    final state = SolverState(payload);
    for (final a in assignments) {
      state.place(a);
    }
    return state;
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  ABSTRACT CONSTRAINT — The Plugin Interface
// ═══════════════════════════════════════════════════════════════════════

/// Return value for hard constraint evaluation.
/// 0 = no violation. Any positive value = violation code.
/// This avoids object allocation in the hot path.
typedef HardResult = int;

/// Abstract base for all engine constraints. Implement this
/// interface to add new constraint types without touching the solver core.
abstract class EngineConstraint {
  /// Human-readable name for diagnostics / insight reports.
  String get name;

  /// Whether this is a hard constraint (infeasible if violated) or soft
  /// (contributes penalty score to minimize).
  bool get isHard;

  /// Evaluate placing [lesson] at [slot] with [roomId] against the
  /// current [state]. Returns 0 if OK, or a positive int violation code.
  ///
  /// Only called for hard constraints. Must be as fast as possible —
  /// avoid allocations, use O(1) lookups from [state].
  int checkHard(
    SolverState state,
    SolverLesson lesson,
    SolverSlot slot,
    String roomId,
  ) => 0;

  /// Score the entire solution for soft constraint penalty.
  /// Lower = better. Only called for soft constraints during scoring.
  double scoreSoft(SolverState state) => 0.0;
}

// ═══════════════════════════════════════════════════════════════════════
//  BUILT-IN HARD CONSTRAINTS
// ═══════════════════════════════════════════════════════════════════════

/// Slot must be within grid bounds.
class BoundsConstraint extends EngineConstraint {
  @override String get name => 'Bounds Check';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    if (slot.day < 0 || slot.day >= state.payload.days) return 1;
    if (slot.period < 0 || slot.period >= state.payload.periodsPerDay) return 1;
    if (lesson.isDouble && slot.period + 1 >= state.payload.periodsPerDay) return 2;
    return 0;
  }
}

/// No two lessons sharing a teacher can occupy the same slot.
class TeacherClashConstraint extends EngineConstraint {
  @override String get name => 'Teacher Clash';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    final periodsToCheck = [slot.period];
    if (lesson.isDouble) periodsToCheck.add(slot.period + 1);

    for (final p in periodsToCheck) {
      if (p >= state.payload.periodsPerDay) return 3;
      for (final tid in lesson.teacherIds) {
        if (state.isTeacherBusy(tid, slot.day, p)) return 3;
      }
    }
    return 0;
  }
}

/// No two lessons sharing a class can occupy the same slot
/// (unless they are different divisions of the same class).
class ClassClashConstraint extends EngineConstraint {
  @override String get name => 'Class Clash';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    final periodsToCheck = [slot.period];
    if (lesson.isDouble) periodsToCheck.add(slot.period + 1);

    for (final p in periodsToCheck) {
      if (p >= state.payload.periodsPerDay) return 4;
      for (final cid in lesson.classIds) {
        if (!state.isClassBusy(cid, slot.day, p)) continue;

        // Check division exception: different divisions of same class CAN overlap
        final conflictingLessonIds = state.lessonsAt(slot.day, p);
        for (final existingLid in conflictingLessonIds) {
          final existingLesson = state.lessonById[existingLid];
          if (existingLesson == null) continue;
          if (!existingLesson.classIds.contains(cid)) continue;

          // Division exception
          if (lesson.divisionId != null &&
              existingLesson.divisionId != null &&
              lesson.divisionId != existingLesson.divisionId &&
              lesson.classIds.length == 1 &&
              existingLesson.classIds.length == 1 &&
              lesson.classIds.first == existingLesson.classIds.first) {
            continue; // Parallel divisions allowed
          }
          return 4; // True class clash
        }
      }
    }
    return 0;
  }
}

/// No two lessons can use the same room at the same time.
class RoomClashConstraint extends EngineConstraint {
  @override String get name => 'Room Clash';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    if (roomId.isEmpty) return 0;
    final periodsToCheck = [slot.period];
    if (lesson.isDouble) periodsToCheck.add(slot.period + 1);

    for (final p in periodsToCheck) {
      if (p >= state.payload.periodsPerDay) return 5;
      if (state.isRoomOccupied(roomId, slot.day, p)) return 5;
    }
    return 0;
  }
}

/// Teacher must not be scheduled during their unavailable slots.
class TeacherUnavailabilityConstraint extends EngineConstraint {
  @override String get name => 'Teacher Unavailability';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    final periodsToCheck = [slot.period];
    if (lesson.isDouble) periodsToCheck.add(slot.period + 1);

    for (final p in periodsToCheck) {
      final checkSlot = SolverSlot(slot.day, p);
      for (final tid in lesson.teacherIds) {
        final profile = state.payload.teacherProfiles[tid];
        if (profile != null && profile.unavailableSlots.contains(checkSlot)) {
          return 6;
        }
      }
    }
    return 0;
  }
}

/// Teacher cannot exceed their max periods per day.
class TeacherMaxPeriodsPerDayConstraint extends EngineConstraint {
  @override String get name => 'Teacher Max Periods/Day';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    final addingPeriods = lesson.isDouble ? 2 : 1;
    for (final tid in lesson.teacherIds) {
      final profile = state.payload.teacherProfiles[tid];
      if (profile?.maxPeriodsPerDay != null) {
        final currentLoad = state.teacherDayLoad(tid, slot.day);
        if (currentLoad + addingPeriods > profile!.maxPeriodsPerDay!) return 7;
      }
    }
    return 0;
  }
}

/// Class cannot exceed their max periods per day.
class ClassMaxPeriodsPerDayConstraint extends EngineConstraint {
  @override String get name => 'Class Max Periods/Day';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    final addingPeriods = lesson.isDouble ? 2 : 1;
    for (final cid in lesson.classIds) {
      final profile = state.payload.classProfiles[cid];
      if (profile?.maxPeriodsPerDay != null) {
        final currentLoad = state.classDayLoad(cid, slot.day);
        if (currentLoad + addingPeriods > profile!.maxPeriodsPerDay!) return 8;
      }
    }
    return 0;
  }
}

/// Lesson with a required room must be placed in that room.
class RequiredRoomConstraint extends EngineConstraint {
  @override String get name => 'Required Room';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    if (lesson.requiredRoomId != null && lesson.requiredRoomId!.isNotEmpty) {
      if (roomId != lesson.requiredRoomId) return 9;
    }
    return 0;
  }
}

/// Pinned lessons must go to their designated slot.
class PinnedConstraint extends EngineConstraint {
  @override String get name => 'Pinned Lesson';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    if (lesson.isPinned && lesson.pinnedSlot != null) {
      if (slot != lesson.pinnedSlot) return 10;
    }
    return 0;
  }
}

/// Teacher cannot exceed their max consecutive teaching periods.
/// This is enforced as a hard constraint when maxConsecutivePeriods is set.
class TeacherMaxConsecutiveConstraint extends EngineConstraint {
  @override String get name => 'Teacher Max Consecutive';
  @override bool get isHard => true;

  @override
  int checkHard(SolverState state, SolverLesson lesson, SolverSlot slot, String roomId) {
    for (final tid in lesson.teacherIds) {
      final profile = state.payload.teacherProfiles[tid];
      if (profile?.maxConsecutivePeriods == null) continue;
      final maxConsec = profile!.maxConsecutivePeriods!;

      // Get current periods + the proposed slot
      final periods = state.teacherPeriodsOnDay(tid, slot.day);
      final allPeriods = <int>{...periods, slot.period};
      if (lesson.isDouble) allPeriods.add(slot.period + 1);
      final sorted = allPeriods.toList()..sort();

      // Check for consecutive run exceeding max
      int consecutive = 1;
      for (int i = 1; i < sorted.length; i++) {
        if (sorted[i] == sorted[i - 1] + 1) {
          consecutive++;
          if (consecutive > maxConsec) return 11;
        } else {
          consecutive = 1;
        }
      }
    }
    return 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  BUILT-IN SOFT CONSTRAINTS
// ═══════════════════════════════════════════════════════════════════════

/// Penalize idle gaps between teacher's first and last lesson each day.
class TeacherGapsSoftConstraint extends EngineConstraint {
  @override String get name => 'Teacher Gaps';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in state.payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      final profile = state.payload.teacherProfiles[tid];
      final maxAllowed = profile?.maxGapsPerDay ?? 2;

      for (int d = 0; d < state.payload.days; d++) {
        final periods = state.teacherPeriodsOnDay(tid, d);
        if (periods.length < 2) continue;
        final gaps = periods.last - periods.first - (periods.length - 1);
        if (gaps > maxAllowed) {
          penalty += (gaps - maxAllowed).toDouble();
        }
      }
    }
    return penalty;
  }
}

/// Penalize idle gaps in class schedules.
class ClassGapsSoftConstraint extends EngineConstraint {
  @override String get name => 'Class Gaps';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final classIds = <String>{};
    for (final l in state.payload.lessons) {
      classIds.addAll(l.classIds);
    }

    for (final cid in classIds) {
      for (int d = 0; d < state.payload.days; d++) {
        final periods = state.classPeriodsOnDay(cid, d);
        if (periods.length < 2) continue;
        final gaps = periods.last - periods.first - (periods.length - 1);
        if (gaps > 0) penalty += gaps.toDouble();
      }
    }
    return penalty;
  }
}

/// Penalize same subject on same day or consecutive days for a class.
class SubjectDistributionSoftConstraint extends EngineConstraint {
  @override String get name => 'Subject Distribution';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final classIds = <String>{};
    for (final l in state.payload.lessons) {
      classIds.addAll(l.classIds);
    }

    for (final cid in classIds) {
      final subjectDays = <String, List<int>>{};
      for (final a in state.allAssignments) {
        final l = state.lessonById[a.lessonId];
        if (l == null || !l.classIds.contains(cid)) continue;
        subjectDays.putIfAbsent(l.subjectId, () => []).add(a.day);
      }

      for (final days in subjectDays.values) {
        days.sort();
        for (int i = 1; i < days.length; i++) {
          if (days[i] == days[i - 1]) {
            penalty += 1.0; // Same subject twice on same day
          } else if (days[i] - days[i - 1] == 1) {
            penalty += 0.5; // Consecutive days
          }
        }
      }
    }
    return penalty;
  }
}

/// Penalize teachers moving between many rooms on the same day.
class TeacherRoomStabilitySoftConstraint extends EngineConstraint {
  @override String get name => 'Room Stability';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in state.payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      for (int d = 0; d < state.payload.days; d++) {
        final rooms = <String>{};
        for (final a in state.allAssignments) {
          if (a.day != d) continue;
          final l = state.lessonById[a.lessonId];
          if (l != null && l.teacherIds.contains(tid)) {
            rooms.add(a.roomId);
          }
        }
        if (rooms.length > 1) penalty += (rooms.length - 1).toDouble();
      }
    }
    return penalty;
  }
}

/// Penalize teachers exceeding max consecutive teaching periods.
class TeacherConsecutiveSoftConstraint extends EngineConstraint {
  @override String get name => 'Teacher Consecutive';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in state.payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      final profile = state.payload.teacherProfiles[tid];
      final maxConsec = profile?.maxConsecutivePeriods ?? 4;

      for (int d = 0; d < state.payload.days; d++) {
        final periods = state.teacherPeriodsOnDay(tid, d);
        if (periods.length <= 1) continue;

        int consecutive = 1;
        int maxRun = 1;
        for (int i = 1; i < periods.length; i++) {
          if (periods[i] == periods[i - 1] + 1) {
            consecutive++;
            if (consecutive > maxRun) maxRun = consecutive;
          } else {
            consecutive = 1;
          }
        }
        if (maxRun > maxConsec) penalty += (maxRun - maxConsec).toDouble();
      }
    }
    return penalty;
  }
}

/// Penalize uneven distribution of teacher workload across days.
class WorkloadBalanceSoftConstraint extends EngineConstraint {
  @override String get name => 'Workload Balance';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in state.payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      final dailyCounts = List<int>.filled(state.payload.days, 0);
      for (int d = 0; d < state.payload.days; d++) {
        dailyCounts[d] = state.teacherDayLoad(tid, d);
      }

      final activeDays = dailyCounts.where((c) => c > 0).toList();
      if (activeDays.length < 2) continue;

      final mean = activeDays.reduce((a, b) => a + b) / activeDays.length;
      double variance = 0;
      for (final c in activeDays) {
        variance += (c - mean) * (c - mean);
      }
      penalty += variance / activeDays.length;
    }
    return penalty;
  }
}

/// Penalize subjects with morning preference being placed in late periods.
class MorningPreferenceSoftConstraint extends EngineConstraint {
  @override String get name => 'Morning Preference';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    for (final a in state.allAssignments) {
      final l = state.lessonById[a.lessonId];
      if (l == null) continue;
      final profile = state.payload.subjectProfiles[l.subjectId];
      if (profile != null && profile.preferMorning && a.period >= 3) {
        penalty += (a.period - 2).toDouble();
      }
    }
    return penalty;
  }
}

/// Penalize orphan periods (single isolated lessons with gaps on both sides).
class OrphanPeriodSoftConstraint extends EngineConstraint {
  @override String get name => 'Orphan Periods';
  @override bool get isHard => false;

  @override
  double scoreSoft(SolverState state) {
    double penalty = 0;
    final classIds = <String>{};
    for (final l in state.payload.lessons) {
      classIds.addAll(l.classIds);
    }

    for (final cid in classIds) {
      for (int d = 0; d < state.payload.days; d++) {
        final periods = state.classPeriodsOnDay(cid, d).toSet();
        if (periods.length <= 1) continue;

        for (final p in periods) {
          final hasBefore = periods.contains(p - 1);
          final hasAfter = periods.contains(p + 1);
          if (!hasBefore && !hasAfter) penalty += 1.0;
        }
      }
    }
    return penalty;
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  DEFAULT CONSTRAINT REGISTRY
// ═══════════════════════════════════════════════════════════════════════

/// Returns the default list of all built-in constraints.
/// Users can add custom constraints to this list before passing to the solver.
List<EngineConstraint> defaultConstraints() => [
  // Hard constraints
  BoundsConstraint(),
  TeacherClashConstraint(),
  ClassClashConstraint(),
  RoomClashConstraint(),
  TeacherUnavailabilityConstraint(),
  TeacherMaxPeriodsPerDayConstraint(),
  ClassMaxPeriodsPerDayConstraint(),
  RequiredRoomConstraint(),
  PinnedConstraint(),
  TeacherMaxConsecutiveConstraint(),
  // Soft constraints
  TeacherGapsSoftConstraint(),
  ClassGapsSoftConstraint(),
  SubjectDistributionSoftConstraint(),
  TeacherRoomStabilitySoftConstraint(),
  TeacherConsecutiveSoftConstraint(),
  WorkloadBalanceSoftConstraint(),
  MorningPreferenceSoftConstraint(),
  OrphanPeriodSoftConstraint(),
];
