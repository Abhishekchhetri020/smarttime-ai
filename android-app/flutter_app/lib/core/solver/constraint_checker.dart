// Constraint checker for the pure-Dart timetable solver.
//
// Evaluates both hard constraints (violations = infeasible) and
// soft constraints (violations = penalty score to minimize).

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

  // Pre-computed lookup tables for O(1) conflict detection
  late final Map<String, SolverLesson> _lessonById;

  ConstraintChecker(this.payload) {
    _lessonById = {for (final l in payload.lessons) l.id: l};
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HARD CONSTRAINT CHECKS
  // ═══════════════════════════════════════════════════════════════════

  /// Check if placing [lesson] at [slot] with [roomId] would violate
  /// any hard constraint given current [assignments].
  ConstraintCheckResult checkHard(
    SolverLesson lesson,
    SolverSlot slot,
    String roomId,
    List<SolverAssignment> assignments,
  ) {
    // 1. Bounds check
    if (slot.day < 0 || slot.day >= payload.days ||
        slot.period < 0 || slot.period >= payload.periodsPerDay) {
      return const ConstraintCheckResult(
        hardViolation: true,
        hardReason: 'Slot out of bounds',
      );
    }

    // 2. Double lesson must fit
    if (lesson.isDouble && slot.period + 1 >= payload.periodsPerDay) {
      return const ConstraintCheckResult(
        hardViolation: true,
        hardReason: 'Double lesson does not fit — no consecutive period available',
      );
    }

    // Collect all slots this lesson would occupy
    final occupiedSlots = <SolverSlot>[slot];
    if (lesson.isDouble) {
      occupiedSlots.add(SolverSlot(slot.day, slot.period + 1));
    }

    for (final occSlot in occupiedSlots) {
      // 3. Teacher conflict
      for (final existing in assignments) {
        if (existing.day != occSlot.day || existing.period != occSlot.period) continue;
        final existingLesson = _lessonById[existing.lessonId];
        if (existingLesson == null) continue;

        // Teacher clash
        for (final tid in lesson.teacherIds) {
          if (existingLesson.teacherIds.contains(tid)) {
            return ConstraintCheckResult(
              hardViolation: true,
              hardReason: 'Teacher $tid already teaching at $occSlot',
            );
          }
        }

        // 4. Class conflict
        for (final cid in lesson.classIds) {
          if (existingLesson.classIds.contains(cid)) {
            // Check division exception: different divisions of same class CAN overlap
            if (lesson.divisionId != null &&
                existingLesson.divisionId != null &&
                lesson.divisionId != existingLesson.divisionId &&
                lesson.classIds.length == 1 &&
                existingLesson.classIds.length == 1 &&
                lesson.classIds.first == existingLesson.classIds.first) {
              continue; // Division-based parallel scheduling allowed
            }
            return ConstraintCheckResult(
              hardViolation: true,
              hardReason: 'Class $cid already has a lesson at $occSlot',
            );
          }
        }

        // 5. Room conflict
        if (existing.roomId == roomId && roomId.isNotEmpty) {
          return ConstraintCheckResult(
            hardViolation: true,
            hardReason: 'Room $roomId already occupied at $occSlot',
          );
        }
      }

      // 6. Teacher unavailability (time-off)
      for (final tid in lesson.teacherIds) {
        final profile = payload.teacherProfiles[tid];
        if (profile != null && profile.unavailableSlots.contains(occSlot)) {
          return ConstraintCheckResult(
            hardViolation: true,
            hardReason: 'Teacher $tid unavailable at $occSlot',
          );
        }
      }
    }

    // 7. Teacher max periods per day (hard cap)
    for (final tid in lesson.teacherIds) {
      final profile = payload.teacherProfiles[tid];
      if (profile?.maxPeriodsPerDay != null) {
        final dayCount = assignments
            .where((a) => a.day == slot.day)
            .where((a) {
              final l = _lessonById[a.lessonId];
              return l != null && l.teacherIds.contains(tid);
            })
            .length;
        final addingPeriods = lesson.isDouble ? 2 : 1;
        if (dayCount + addingPeriods > profile!.maxPeriodsPerDay!) {
          return ConstraintCheckResult(
            hardViolation: true,
            hardReason: 'Teacher $tid exceeds max ${profile.maxPeriodsPerDay} periods on day ${slot.day}',
          );
        }
      }
    }

    // 8. Lab/room type requirement
    if (lesson.requiredRoomId != null && lesson.requiredRoomId!.isNotEmpty) {
      if (roomId != lesson.requiredRoomId) {
        return ConstraintCheckResult(
          hardViolation: true,
          hardReason: 'Lesson requires room ${lesson.requiredRoomId} but assigned $roomId',
        );
      }
    }

    // 9. Pinned constraint
    if (lesson.isPinned && lesson.pinnedSlot != null) {
      if (slot != lesson.pinnedSlot) {
        return ConstraintCheckResult(
          hardViolation: true,
          hardReason: 'Pinned lesson must be at ${lesson.pinnedSlot}',
        );
      }
    }

    return ConstraintCheckResult.ok;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SOFT CONSTRAINT SCORING (full solution evaluation)
  // ═══════════════════════════════════════════════════════════════════

  /// Score an entire solution. Lower score = better.
  SolverVariant scoreSolution(
    List<SolverAssignment> assignments,
    List<String> unscheduledIds,
    int variantIndex,
  ) {
    final breakdown = <String, double>{};
    double total = 0.0;
    int hardViolations = 0;

    // Count unscheduled as heavy penalty
    final unscheduledPenalty = unscheduledIds.length * 100.0;
    breakdown['unscheduled'] = unscheduledPenalty;
    total += unscheduledPenalty;

    // Teacher gaps
    final tGaps = _scoreTeacherGaps(assignments);
    breakdown['teacher_gaps'] = tGaps * payload.softWeights.teacherGaps;
    total += breakdown['teacher_gaps']!;

    // Class gaps
    final cGaps = _scoreClassGaps(assignments);
    breakdown['class_gaps'] = cGaps * payload.softWeights.classGaps;
    total += breakdown['class_gaps']!;

    // Subject distribution
    final sDist = _scoreSubjectDistribution(assignments);
    breakdown['subject_distribution'] = sDist * payload.softWeights.subjectDistribution;
    total += breakdown['subject_distribution']!;

    // Teacher room stability
    final rStab = _scoreTeacherRoomStability(assignments);
    breakdown['room_stability'] = rStab * payload.softWeights.teacherRoomStability;
    total += breakdown['room_stability']!;

    // Teacher consecutive periods
    final tCons = _scoreTeacherConsecutive(assignments);
    breakdown['teacher_consecutive'] = tCons * payload.softWeights.teacherConsecutive;
    total += breakdown['teacher_consecutive']!;

    // Teacher workload balance
    final wBal = _scoreWorkloadBalance(assignments);
    breakdown['workload_balance'] = wBal * payload.softWeights.workloadBalance;
    total += breakdown['workload_balance']!;

    // Orphan periods
    final orphan = _scoreOrphanPeriods(assignments);
    breakdown['orphan_periods'] = orphan * payload.softWeights.orphanPeriodPenalty;
    total += breakdown['orphan_periods']!;

    return SolverVariant(
      variantIndex: variantIndex,
      assignments: assignments,
      totalScore: total,
      hardViolations: hardViolations,
      scoreBreakdown: breakdown,
      unscheduledLessonIds: unscheduledIds,
    );
  }

  // ── Teacher gaps: count free periods between first and last lesson per day ──

  double _scoreTeacherGaps(List<SolverAssignment> assignments) {
    final teacherIds = <String>{};
    for (final l in payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    double totalPenalty = 0;
    for (final tid in teacherIds) {
      final profile = payload.teacherProfiles[tid];
      final maxAllowed = profile?.maxGapsPerDay ?? 2;

      for (int d = 0; d < payload.days; d++) {
        final periods = assignments
            .where((a) => a.day == d)
            .where((a) {
              final l = _lessonById[a.lessonId];
              return l != null && l.teacherIds.contains(tid);
            })
            .map((a) => a.period)
            .toList()
          ..sort();

        if (periods.length < 2) continue;
        final gaps = periods.last - periods.first - (periods.length - 1);
        if (gaps > maxAllowed) {
          totalPenalty += (gaps - maxAllowed).toDouble();
        }
      }
    }
    return totalPenalty;
  }

  // ── Class gaps ──

  double _scoreClassGaps(List<SolverAssignment> assignments) {
    final classIds = <String>{};
    for (final l in payload.lessons) {
      classIds.addAll(l.classIds);
    }

    double totalPenalty = 0;
    for (final cid in classIds) {
      for (int d = 0; d < payload.days; d++) {
        final periods = assignments
            .where((a) => a.day == d)
            .where((a) {
              final l = _lessonById[a.lessonId];
              return l != null && l.classIds.contains(cid);
            })
            .map((a) => a.period)
            .toList()
          ..sort();

        if (periods.length < 2) continue;
        final gaps = periods.last - periods.first - (periods.length - 1);
        if (gaps > 0) totalPenalty += gaps.toDouble();
      }
    }
    return totalPenalty;
  }

  // ── Subject distribution: penalize same subject on consecutive days ──

  double _scoreSubjectDistribution(List<SolverAssignment> assignments) {
    double penalty = 0;
    final classIds = <String>{};
    for (final l in payload.lessons) {
      classIds.addAll(l.classIds);
    }

    for (final cid in classIds) {
      // Group by subject → days
      final subjectDays = <String, List<int>>{};
      for (final a in assignments) {
        final l = _lessonById[a.lessonId];
        if (l == null || !l.classIds.contains(cid)) continue;
        subjectDays.putIfAbsent(l.subjectId, () => []).add(a.day);
      }

      for (final days in subjectDays.values) {
        days.sort();
        for (int i = 1; i < days.length; i++) {
          if (days[i] == days[i - 1]) {
            penalty += 1.0; // same subject twice on same day
          } else if (days[i] - days[i - 1] == 1) {
            penalty += 0.5; // consecutive days
          }
        }
      }
    }
    return penalty;
  }

  // ── Teacher room stability: count distinct rooms per teacher per day ──

  double _scoreTeacherRoomStability(List<SolverAssignment> assignments) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      for (int d = 0; d < payload.days; d++) {
        final rooms = assignments
            .where((a) => a.day == d)
            .where((a) {
              final l = _lessonById[a.lessonId];
              return l != null && l.teacherIds.contains(tid);
            })
            .map((a) => a.roomId)
            .toSet();

        if (rooms.length > 1) {
          penalty += (rooms.length - 1).toDouble();
        }
      }
    }
    return penalty;
  }

  // ── Teacher consecutive periods: penalize exceeding max consecutive ──

  double _scoreTeacherConsecutive(List<SolverAssignment> assignments) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      final profile = payload.teacherProfiles[tid];
      final maxConsec = profile?.maxConsecutivePeriods ?? 4;

      for (int d = 0; d < payload.days; d++) {
        final periods = assignments
            .where((a) => a.day == d)
            .where((a) {
              final l = _lessonById[a.lessonId];
              return l != null && l.teacherIds.contains(tid);
            })
            .map((a) => a.period)
            .toList()
          ..sort();

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

        if (maxRun > maxConsec) {
          penalty += (maxRun - maxConsec).toDouble();
        }
      }
    }
    return penalty;
  }

  // ── Teacher workload balance: penalize uneven distribution across days ──

  double _scoreWorkloadBalance(List<SolverAssignment> assignments) {
    double penalty = 0;
    final teacherIds = <String>{};
    for (final l in payload.lessons) {
      teacherIds.addAll(l.teacherIds);
    }

    for (final tid in teacherIds) {
      final dailyCounts = List<int>.filled(payload.days, 0);
      for (final a in assignments) {
        final l = _lessonById[a.lessonId];
        if (l != null && l.teacherIds.contains(tid)) {
          dailyCounts[a.day]++;
        }
      }

      final activeDays = dailyCounts.where((c) => c > 0).toList();
      if (activeDays.length < 2) continue;

      final mean = activeDays.reduce((a, b) => a + b) / activeDays.length;
      double variance = 0;
      for (final c in activeDays) {
        variance += (c - mean) * (c - mean);
      }
      variance /= activeDays.length;
      penalty += variance;
    }
    return penalty;
  }

  // ── Orphan periods: isolated single lesson surrounded by gaps ──

  double _scoreOrphanPeriods(List<SolverAssignment> assignments) {
    double penalty = 0;
    final classIds = <String>{};
    for (final l in payload.lessons) {
      classIds.addAll(l.classIds);
    }

    for (final cid in classIds) {
      for (int d = 0; d < payload.days; d++) {
        final periods = assignments
            .where((a) => a.day == d)
            .where((a) {
              final l = _lessonById[a.lessonId];
              return l != null && l.classIds.contains(cid);
            })
            .map((a) => a.period)
            .toSet();

        for (final p in periods) {
          final hasBefore = periods.contains(p - 1);
          final hasAfter = periods.contains(p + 1);
          if (!hasBefore && !hasAfter && periods.length > 1) {
            penalty += 1.0;
          }
        }
      }
    }
    return penalty;
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
    final available = <SolverSlot>[];
    for (int d = 0; d < payload.days; d++) {
      for (int p = 0; p < payload.periodsPerDay; p++) {
        final slot = SolverSlot(d, p);
        final result = checkHard(lesson, slot, roomId, assignments);
        if (!result.hardViolation) {
          available.add(slot);
        }
      }
    }
    return available;
  }
}
