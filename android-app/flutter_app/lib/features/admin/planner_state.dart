import 'package:flutter/foundation.dart';

import '../../core/database.dart';
import 'time_off_picker.dart';

class SubjectItem {
  final String id;
  final String name;
  final String abbr;
  final int color;
  final String? relationshipGroupKey;

  String get abbreviation => abbr;

  SubjectItem({
    String? id,
    required this.name,
    required this.abbr,
    required this.color,
    this.relationshipGroupKey,
  }) : id = id ?? abbr;
}

class ClassDivisionItem {
  final String id;
  final String classId;
  final String name;
  final String code;

  ClassDivisionItem({
    String? id,
    required this.classId,
    required this.name,
    required this.code,
  }) : id = id ?? '$classId:$code';
}

class ClassItem {
  final String id;
  final String name;
  final String abbr;
  final List<ClassDivisionItem> divisions;

  String get abbreviation => abbr;

  ClassItem({String? id, required this.name, required this.abbr, List<ClassDivisionItem>? divisions})
      : id = id ?? abbr,
        divisions = divisions ?? [];
}

class TeacherItem {
  final String id;
  final String firstName;
  final String lastName;
  final String abbr;
  final int? maxGapsPerDay;
  final int? maxConsecutivePeriods;
  final Map<String, TimeOffState> timeOff;

  String get abbreviation => abbr;
  String get fullName => '$firstName $lastName'.trim();

  TeacherItem({
    String? id,
    required this.firstName,
    required this.lastName,
    required this.abbr,
    this.maxGapsPerDay,
    this.maxConsecutivePeriods,
    Map<String, TimeOffState>? timeOff,
  })  : id = id ?? abbr,
        timeOff = timeOff ?? {};

  TeacherItem copyWith({
    int? maxGapsPerDay,
    int? maxConsecutivePeriods,
    Map<String, TimeOffState>? timeOff,
  }) {
    return TeacherItem(
      id: id,
      firstName: firstName,
      lastName: lastName,
      abbr: abbr,
      maxGapsPerDay: maxGapsPerDay ?? this.maxGapsPerDay,
      maxConsecutivePeriods: maxConsecutivePeriods ?? this.maxConsecutivePeriods,
      timeOff: timeOff ?? this.timeOff,
    );
  }
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
  final String id;
  final String subjectId;
  final List<String> teacherIds;
  final List<String> classIds;
  final String? classDivisionId;
  final int countPerWeek;
  final String length;
  final String? requiredClassroomId;
  final bool isPinned;
  final int? fixedDay;
  final int? fixedPeriod;
  final int? roomTypeId;
  final int relationshipType; // 0 simultaneous, 1 following, 2 same-day
  final String? relationshipGroupKey;

  LessonSpec({
    required this.id,
    required this.subjectId,
    required this.teacherIds,
    required this.classIds,
    this.classDivisionId,
    required this.countPerWeek,
    required this.length,
    this.requiredClassroomId,
    this.isPinned = false,
    this.fixedDay,
    this.fixedPeriod,
    this.roomTypeId,
    this.relationshipType = 0,
    this.relationshipGroupKey,
  });
}

class PlannerState extends ChangeNotifier {
  PlannerState([this._db]) {
    if (_db != null) {
      _hydrate();
    } else {
      hydrated = true;
    }
  }

  final AppDatabase? _db;
  AppDatabase? get db => _db;
  bool hydrated = false;

  final List<SubjectItem> subjects = [];
  final List<ClassItem> classes = [];
  final List<ClassDivisionItem> divisions = [];
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
    _touch();
  }

  void setWorkingDays(int value) {
    workingDays = value.clamp(1, 7);
    _touch();
  }

  void setBellTimes(List<String> values) {
    bellTimes
      ..clear()
      ..addAll(values.where((e) => e.trim().isNotEmpty).map((e) => e.trim()));
    _touch();
  }

  void addSubject(SubjectItem item) {
    subjects.add(item);
    _touch();
  }

  void addClass(ClassItem item) {
    classes.add(item);
    _touch();
  }

  void addDivision({required String classId, required String name, required String code}) {
    final d = ClassDivisionItem(classId: classId, name: name, code: code);
    divisions.add(d);
    final idx = classes.indexWhere((c) => c.id == classId);
    if (idx >= 0) {
      classes[idx].divisions.add(d);
    }
    _touch();
  }

  void addTeacher(TeacherItem item) {
    teachers.add(item);
    _touch();
  }

  void updateTeacherConstraints(
    String teacherId, {
    int? maxGapsPerDay,
    int? maxConsecutivePeriods,
    Map<String, TimeOffState>? timeOff,
  }) {
    final i = teachers.indexWhere((t) => t.id == teacherId);
    if (i < 0) return;
    teachers[i] = teachers[i].copyWith(
      maxGapsPerDay: maxGapsPerDay,
      maxConsecutivePeriods: maxConsecutivePeriods,
      timeOff: timeOff,
    );
    _touch();
  }

  void addClassroom(ClassroomItem item) {
    classrooms.add(item);
    _touch();
  }

  void addLesson({
    required String subjectId,
    String? teacherId,
    String? classId,
    List<String>? teacherIds,
    List<String>? classIds,
    String? classDivisionId,
    required int countPerWeek,
    required String length,
    String? requiredClassroomId,
    bool isPinned = false,
    int? fixedDay,
    int? fixedPeriod,
    int? roomTypeId,
    int relationshipType = 0,
    String? relationshipGroupKey,
  }) {
    final tIds = teacherIds ?? [if (teacherId != null) teacherId];
    final cIds = classIds ?? [if (classId != null) classId];

    final lessonId = "LS${lessons.length + 1}_${DateTime.now().millisecondsSinceEpoch}";

    lessons.add(
      LessonSpec(
        id: lessonId,
        subjectId: subjectId,
        teacherIds: tIds,
        classIds: cIds,
        classDivisionId: classDivisionId,
        countPerWeek: countPerWeek,
        length: length,
        requiredClassroomId: requiredClassroomId,
        isPinned: isPinned,
        fixedDay: fixedDay,
        fixedPeriod: fixedPeriod,
        roomTypeId: roomTypeId,
        relationshipType: relationshipType,
        relationshipGroupKey: relationshipGroupKey,
      ),
    );
    _touch();
  }

  Future<void> _hydrate() async {
    final snap = await _db!.loadPlannerSnapshot();
    if (snap == null) {
      hydrated = true;
      notifyListeners();
      return;
    }

    schoolName = (snap['schoolName'] as String?) ?? schoolName;
    workingDays = (snap['workingDays'] as int?) ?? workingDays;

    bellTimes
      ..clear()
      ..addAll(((snap['bellTimes'] as List?) ?? const []).map((e) => e.toString()));

    subjects
      ..clear()
      ..addAll((((snap['subjects'] as List?) ?? const [])).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return SubjectItem(
          id: m['id']?.toString(),
          name: m['name']?.toString() ?? '',
          abbr: m['abbr']?.toString() ?? '',
          color: (m['color'] as num?)?.toInt() ?? 0xFF0B3D91,
          relationshipGroupKey: m['relationshipGroupKey']?.toString(),
        );
      }));

    classes
      ..clear()
      ..addAll((((snap['classes'] as List?) ?? const [])).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return ClassItem(id: m['id']?.toString(), name: m['name']?.toString() ?? '', abbr: m['abbr']?.toString() ?? '');
      }));

    divisions
      ..clear()
      ..addAll((((snap['divisions'] as List?) ?? const [])).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return ClassDivisionItem(
          id: m['id']?.toString(),
          classId: m['classId']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          code: m['code']?.toString() ?? '',
        );
      }));

    for (final c in classes) {
      c.divisions.addAll(divisions.where((d) => d.classId == c.id));
    }

    teachers
      ..clear()
      ..addAll((((snap['teachers'] as List?) ?? const [])).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final rawOff = Map<String, dynamic>.from((m['timeOff'] as Map?) ?? const {});
        return TeacherItem(
          id: m['id']?.toString(),
          firstName: m['firstName']?.toString() ?? '',
          lastName: m['lastName']?.toString() ?? '',
          abbr: m['abbr']?.toString() ?? '',
          maxGapsPerDay: (m['maxGapsPerDay'] as num?)?.toInt(),
          maxConsecutivePeriods: (m['maxConsecutivePeriods'] as num?)?.toInt(),
          timeOff: rawOff.map((k, v) => MapEntry(k, TimeOffState.values[(v as num).toInt()])),
        );
      }));

    classrooms
      ..clear()
      ..addAll((((snap['classrooms'] as List?) ?? const [])).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return ClassroomItem(id: m['id']?.toString(), name: m['name']?.toString() ?? '', roomType: m['roomType']?.toString() ?? 'standard');
      }));

    lessons
      ..clear()
      ..addAll((((snap['lessons'] as List?) ?? const [])).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return LessonSpec(
          id: m['id']?.toString() ?? "LS_hydrated",
          subjectId: m['subjectId']?.toString() ?? '',
          teacherIds: ((m['teacherIds'] as List?) ?? const []).map((x) => x.toString()).toList(),
          classIds: ((m['classIds'] as List?) ?? const []).map((x) => x.toString()).toList(),
          classDivisionId: m['classDivisionId']?.toString(),
          countPerWeek: (m['countPerWeek'] as num?)?.toInt() ?? 1,
          length: m['length']?.toString() ?? 'single',
          requiredClassroomId: m['requiredClassroomId']?.toString(),
          isPinned: m['isPinned'] == true,
          fixedDay: (m['fixedDay'] as num?)?.toInt(),
          fixedPeriod: (m['fixedPeriod'] as num?)?.toInt(),
          roomTypeId: (m['roomTypeId'] as num?)?.toInt(),
          relationshipType: (m['relationshipType'] as num?)?.toInt() ?? 0,
          relationshipGroupKey: m['relationshipGroupKey']?.toString(),
        );
      }));

    hydrated = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final json = {
      'schoolName': schoolName,
      'workingDays': workingDays,
      'bellTimes': bellTimes,
      'subjects': subjects
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'abbr': s.abbr,
                'color': s.color,
                'relationshipGroupKey': s.relationshipGroupKey,
              })
          .toList(),
      'classes': classes.map((c) => {'id': c.id, 'name': c.name, 'abbr': c.abbr}).toList(),
      'divisions': divisions
          .map((d) => {'id': d.id, 'classId': d.classId, 'name': d.name, 'code': d.code})
          .toList(),
      'teachers': teachers
          .map((t) => {
                'id': t.id,
                'firstName': t.firstName,
                'lastName': t.lastName,
                'abbr': t.abbr,
                'maxGapsPerDay': t.maxGapsPerDay,
                'maxConsecutivePeriods': t.maxConsecutivePeriods,
                'timeOff': t.timeOff.map((k, v) => MapEntry(k, v.index)),
              })
          .toList(),
      'classrooms': classrooms.map((r) => {'id': r.id, 'name': r.name, 'roomType': r.roomType}).toList(),
      'lessons': lessons
          .map((l) => {
                'id': l.id,
                'subjectId': l.subjectId,
                'teacherIds': l.teacherIds,
                'classIds': l.classIds,
                'classDivisionId': l.classDivisionId,
                'countPerWeek': l.countPerWeek,
                'length': l.length,
                'requiredClassroomId': l.requiredClassroomId,
                'isPinned': l.isPinned,
                'fixedDay': l.fixedDay,
                'fixedPeriod': l.fixedPeriod,
                'roomTypeId': l.roomTypeId,
                'relationshipType': l.relationshipType,
                'relationshipGroupKey': l.relationshipGroupKey,
              })
          .toList(),
    };

    final db = _db;
    if (db != null) {
      await db.savePlannerSnapshot(json);
    }
  }

  void _touch() {
    notifyListeners();
    _persist();
  }



  Future<void> pinLessonToSlot({
    required String lessonId,
    required int day,
    required int period,
  }) async {
    final idx = lessons.indexWhere((l) => l.id == lessonId);
    if (idx < 0) return;
    final old = lessons[idx];
    lessons[idx] = LessonSpec(
      id: old.id,
      subjectId: old.subjectId,
      teacherIds: old.teacherIds,
      classIds: old.classIds,
      classDivisionId: old.classDivisionId,
      countPerWeek: old.countPerWeek,
      length: old.length,
      requiredClassroomId: old.requiredClassroomId,
      isPinned: true,
      fixedDay: day,
      fixedPeriod: period,
      roomTypeId: old.roomTypeId,
      relationshipType: old.relationshipType,
      relationshipGroupKey: old.relationshipGroupKey,
    );
    await _persist();
    notifyListeners();
  }
  bool get hasMinimumData =>
      subjects.isNotEmpty && classes.isNotEmpty && teachers.isNotEmpty;

  Map<String, dynamic> toSolverPayload() {
    final solverLessons = <Map<String, dynamic>>[];
    final lessonClassesRows = <Map<String, dynamic>>[]; // emulates junction table writes

    var solverLid = 1;
    if (lessons.isNotEmpty) {
      for (final lesson in lessons) {
        for (int k = 0; k < lesson.countPerWeek; k++) {
          // Each solver lesson must have a unique ID; the same LessonSpec
          // is expanded once per countPerWeek.
          final lid = 'SL${solverLid++}_${lesson.id}';
          solverLessons.add({
            'id': lid,
            'classIds': lesson.classIds,
            'teacherIds': lesson.teacherIds,
            'subjectId': lesson.subjectId,
            'preferredRoomId': lesson.requiredClassroomId,
            'isLabDouble': lesson.length == 'double',
            'isPinned': lesson.isPinned,
            'fixedDay': lesson.fixedDay,
            'fixedPeriod': lesson.fixedPeriod,
            'relationshipType': lesson.relationshipType,
            'relationshipGroupKey': lesson.relationshipGroupKey,
            'classDivisionId': lesson.classDivisionId,
            'syncGroupId': lesson.relationshipGroupKey,
          });

          // emulate LessonClasses junction insert rows for joint classes
          for (final cid in lesson.classIds) {
            lessonClassesRows.add({'lessonId': lid, 'classId': cid});
          }
        }
      }
    }

    final teacherAvailability = <String, int>{};
    final teacherMaxConsecutive = <String, int>{};

    for (final t in teachers) {
      if (t.maxConsecutivePeriods != null) {
        teacherMaxConsecutive[t.id] = t.maxConsecutivePeriods!;
      }
      t.timeOff.forEach((key, state) {
        final stateCode = switch (state) {
          TimeOffState.available => 1,
          TimeOffState.unavailable => 0,
          TimeOffState.conditional => 2,
        };
        teacherAvailability['${t.id}:$key'] = stateCode;
      });
    }

    return {
      'days': workingDays,
      'periodsPerDay': bellTimes.isEmpty ? 8 : bellTimes.length,
      'timeoutMs': 15000,
      'lessons': solverLessons,
      'rooms': classrooms
          .map((r) => {
                'id': r.id,
                'roomType': r.roomType,
              })
          .toList(),
      'constraints': {
        'teacherAvailability': teacherAvailability,
        'teacherMaxConsecutivePeriods': teacherMaxConsecutive,
        'softWeights': {
          'teacher_gaps': 5,
          'class_gaps': 5,
          'subject_distribution': 3,
          'teacher_room_stability': 1,
        }
      },
      'debug': {
        'lessonClassesRows': lessonClassesRows,
      }
    };
  }
}
