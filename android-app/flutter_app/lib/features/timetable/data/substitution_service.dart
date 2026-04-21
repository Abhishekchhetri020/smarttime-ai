import '../../admin/planner_state.dart';
import '../../admin/time_off_picker.dart';
import '../presentation/controllers/solver_controller.dart';

class SubstituteCandidate {
  final String teacherId;
  final String teacherName;
  final double score;
  final List<String> reasons;

  const SubstituteCandidate({
    required this.teacherId,
    required this.teacherName,
    required this.score,
    this.reasons = const [],
  });
}

class SubstitutionService {
  List<SubstituteCandidate> findSubstitutes({
    required PlannerState planner,
    required String absentTeacherId,
    required int day, // 1-indexed
    required int period, // 1-indexed
    required String subjectId,
    required List<TimetableAssignment> currentAssignments,
  }) {
    final candidates = <SubstituteCandidate>[];

    for (final teacher in planner.teachers) {
      if (teacher.id == absentTeacherId) continue;

      final reasons = <String>[];
      double score = 0.0;

      // 1. Is teacher already busy at this time?
      final isBusy = currentAssignments.any((a) =>
          a.day == day &&
          a.period == period &&
          a.teacherIds.contains(teacher.id));
      if (isBusy) continue;

      // 2. Is this slot in teacher's unavailable time-off?
      final timeOffKey = '$day-$period';
      if (teacher.timeOff[timeOffKey] == TimeOffState.unavailable) {
        continue;
      }

      // 3. Does teacher teach this subject?
      final teachesSubject = planner.lessons
          .any((l) => l.teacherIds.contains(teacher.id) && l.subjectId == subjectId);
      if (teachesSubject) {
        score += 50.0;
        reasons.add('Teaches same subject');
      }

      // 4. Bonus: Is teacher already in the building? (if we had building info here)
      // 5. Penalty: Does this create a gap or violation? (simplified for now)

      candidates.add(SubstituteCandidate(
        teacherId: teacher.id,
        teacherName: teacher.name,
        score: score,
        reasons: reasons,
      ));
    }

    // Sort by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }
}
