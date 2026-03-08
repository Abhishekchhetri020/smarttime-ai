import '../../admin/planner_state.dart';
import '../../admin/time_off_picker.dart';
import '../presentation/controllers/solver_controller.dart';

enum WarningSeverity { critical, suggestion }

class PreflightWarning {
  final String code;
  final String message;
  final WarningSeverity severity;
  final String targetType;
  final String targetId;

  const PreflightWarning(
    this.code,
    this.message, {
    this.severity = WarningSeverity.suggestion,
    this.targetType = 'lesson',
    this.targetId = '',
  });
}

class MoveValidationResult {
  final bool isValid;
  final String? reason;
  const MoveValidationResult(this.isValid, [this.reason]);
}

class ConflictService {
  List<PreflightWarning> preflight(PlannerState planner) {
    final warnings = <PreflightWarning>[];

    // Pinned lesson in teacher time-off slot => critical
    for (final l in planner.lessons) {
      if (!l.isPinned || l.fixedDay == null || l.fixedPeriod == null) continue;
      final key = '${l.fixedDay}-${l.fixedPeriod}';
      for (final tid in l.teacherIds) {
        final teacher = planner.teachers.where((t) => t.id == tid).cast<TeacherItem?>().firstWhere(
              (t) => t != null,
              orElse: () => null,
            );
        if (teacher == null) continue;
        final state = teacher.timeOff[key];
        if (state == TimeOffState.unavailable) {
          warnings.add(
            PreflightWarning(
              'PINNED_IN_TIMEOFF',
              'Pinned lesson (${l.subjectId}) is in unavailable slot D${l.fixedDay} P${l.fixedPeriod} for teacher ${teacher.abbr}.',
              severity: WarningSeverity.critical,
              targetType: 'teacher',
              targetId: teacher.id,
            ),
          );
        }
      }
    }

    // Soft suggestion
    for (final t in planner.teachers) {
      if ((t.maxGapsPerDay ?? 0) >= 5) {
        warnings.add(
          PreflightWarning(
            'HIGH_GAP_LIMIT',
            'Teacher ${t.abbr} has high gap tolerance (${t.maxGapsPerDay}).',
            severity: WarningSeverity.suggestion,
            targetType: 'teacher',
            targetId: t.id,
          ),
        );
      }
    }

    return warnings;
  }

  MoveValidationResult validateManualMove({
    required PlannerState planner,
    required String lessonId,
    required int targetDay,
    required int targetPeriod,
    required List<TimetableAssignment> currentAssignments,
  }) {
    final moving = currentAssignments.where((a) => a.lessonId == lessonId).cast<TimetableAssignment?>().firstWhere(
          (a) => a != null,
          orElse: () => null,
        );
    if (moving == null) return const MoveValidationResult(false, 'Lesson not found');

    // Teacher busy at target slot?
    for (final other in currentAssignments) {
      if (other.lessonId == moving.lessonId) continue;
      if (other.day == targetDay && other.period == targetPeriod) {
        final teacherConflict = other.teacherIds.any(moving.teacherIds.contains);
        if (teacherConflict) return const MoveValidationResult(false, 'Teacher conflict at target slot');

        final classConflict = other.classIds.any(moving.classIds.contains);
        if (classConflict) return const MoveValidationResult(false, 'Class conflict at target slot');
      }
    }

    // Time-off conflict
    for (final tid in moving.teacherIds) {
      final teacher = planner.teachers.where((t) => t.id == tid).cast<TeacherItem?>().firstWhere(
            (t) => t != null,
            orElse: () => null,
          );
      if (teacher == null) continue;
      final state = teacher.timeOff['$targetDay-$targetPeriod'];
      if (state == TimeOffState.unavailable) {
        return MoveValidationResult(false, 'Teacher ${teacher.abbr} unavailable');
      }
    }

    return const MoveValidationResult(true);
  }
}
