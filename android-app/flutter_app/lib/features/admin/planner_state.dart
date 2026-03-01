import 'package:flutter/foundation.dart';

class SubjectItem {
  final String id;
  final String name;
  final String abbr;
  final int color;

  String get abbreviation => abbr;

  SubjectItem({String? id, required this.name, required this.abbr, required this.color})
      : id = id ?? abbr;
}

class ClassItem {
  final String id;
  final String name;
  final String abbr;

  String get abbreviation => abbr;

  ClassItem({String? id, required this.name, required this.abbr})
      : id = id ?? abbr;
}

class TeacherItem {
  final String id;
  final String firstName;
  final String lastName;
  final String abbr;

  String get abbreviation => abbr;
  String get fullName => '$firstName $lastName'.trim();

  TeacherItem({String? id, required this.firstName, required this.lastName, required this.abbr})
      : id = id ?? abbr;
}

class ClassroomItem {
  final String id;
  final String name;
  final String roomType;

  String get type => roomType;

  ClassroomItem({String? id, required this.name, this.roomType = 'standard'})
      : id = id ?? name;
}

class LessonSpec {
  final String subjectId;
  final String teacherId;
  final String classId;
  final int countPerWeek;
  final String length;
  final String? requiredClassroomId;

  LessonSpec({
    required this.subjectId,
    required this.teacherId,
    required this.classId,
    required this.countPerWeek,
    required this.length,
    this.requiredClassroomId,
  });
}

class PlannerState extends ChangeNotifier {
  final List<SubjectItem> subjects = [];
  final List<ClassItem> classes = [];
  final List<TeacherItem> teachers = [];
  final List<ClassroomItem> classrooms = [];
  final List<LessonSpec> lessons = [];

  String schoolName = '';
  int workingDays = 5;
  final List<String> bellTimes = [
    '08:00-08:45',
    '08:45-09:30',
    '09:45-10:30',
    '10:30-11:15',
    '11:30-12:15',
    '12:15-13:00',
    '13:30-14:15',
    '14:15-15:00',
  ];

  void setSchoolName(String value) {
    schoolName = value.trim();
    notifyListeners();
  }

  void setWorkingDays(int value) {
    workingDays = value.clamp(1, 7);
    notifyListeners();
  }

  void setBellTimes(List<String> values) {
    bellTimes
      ..clear()
      ..addAll(values.where((e) => e.trim().isNotEmpty).map((e) => e.trim()));
    notifyListeners();
  }

  void addSubject(SubjectItem item) {
    subjects.add(item);
    notifyListeners();
  }

  void addClass(ClassItem item) {
    classes.add(item);
    notifyListeners();
  }

  void addTeacher(TeacherItem item) {
    teachers.add(item);
    notifyListeners();
  }

  void addClassroom(ClassroomItem item) {
    classrooms.add(item);
    notifyListeners();
  }

  void addLesson({
    required String subjectId,
    required String teacherId,
    required String classId,
    required int countPerWeek,
    required String length,
    String? requiredClassroomId,
  }) {
    lessons.add(
      LessonSpec(
        subjectId: subjectId,
        teacherId: teacherId,
        classId: classId,
        countPerWeek: countPerWeek,
        length: length,
        requiredClassroomId: requiredClassroomId,
      ),
    );
    notifyListeners();
  }

  bool get hasMinimumData =>
      subjects.isNotEmpty && classes.isNotEmpty && teachers.isNotEmpty;

  Map<String, dynamic> toSolverPayload() {
    int i = 1;
    final solverLessons = <Map<String, dynamic>>[];

    if (lessons.isNotEmpty) {
      for (final lesson in lessons) {
        for (int k = 0; k < lesson.countPerWeek; k++) {
          solverLessons.add({
            'id': 'L${i++}',
            'classId': lesson.classId,
            'teacherId': lesson.teacherId,
            'subjectId': lesson.subjectId,
            'preferredRoomId': lesson.requiredClassroomId,
            'isLabDouble': lesson.length == 'double',
          });
        }
      }
    } else {
      for (final c in classes) {
        final teacher = teachers.first;
        final subject = subjects.first;
        for (int k = 0; k < workingDays; k++) {
          solverLessons.add({
            'id': 'L${i++}',
            'classId': c.id,
            'teacherId': teacher.id,
            'subjectId': subject.id,
            'isLabDouble': false,
          });
        }
      }
    }

    return {
      'days': workingDays,
      'periodsPerDay': bellTimes.isEmpty ? 8 : bellTimes.length,
      'seed': 13,
      'lessons': solverLessons,
      'rooms': classrooms
          .map((r) => {
                'id': r.id,
                'roomType': r.roomType,
              })
          .toList(),
      'constraints': {
        'softWeights': {
          'teacher_gaps': 5,
          'class_gaps': 5,
          'subject_distribution': 3,
          'teacher_room_stability': 1,
        }
      }
    };
  }
}
