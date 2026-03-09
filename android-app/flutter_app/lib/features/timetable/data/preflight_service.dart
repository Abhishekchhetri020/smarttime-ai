import '../../admin/planner_state.dart';

class PreflightIssue {
  final String code;
  final String message;
  final bool isHardError;

  const PreflightIssue({
    required this.code,
    required this.message,
    required this.isHardError,
  });
}

class PreflightReport {
  final List<PreflightIssue> issues;

  const PreflightReport(this.issues);

  bool get hasHardErrors => issues.any((e) => e.isHardError);
  bool get isReadyToSolve => !hasHardErrors;
}

class PreflightService {
  PreflightReport audit(PlannerState planner) {
    final issues = <PreflightIssue>[];
    final rooms = planner.classrooms.isEmpty ? 1 : planner.classrooms.length;
    final periodsPerWeek = planner.workingDays * planner.bellTimes.length;
    final totalRoomSlots = rooms * periodsPerWeek;
    final totalLessonsRequested =
        planner.lessons.fold<int>(0, (sum, l) => sum + l.countPerWeek);

    if (totalLessonsRequested > totalRoomSlots) {
      issues.add(
        PreflightIssue(
          code: 'TOTAL_SLOT_OVERFLOW',
          message:
              'Total lessons ($totalLessonsRequested) exceed total available room slots ($totalRoomSlots).',
          isHardError: true,
        ),
      );
    }

    final teacherLoad = <String, int>{};
    for (final lesson in planner.lessons) {
      for (final tid in lesson.teacherIds) {
        teacherLoad[tid] = (teacherLoad[tid] ?? 0) + lesson.countPerWeek;
      }
    }

    for (final teacher in planner.teachers) {
      final assigned = teacherLoad[teacher.id] ?? 0;
      if (assigned > periodsPerWeek) {
        issues.add(
          PreflightIssue(
            code: 'TEACHER_OVER_ALLOCATED',
            message:
                "Teacher '${teacher.fullName.isEmpty ? teacher.abbr : teacher.fullName}' is over-allocated by ${assigned - periodsPerWeek} periods.",
            isHardError: true,
          ),
        );
      }
    }

    for (final lesson in planner.lessons) {
      if (lesson.length != 'double') continue;
      if (planner.bellTimes.length < 2) {
        issues.add(
          PreflightIssue(
            code: 'DOUBLE_PERIOD_IMPOSSIBLE',
            message:
                'Lesson ${lesson.id} is marked double, but the timetable does not have enough periods per day.',
            isHardError: true,
          ),
        );
      }
      if (lesson.isPinned &&
          lesson.fixedPeriod != null &&
          lesson.fixedPeriod! >= planner.bellTimes.length) {
        issues.add(
          PreflightIssue(
            code: 'DOUBLE_PERIOD_PINNED_OVERFLOW',
            message:
                'Lesson ${lesson.id} is a double period pinned too late in the day (P${lesson.fixedPeriod}).',
            isHardError: true,
          ),
        );
      }
    }

    if (planner.lessons.isEmpty) {
      issues.add(
        const PreflightIssue(
          code: 'NO_LESSONS',
          message: 'No lessons found in the Lessons table/schedule state.',
          isHardError: true,
        ),
      );
    }

    return PreflightReport(issues);
  }
}
