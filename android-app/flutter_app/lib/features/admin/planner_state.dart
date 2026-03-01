import 'package:flutter/material.dart';

class DayConfig {
  DayConfig({required this.name, required this.abbreviation});

  String name;
  String abbreviation;

  Map<String, dynamic> toJson() => {
        'name': name,
        'abbreviation': abbreviation,
      };
}

class BellSlot {
  BellSlot({required this.start, required this.end});

  TimeOfDay start;
  TimeOfDay end;

  Map<String, dynamic> toJson() => {
        'start': _as24(start),
        'end': _as24(end),
      };

  static String _as24(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class BreakSlot {
  BreakSlot({required this.afterPeriod, required this.start, required this.end});

  int afterPeriod;
  TimeOfDay start;
  TimeOfDay end;

  Map<String, dynamic> toJson() => {
        'afterPeriod': afterPeriod,
        'start': BellSlot._as24(start),
        'end': BellSlot._as24(end),
      };
}

class SubjectEntity {
  SubjectEntity({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.color,
    Set<String>? unavailableSlots,
  }) : unavailableSlots = unavailableSlots ?? <String>{};

  final String id;
  final String name;
  final String abbreviation;
  final Color color;
  final Set<String> unavailableSlots;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'color': color.toARGB32(),
        'unavailableSlots': unavailableSlots.toList(),
      };
}

class ClassEntity {
  ClassEntity({required this.id, required this.name, required this.abbreviation});

  final String id;
  final String name;
  final String abbreviation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
      };
}

class ClassroomEntity {
  ClassroomEntity({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.type,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String type;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'type': type,
      };
}

class TeacherEntity {
  TeacherEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.abbreviation,
    Set<String>? unavailableSlots,
  }) : unavailableSlots = unavailableSlots ?? <String>{};

  final String id;
  final String firstName;
  final String lastName;
  final String abbreviation;
  final Set<String> unavailableSlots;

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'abbreviation': abbreviation,
        'unavailableSlots': unavailableSlots.toList(),
      };
}

class LessonEntity {
  LessonEntity({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.classId,
    required this.countPerWeek,
    required this.length,
    this.requiredClassroomId,
  });

  final String id;
  final String subjectId;
  final String teacherId;
  final String classId;
  final int countPerWeek;
  final String length;
  final String? requiredClassroomId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'classId': classId,
        'countPerWeek': countPerWeek,
        'length': length,
        if (requiredClassroomId != null) 'requiredClassroomId': requiredClassroomId,
      };
}

class PlannerState extends ChangeNotifier {
  bool setupComplete = false;
  String schoolName = '';
  String schoolYear = '';

  List<DayConfig> days = [
    DayConfig(name: 'Monday', abbreviation: 'Mon'),
    DayConfig(name: 'Tuesday', abbreviation: 'Tue'),
    DayConfig(name: 'Wednesday', abbreviation: 'Wed'),
    DayConfig(name: 'Thursday', abbreviation: 'Thu'),
    DayConfig(name: 'Friday', abbreviation: 'Fri'),
  ];

  int periodsPerDay = 7;
  List<BellSlot> bellSlots = List.generate(
    7,
    (index) => BellSlot(
      start: TimeOfDay(hour: 8 + index, minute: 0),
      end: TimeOfDay(hour: 8 + index, minute: 45),
    ),
  );
  List<BreakSlot> breaks = [];

  final List<SubjectEntity> subjects = [];
  final List<ClassEntity> classes = [];
  final List<ClassroomEntity> classrooms = [];
  final List<TeacherEntity> teachers = [];
  final List<LessonEntity> lessons = [];

  void saveSchoolSettings({required String name, required String year}) {
    schoolName = name;
    schoolYear = year;
    notifyListeners();
  }

  void setDaysCount(int count) {
    if (count < 1) return;
    if (count > days.length) {
      for (int i = days.length; i < count; i++) {
        days.add(DayConfig(name: 'Day ${i + 1}', abbreviation: 'D${i + 1}'));
      }
    } else {
      days = days.take(count).toList();
    }
    notifyListeners();
  }

  void updateDay(int index, {required String name, required String abbreviation}) {
    if (index < 0 || index >= days.length) return;
    days[index].name = name;
    days[index].abbreviation = abbreviation;
    notifyListeners();
  }

  void setPeriodsPerDay(int count) {
    periodsPerDay = count;
    if (count > bellSlots.length) {
      for (int i = bellSlots.length; i < count; i++) {
        bellSlots.add(BellSlot(
          start: TimeOfDay(hour: 8 + i, minute: 0),
          end: TimeOfDay(hour: 8 + i, minute: 45),
        ));
      }
    } else {
      bellSlots = bellSlots.take(count).toList();
      breaks.removeWhere((b) => b.afterPeriod >= count);
    }
    notifyListeners();
  }

  void updateBellSlot(int index, {TimeOfDay? start, TimeOfDay? end}) {
    if (index < 0 || index >= bellSlots.length) return;
    final current = bellSlots[index];
    bellSlots[index] = BellSlot(start: start ?? current.start, end: end ?? current.end);
    notifyListeners();
  }

  void addBreak() {
    final defaultPeriod = (periodsPerDay > 1) ? 1 : 0;
    if (defaultPeriod == 0) return;
    breaks.add(BreakSlot(
      afterPeriod: defaultPeriod,
      start: const TimeOfDay(hour: 10, minute: 30),
      end: const TimeOfDay(hour: 10, minute: 45),
    ));
    notifyListeners();
  }

  void updateBreak(int index, {int? afterPeriod, TimeOfDay? start, TimeOfDay? end}) {
    if (index < 0 || index >= breaks.length) return;
    final current = breaks[index];
    breaks[index] = BreakSlot(
      afterPeriod: afterPeriod ?? current.afterPeriod,
      start: start ?? current.start,
      end: end ?? current.end,
    );
    notifyListeners();
  }

  void removeBreak(int index) {
    if (index < 0 || index >= breaks.length) return;
    breaks.removeAt(index);
    notifyListeners();
  }

  void completeSetup() {
    setupComplete = true;
    notifyListeners();
  }

  String _id(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  void addSubject({required String name, required String abbreviation, required Color color}) {
    subjects.add(SubjectEntity(id: _id('sub'), name: name, abbreviation: abbreviation, color: color));
    notifyListeners();
  }

  void addClass({required String name, required String abbreviation}) {
    classes.add(ClassEntity(id: _id('class'), name: name, abbreviation: abbreviation));
    notifyListeners();
  }

  void addClassroom({required String name, required String abbreviation, required String type}) {
    classrooms.add(ClassroomEntity(id: _id('room'), name: name, abbreviation: abbreviation, type: type));
    notifyListeners();
  }

  void addTeacher({required String firstName, required String lastName, required String abbreviation}) {
    teachers.add(TeacherEntity(id: _id('teacher'), firstName: firstName, lastName: lastName, abbreviation: abbreviation));
    notifyListeners();
  }

  void setTeacherAvailability(String teacherId, Set<String> unavailableSlots) {
    final idx = teachers.indexWhere((t) => t.id == teacherId);
    if (idx == -1) return;
    final current = teachers[idx];
    teachers[idx] = TeacherEntity(
      id: current.id,
      firstName: current.firstName,
      lastName: current.lastName,
      abbreviation: current.abbreviation,
      unavailableSlots: unavailableSlots,
    );
    notifyListeners();
  }

  void setSubjectAvailability(String subjectId, Set<String> unavailableSlots) {
    final idx = subjects.indexWhere((s) => s.id == subjectId);
    if (idx == -1) return;
    final current = subjects[idx];
    subjects[idx] = SubjectEntity(
      id: current.id,
      name: current.name,
      abbreviation: current.abbreviation,
      color: current.color,
      unavailableSlots: unavailableSlots,
    );
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
    lessons.add(LessonEntity(
      id: _id('lesson'),
      subjectId: subjectId,
      teacherId: teacherId,
      classId: classId,
      countPerWeek: countPerWeek,
      length: length,
      requiredClassroomId: requiredClassroomId,
    ));
    notifyListeners();
  }

  Map<String, dynamic> toSolverPayload() {
    return {
      'school': {
        'name': schoolName,
        'year': schoolYear,
      },
      'days': days.map((d) => d.toJson()).toList(),
      'periodsPerDay': periodsPerDay,
      'bellTimes': bellSlots.map((b) => b.toJson()).toList(),
      'breaks': breaks.map((b) => b.toJson()).toList(),
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'classes': classes.map((c) => c.toJson()).toList(),
      'classrooms': classrooms.map((r) => r.toJson()).toList(),
      'teachers': teachers.map((t) => t.toJson()).toList(),
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }
}
