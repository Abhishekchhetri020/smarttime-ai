// Backtracking solver — Phase 2 of the solver pipeline.
//
// Takes the greedy seed result and attempts to schedule any remaining
// unscheduled lessons using backtracking search with:
// - Arc Consistency (AC-3) domain pruning
// - Minimum Remaining Values (MRV) variable ordering
// - Forward checking to detect dead-ends early

import 'constraint_checker.dart';
import 'solver_models.dart';

class BacktrackSolver {
  final SolverPayload payload;
  final ConstraintChecker checker;
  final void Function(SolverProgress)? onProgress;
  final Stopwatch _stopwatch = Stopwatch();

  int _nodesExplored = 0;
  static const int _maxNodes = 500000; // prevent infinite search

  BacktrackSolver({
    required this.payload,
    required this.checker,
    this.onProgress,
  });

  /// Attempt to place all [unscheduledIds] into [currentAssignments].
  /// Returns improved assignments list + remaining unscheduled.
  BacktrackResult run(
    List<SolverAssignment> currentAssignments,
    List<String> unscheduledIds,
  ) {
    if (unscheduledIds.isEmpty) {
      return BacktrackResult(
        assignments: currentAssignments,
        unscheduledIds: const [],
      );
    }

    _stopwatch
      ..reset()
      ..start();
    _nodesExplored = 0;

    // Build domains: for each unscheduled lesson, compute valid (slot, room) pairs
    final domains = <String, List<_DomainEntry>>{};
    final lessonById = {for (final l in payload.lessons) l.id: l};

    // Room usage tracker from existing assignments
    final roomUsage = <SolverSlot, Set<String>>{};
    for (final a in currentAssignments) {
      roomUsage.putIfAbsent(SolverSlot(a.day, a.period), () => <String>{}).add(a.roomId);
      final lesson = lessonById[a.lessonId];
      if (lesson != null && lesson.isDouble) {
        roomUsage.putIfAbsent(SolverSlot(a.day, a.period + 1), () => <String>{}).add(a.roomId);
      }
    }

    for (final lid in unscheduledIds) {
      final lesson = lessonById[lid];
      if (lesson == null) continue;

      final entries = <_DomainEntry>[];
      for (int d = 0; d < payload.days; d++) {
        for (int p = 0; p < payload.periodsPerDay; p++) {
          final slot = SolverSlot(d, p);
          final roomId = _findRoom(lesson, slot, roomUsage, currentAssignments);
          final check = checker.checkHard(lesson, slot, roomId, currentAssignments);
          if (!check.hardViolation) {
            entries.add(_DomainEntry(slot, roomId));
          }
        }
      }
      domains[lid] = entries;
    }

    // AC-3 pruning
    _ac3(domains, lessonById, currentAssignments);

    // MRV ordering: sort unscheduled by domain size (smallest first)
    final ordered = [...unscheduledIds];
    ordered.sort((a, b) {
      final domA = domains[a]?.length ?? 0;
      final domB = domains[b]?.length ?? 0;
      return domA.compareTo(domB);
    });

    // Backtrack
    final result = List<SolverAssignment>.from(currentAssignments);
    final remaining = <String>[];

    final success = _backtrack(ordered, 0, result, domains, lessonById);

    if (!success) {
      // Collect any lessons we couldn't place
      final placedIds = result.map((a) => a.lessonId).toSet();
      for (final lid in unscheduledIds) {
        if (!placedIds.contains(lid)) remaining.add(lid);
      }
    }

    _stopwatch.stop();

    onProgress?.call(SolverProgress(
      phase: 'backtrack',
      percent: 1.0,
      message: 'Backtracking complete. Explored $_nodesExplored nodes in ${_stopwatch.elapsedMilliseconds}ms',
    ));

    return BacktrackResult(
      assignments: result,
      unscheduledIds: remaining,
    );
  }

  bool _backtrack(
    List<String> lessonIds,
    int index,
    List<SolverAssignment> assignments,
    Map<String, List<_DomainEntry>> domains,
    Map<String, SolverLesson> lessonById,
  ) {
    if (index >= lessonIds.length) return true;

    // Timeout check
    if (_stopwatch.elapsedMilliseconds > payload.timeoutMs * 0.6) return false;
    if (_nodesExplored > _maxNodes) return false;

    final lid = lessonIds[index];
    final lesson = lessonById[lid];
    if (lesson == null) return _backtrack(lessonIds, index + 1, assignments, domains, lessonById);

    final domain = domains[lid];
    if (domain == null || domain.isEmpty) return false;

    _nodesExplored++;

    if (_nodesExplored % 1000 == 0) {
      onProgress?.call(SolverProgress(
        phase: 'backtrack',
        percent: index / lessonIds.length,
        message: 'Exploring node $_nodesExplored...',
      ));
    }

    for (final entry in domain) {
      final check = checker.checkHard(lesson, entry.slot, entry.roomId, assignments);
      if (check.hardViolation) continue;

      // Place the lesson
      final assignment = SolverAssignment(
        lessonId: lid,
        day: entry.slot.day,
        period: entry.slot.period,
        roomId: entry.roomId,
      );
      assignments.add(assignment);

      // Forward check: verify remaining lessons still have non-empty domains
      if (_forwardCheck(lessonIds, index + 1, assignments, domains, lessonById)) {
        if (_backtrack(lessonIds, index + 1, assignments, domains, lessonById)) {
          return true;
        }
      }

      // Undo
      assignments.removeLast();
    }

    return false;
  }

  /// Forward checking: verify that all future variables still have at least
  /// one valid value in their domain.
  bool _forwardCheck(
    List<String> lessonIds,
    int fromIndex,
    List<SolverAssignment> assignments,
    Map<String, List<_DomainEntry>> domains,
    Map<String, SolverLesson> lessonById,
  ) {
    for (int i = fromIndex; i < lessonIds.length; i++) {
      final lid = lessonIds[i];
      final lesson = lessonById[lid];
      if (lesson == null) continue;

      final domain = domains[lid];
      if (domain == null) return false;

      bool hasValid = false;
      for (final entry in domain) {
        final check = checker.checkHard(lesson, entry.slot, entry.roomId, assignments);
        if (!check.hardViolation) {
          hasValid = true;
          break;
        }
      }
      if (!hasValid) return false;
    }
    return true;
  }

  /// AC-3 arc consistency algorithm to prune domains.
  void _ac3(
    Map<String, List<_DomainEntry>> domains,
    Map<String, SolverLesson> lessonById,
    List<SolverAssignment> currentAssignments,
  ) {
    // Build constraint arcs: pairs of lessons that share teachers or classes
    final arcs = <_Arc>[];
    final lessonIds = domains.keys.toList();

    for (int i = 0; i < lessonIds.length; i++) {
      for (int j = i + 1; j < lessonIds.length; j++) {
        final li = lessonById[lessonIds[i]];
        final lj = lessonById[lessonIds[j]];
        if (li == null || lj == null) continue;

        final shareTeacher = li.teacherIds.any(lj.teacherIds.contains);
        final shareClass = li.classIds.any(lj.classIds.contains);

        if (shareTeacher || shareClass) {
          arcs.add(_Arc(lessonIds[i], lessonIds[j]));
          arcs.add(_Arc(lessonIds[j], lessonIds[i]));
        }
      }
    }

    final queue = List<_Arc>.from(arcs);

    while (queue.isNotEmpty) {
      final arc = queue.removeAt(0);
      if (_revise(domains, arc, lessonById)) {
        if (domains[arc.from]?.isEmpty ?? true) return; // Domain wiped out
        // Add neighbors back to queue
        for (final a in arcs) {
          if (a.to == arc.from && a.from != arc.to) {
            queue.add(a);
          }
        }
      }
    }
  }

  bool _revise(
    Map<String, List<_DomainEntry>> domains,
    _Arc arc,
    Map<String, SolverLesson> lessonById,
  ) {
    final fromLesson = lessonById[arc.from];
    final toLesson = lessonById[arc.to];
    if (fromLesson == null || toLesson == null) return false;

    final shareTeacher = fromLesson.teacherIds.any(toLesson.teacherIds.contains);
    final shareClass = fromLesson.classIds.any(toLesson.classIds.contains);

    bool revised = false;

    domains[arc.from]?.removeWhere((entry) {
      // For each value in from's domain, check if there exists
      // at least one consistent value in to's domain
      final toDomain = domains[arc.to];
      if (toDomain == null) return false;

      final hasConsistent = toDomain.any((toEntry) {
        if (entry.slot == toEntry.slot) {
          // Same slot → conflict if they share teacher or class
          if (shareTeacher || shareClass) return false;
        }
        return true;
      });

      if (!hasConsistent) {
        revised = true;
        return true;
      }
      return false;
    });

    return revised;
  }

  String _findRoom(
    SolverLesson lesson,
    SolverSlot slot,
    Map<SolverSlot, Set<String>> roomUsage,
    List<SolverAssignment> assignments,
  ) {
    if (lesson.requiredRoomId != null && lesson.requiredRoomId!.isNotEmpty) {
      return lesson.requiredRoomId!;
    }

    if (payload.rooms.isEmpty) return '';

    final allUsed = <String>{};
    allUsed.addAll(roomUsage[slot] ?? {});
    // Also check assignments directly for this slot
    for (final a in assignments) {
      if (a.day == slot.day && a.period == slot.period) {
        allUsed.add(a.roomId);
      }
    }

    if (lesson.isDouble) {
      final nextSlot = SolverSlot(slot.day, slot.period + 1);
      allUsed.addAll(roomUsage[nextSlot] ?? {});
      for (final a in assignments) {
        if (a.day == nextSlot.day && a.period == nextSlot.period) {
          allUsed.add(a.roomId);
        }
      }
    }

    for (final room in payload.rooms) {
      if (!allUsed.contains(room.id)) return room.id;
    }

    return '';
  }
}

class BacktrackResult {
  final List<SolverAssignment> assignments;
  final List<String> unscheduledIds;

  const BacktrackResult({
    required this.assignments,
    required this.unscheduledIds,
  });
}

class _DomainEntry {
  final SolverSlot slot;
  final String roomId;

  const _DomainEntry(this.slot, this.roomId);
}

class _Arc {
  final String from;
  final String to;

  const _Arc(this.from, this.to);
}
