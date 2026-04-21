import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

import '../../core/database.dart';
import 'schedule_entry.dart';
import 'time_off_picker.dart';

class SubjectItem {
  final String id;
  final String name;
  final String abbr;
  final int color;
  final String? relationshipGroupKey;
  final Map<String, TimeOffState> timeOff;

  String get abbreviation => abbr;

  SubjectItem({
    String? id,
    required this.name,
    required this.abbr,
    required this.color,
    this.relationshipGroupKey,
    Map<String, TimeOffState>? timeOff,
  })  : id = id ?? abbr,
        timeOff = timeOff ?? {};

  SubjectItem copyWith({
    String? name,
    String? abbr,
    int? color,
    String? relationshipGroupKey,
    Map<String, TimeOffState>? timeOff,
  }) {
    return SubjectItem(
      id: id,
      name: name ?? this.name,
      abbr: abbr ?? this.abbr,
      color: color ?? this.color,
      relationshipGroupKey: relationshipGroupKey ?? this.relationshipGroupKey,
      timeOff: timeOff ?? this.timeOff,
    );
  }
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
  final String? color;
  final List<ClassDivisionItem> divisions;
  final Map<String, TimeOffState> timeOff;
  final String? classTeacherId;

  String get abbreviation => abbr;

  ClassItem({
    String? id,
    required this.name,
    required this.abbr,
    this.color,
    List<ClassDivisionItem>? divisions,
    Map<String, TimeOffState>? timeOff,
    this.classTeacherId,
  })  : id = id ?? abbr,
        divisions = divisions ?? [],
        timeOff = timeOff ?? {};

  ClassItem copyWith({
    String? name,
    String? abbr,
    String? color,
    List<ClassDivisionItem>? divisions,
    Map<String, TimeOffState>? timeOff,
    String? classTeacherId,
  }) {
    return ClassItem(
      id: id,
      name: name ?? this.name,
      abbr: abbr ?? this.abbr,
      color: color ?? this.color,
      divisions: divisions ?? this.divisions,
      timeOff: timeOff ?? this.timeOff,
      classTeacherId: classTeacherId ?? this.classTeacherId,
    );
  }
}

class TeacherItem {
  final String id;
  final String firstName;
  final String lastName;
  final String abbr;
  final String? color;
  final int? maxGapsPerDay;
  final int? maxConsecutivePeriods;
  final Map<String, TimeOffState> timeOff;
  final String? email;
  final String? phone;
  final String? designation;

  String get abbreviation => abbr;
  String get fullName => '$firstName $lastName'.trim();

  TeacherItem({
    String? id,
    required this.firstName,
    required this.lastName,
    required this.abbr,
    this.color,
    this.maxGapsPerDay,
    this.maxConsecutivePeriods,
    Map<String, TimeOffState>? timeOff,
    this.email,
    this.phone,
    this.designation,
  })  : id = id ?? abbr,
        timeOff = timeOff ?? {};

  TeacherItem copyWith({
    String? firstName,
    String? lastName,
    String? abbr,
    String? color,
    int? maxGapsPerDay,
    int? maxConsecutivePeriods,
    Map<String, TimeOffState>? timeOff,
    String? email,
    String? phone,
    String? designation,
  }) {
    return TeacherItem(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      abbr: abbr ?? this.abbr,
      color: color ?? this.color,
      maxGapsPerDay: maxGapsPerDay ?? this.maxGapsPerDay,
      maxConsecutivePeriods:
          maxConsecutivePeriods ?? this.maxConsecutivePeriods,
      timeOff: timeOff ?? this.timeOff,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
    );
  }
}

class ClassroomItem {
  final String id;
  final String name;
  final String roomType;
  final String abbr;
  final String? buildingName;
  final int? capacity;
  final String? color;
  final String? groupId;
  final List<String> assignedTeacherIds;
  final List<String> assignedClassIds;
  final Map<String, TimeOffState> timeOff;

  String get type => roomType;

  ClassroomItem({
    String? id,
    required this.name,
    this.roomType = 'standard',
    String? abbr,
    this.buildingName,
    this.capacity,
    this.color,
    this.groupId,
    List<String>? assignedTeacherIds,
    List<String>? assignedClassIds,
    Map<String, TimeOffState>? timeOff,
  })  : id = id ?? name,
        abbr = abbr ?? name,
        assignedTeacherIds = assignedTeacherIds ?? [],
        assignedClassIds = assignedClassIds ?? [],
        timeOff = timeOff ?? {};

  ClassroomItem copyWith({
    String? name,
    String? roomType,
    String? abbr,
    String? buildingName,
    int? capacity,
    String? color,
    String? groupId,
    List<String>? assignedTeacherIds,
    List<String>? assignedClassIds,
    Map<String, TimeOffState>? timeOff,
  }) {
    return ClassroomItem(
      id: id,
      name: name ?? this.name,
      roomType: roomType ?? this.roomType,
      abbr: abbr ?? this.abbr,
      buildingName: buildingName ?? this.buildingName,
      capacity: capacity ?? this.capacity,
      color: color ?? this.color,
      groupId: groupId ?? this.groupId,
      assignedTeacherIds: assignedTeacherIds ?? this.assignedTeacherIds,
      assignedClassIds: assignedClassIds ?? this.assignedClassIds,
      timeOff: timeOff ?? this.timeOff,
    );
  }
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

class CardRelationship {
  final String id;
  final List<String> subjectIds;
  final List<String> classIds;
  final String condition;
  final String importance;
  final String note;
  bool isActive;

  CardRelationship({
    required this.id,
    required this.subjectIds,
    required this.classIds,
    required this.condition,
    required this.importance,
    this.note = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectIds': subjectIds,
        'classIds': classIds,
        'condition': condition,
        'importance': importance,
        'note': note,
        'isActive': isActive,
      };

  factory CardRelationship.fromJson(Map<String, dynamic> json) =>
      CardRelationship(
        id: json['id'] as String,
        subjectIds: List<String>.from(json['subjectIds'] ?? []),
        classIds: List<String>.from(json['classIds'] ?? []),
        condition: json['condition'] as String,
        importance: json['importance'] as String,
        note: json['note'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
}

class PlannerState extends ChangeNotifier {
  PlannerState(this._db, {this.dbId = 0});

  final AppDatabase? _db;
  int dbId;
  String draftName = 'Untitled Timetable';
  String status = 'draft';
  DateTime createdAt = DateTime.now();

  AppDatabase? get db => _db;
  bool hydrated = false;
  final _lock = Lock();

  final List<SubjectItem> subjects = [];
  final List<ClassItem> classes = [];
  final List<ClassDivisionItem> divisions = [];
  final List<TeacherItem> teachers = [];
  final List<ClassroomItem> classrooms = [];
  final List<LessonSpec> lessons = [];
  final List<CardRelationship> cardRelationships = [];

  String sessionName = '';
  String? sessionStartDate;
  String? sessionEndDate;

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

  final List<ScheduleEntry> scheduleEntries = [];

  // Solver optimization weights (user-configurable)
  Map<String, int> softWeights = {
    'teacher_gaps': 5,
    'class_gaps': 5,
    'subject_distribution': 3,
    'teacher_room_stability': 1,
  };

  void setSchoolName(String value) {
    schoolName = value.trim();
    _touch();
  }

  void setSessionDetails({required String name, String? start, String? end}) {
    sessionName = name.trim();
    sessionStartDate = start;
    sessionEndDate = end;
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
    _syncScheduleEntriesFromBellTimes();
    _touch();
  }

  void setScheduleEntries(List<ScheduleEntry> values) {
    scheduleEntries
      ..clear()
      ..addAll(values);
    bellTimes
      ..clear()
      ..addAll(scheduleEntries
          .where((e) => e.type == ScheduleEntryType.period)
          .map((e) => e.timeRange));
    _touch();
  }

  void _syncScheduleEntriesFromBellTimes() {
    scheduleEntries
      ..clear()
      ..addAll(
        bellTimes
            .asMap()
            .entries
            .map((entry) =>
                ScheduleEntry.fromBellTime(entry.value, index: entry.key))
            .whereType<ScheduleEntry>(),
      );
  }

  Future<void> addSubject(SubjectItem item) async {
    subjects.add(item);
    final db = _db;
    if (db != null) {
      await db.into(db.subjects).insertOnConflictUpdate(
            SubjectsCompanion.insert(
              id: item.id,
              guid: Value(_randomGuidV4()),
              name: item.name,
              abbr: item.abbr,
              color: Value(item.color),
              groupId: Value(item.relationshipGroupKey),
            ),
          );
    }
    await _touch();
  }

  void updateSubject(SubjectItem updated) {
    final idx = subjects.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    subjects[idx] = updated;
    notifyListeners();
    _persist();
  }

  void updateSubjectConstraints(
      String subjectId, Map<String, TimeOffState> newTimeOff) {
    final idx = subjects.indexWhere((s) => s.id == subjectId);
    if (idx == -1) return;
    subjects[idx] = subjects[idx].copyWith(timeOff: newTimeOff);
    notifyListeners();
    _persist();
  }

  Future<void> addClass(ClassItem item) async {
    final idx = classes.indexWhere((c) => c.id == item.id);
    if (idx >= 0) {
      classes[idx] = item;
    } else {
      classes.add(item);
    }
    await _touch();
  }

  Future<void> updateClass(ClassItem updated) async {
    final idx = classes.indexWhere((c) => c.id == updated.id);
    if (idx < 0) return;
    classes[idx] = updated;
    await _touch();
  }

  Future<void> removeClass(String classId) async {
    classes.removeWhere((c) => c.id == classId);
    await _touch();
  }

  void updateClassConstraints(
    String classId, {
    Map<String, TimeOffState>? timeOff,
  }) {
    final i = classes.indexWhere((c) => c.id == classId);
    if (i < 0) return;
    classes[i] = classes[i].copyWith(
      timeOff: timeOff,
    );
    _touch();
  }

  void addDivision(
      {required String classId, required String name, required String code}) {
    final d = ClassDivisionItem(classId: classId, name: name, code: code);
    divisions.add(d);
    final idx = classes.indexWhere((c) => c.id == classId);
    if (idx >= 0) {
      classes[idx].divisions.add(d);
    }
    _touch();
  }

  Future<void> addTeacher(TeacherItem item) async {
    final idx = teachers.indexWhere((t) => t.id == item.id);
    if (idx >= 0) {
      teachers[idx] = item;
    } else {
      teachers.add(item);
    }
    final db = _db;
    if (db != null) {
      await db.into(db.teachers).insertOnConflictUpdate(
            TeachersCompanion.insert(
              id: item.id,
              guid: Value(_randomGuidV4()),
              name: item.fullName,
              abbreviation: item.abbr,
              maxGapsPerDay: Value(item.maxGapsPerDay),
            ),
          );
    }
    await _touch();
  }

  Future<void> removeTeacher(String teacherId) async {
    teachers.removeWhere((t) => t.id == teacherId);
    await _touch();
  }

  Future<void> updateTeacher(TeacherItem updated) async {
    final idx = teachers.indexWhere((t) => t.id == updated.id);
    if (idx < 0) return;
    teachers[idx] = updated;
    await _touch();
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

  Future<void> addClassroom(ClassroomItem item) async {
    final idx = classrooms.indexWhere((r) => r.id == item.id);
    if (idx >= 0) {
      classrooms[idx] = item;
    } else {
      classrooms.add(item);
    }
    await _touch();
  }

  Future<void> removeClassroom(String roomId) async {
    classrooms.removeWhere((r) => r.id == roomId);
    await _touch();
  }

  Future<void> updateRoom(ClassroomItem updated) async {
    final idx = classrooms.indexWhere((r) => r.id == updated.id);
    if (idx < 0) return;
    classrooms[idx] = updated;
    await _touch();
  }

  void addLesson({
    String? id,
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

    final lessonId = id ??
        "LS${lessons.length + 1}_${DateTime.now().millisecondsSinceEpoch}";

    final spec = LessonSpec(
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
    );

    if (id != null) {
      final idx = lessons.indexWhere((l) => l.id == id);
      if (idx >= 0) {
        lessons[idx] = spec;
        _touch();
        return;
      }
    }
    lessons.add(spec);
    _touch();
  }

  void removeLesson(String lessonId) {
    lessons.removeWhere((l) => l.id == lessonId);
    _touch();
  }

  // ── Soft weight management ──
  void updateSoftWeight(String key, int value) {
    softWeights[key] = value.clamp(0, 10);
    _touch();
  }

  // ── Card Relationships ──
  void addCardRelationship(CardRelationship rule) {
    cardRelationships.add(rule);
    _touch();
  }

  void updateCardRelationship(CardRelationship rule) {
    final idx = cardRelationships.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) {
      cardRelationships[idx] = rule;
      _touch();
    }
  }

  void removeCardRelationship(String id) {
    cardRelationships.removeWhere((r) => r.id == id);
    _touch();
  }

  Future<void> saveToDatabase() async {
    await _persist();
  }

  Future<void> refreshFromDatabase() async {
    if (_db == null) return;
    await _hydrate();
  }

  Future<void> _hydrate() async {
    debugPrint('--- HYDRATE STARTED ---');
    await _lock.synchronized(() async {
      debugPrint('--- HYDRATE LOCK ACQUIRED ---');
      final snap = await _db!.loadPlannerSnapshot(dbId);
      debugPrint('--- HYDRATE SNAPSHOT LOADED: ${snap != null} ---');
      if (snap == null) {
        hydrated = true;
        notifyListeners();
        return;
      }

      draftName = (snap['draftName'] as String?) ?? 'Untitled Timetable';
      status = (snap['status'] as String?) ?? 'draft';
      createdAt = DateTime.tryParse(snap['createdAt'] as String? ?? '') ??
          DateTime.now();

      sessionName = (snap['sessionName'] as String?) ?? sessionName;
      sessionStartDate = snap['sessionStartDate'] as String?;
      sessionEndDate = snap['sessionEndDate'] as String?;
      schoolName = (snap['schoolName'] as String?) ?? schoolName;
      workingDays = (snap['workingDays'] as int?) ?? workingDays;

      // Restore soft weights
      final rawWeights = snap['softWeights'] as Map?;
      if (rawWeights != null) {
        softWeights = Map<String, int>.from(
          rawWeights.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        );
      }

      // Restore card relationships
      cardRelationships.clear();
      final rawRelationships = (snap['cardRelationships'] as List?) ?? const [];
      for (final r in rawRelationships) {
        if (r is Map<String, dynamic>) {
          cardRelationships.add(CardRelationship.fromJson(r));
        }
      }

      bellTimes
        ..clear()
        ..addAll(((snap['bellTimes'] as List?) ?? const [])
            .map((e) => e.toString()));

      final rawEntries = (snap['scheduleEntries'] as List?) ?? const [];
      if (rawEntries.isNotEmpty) {
        scheduleEntries
          ..clear()
          ..addAll(
            rawEntries
                .whereType<Map<String, dynamic>>()
                .map((e) => ScheduleEntry.fromJson(e))
                .whereType<ScheduleEntry>(),
          );
        if (scheduleEntries.isNotEmpty) {
          bellTimes
            ..clear()
            ..addAll(scheduleEntries
                .where((e) => e.type == ScheduleEntryType.period)
                .map((e) => e.timeRange));
        }
      }

      if (scheduleEntries.isEmpty) {
        _syncScheduleEntriesFromBellTimes();
      }

      subjects
        ..clear()
        ..addAll((((snap['subjects'] as List?) ?? const []))
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final rawOff =
              Map<String, dynamic>.from((m['timeOff'] as Map?) ?? const {});
          return SubjectItem(
            id: m['id']?.toString(),
            name: m['name']?.toString() ?? '',
            abbr: m['abbr']?.toString() ?? '',
            color: (m['color'] as num?)?.toInt() ?? 0xFF4F46E5,
            relationshipGroupKey: m['relationshipGroupKey']?.toString(),
            timeOff: rawOff.map((k, v) {
              final idx = (v as num?)?.toInt();
              final state =
                  (idx != null && idx >= 0 && idx < TimeOffState.values.length)
                      ? TimeOffState.values[idx]
                      : TimeOffState.available;
              return MapEntry(k, state);
            }),
          );
        }));

      classes
        ..clear()
        ..addAll((((snap['classes'] as List?) ?? const []))
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final rawOff =
              Map<String, dynamic>.from((m['timeOff'] as Map?) ?? const {});
          return ClassItem(
            id: m['id']?.toString(),
            name: m['name']?.toString() ?? '',
            abbr: m['abbr']?.toString() ?? '',
            classTeacherId: m['classTeacherId']?.toString(),
            timeOff: rawOff.map((k, v) {
              final idx = (v as num?)?.toInt();
              final state =
                  (idx != null && idx >= 0 && idx < TimeOffState.values.length)
                      ? TimeOffState.values[idx]
                      : TimeOffState.available;
              return MapEntry(k, state);
            }),
          );
        }));

      divisions
        ..clear()
        ..addAll((((snap['divisions'] as List?) ?? const []))
            .whereType<Map<String, dynamic>>()
            .map((m) {
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
        ..addAll((((snap['teachers'] as List?) ?? const []))
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final rawOff =
              Map<String, dynamic>.from((m['timeOff'] as Map?) ?? const {});
          return TeacherItem(
            id: m['id']?.toString(),
            firstName: m['firstName']?.toString() ?? '',
            lastName: m['lastName']?.toString() ?? '',
            abbr: m['abbr']?.toString() ?? '',
            maxGapsPerDay: (m['maxGapsPerDay'] as num?)?.toInt(),
            maxConsecutivePeriods:
                (m['maxConsecutivePeriods'] as num?)?.toInt(),
            timeOff: rawOff.map((k, v) {
              final idx = (v as num?)?.toInt();
              final state =
                  (idx != null && idx >= 0 && idx < TimeOffState.values.length)
                      ? TimeOffState.values[idx]
                      : TimeOffState.available;
              return MapEntry(k, state);
            }),
            email: m['email']?.toString(),
            phone: m['phone']?.toString(),
            designation: m['designation']?.toString(),
          );
        }));

      classrooms
        ..clear()
        ..addAll((((snap['classrooms'] as List?) ?? const []))
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final rawOff =
              Map<String, dynamic>.from((m['timeOff'] as Map?) ?? const {});
          return ClassroomItem(
            id: m['id']?.toString(),
            name: m['name']?.toString() ?? '',
            roomType: m['roomType']?.toString() ?? 'standard',
            abbr: m['abbr']?.toString(),
            buildingName: m['buildingName']?.toString(),
            capacity: (m['capacity'] as num?)?.toInt(),
            color: m['color']?.toString(),
            groupId: m['groupId']?.toString(),
            assignedTeacherIds: ((m['assignedTeacherIds'] as List?) ?? const [])
                .map((e) => e.toString())
                .toList(),
            assignedClassIds: ((m['assignedClassIds'] as List?) ?? const [])
                .map((e) => e.toString())
                .toList(),
            timeOff: rawOff.map((k, v) {
              final idx = (v as num?)?.toInt();
              final state =
                  (idx != null && idx >= 0 && idx < TimeOffState.values.length)
                      ? TimeOffState.values[idx]
                      : TimeOffState.available;
              return MapEntry(k, state);
            }),
          );
        }));

      lessons
        ..clear()
        ..addAll((((snap['lessons'] as List?) ?? const []))
            .whereType<Map<String, dynamic>>()
            .map((m) {
          return LessonSpec(
            id: m['id']?.toString() ?? "LS_hydrated",
            subjectId: m['subjectId']?.toString() ?? '',
            teacherIds: ((m['teacherIds'] as List?) ?? const [])
                .map((x) => x.toString())
                .toList(),
            classIds: ((m['classIds'] as List?) ?? const [])
                .map((x) => x.toString())
                .toList(),
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

      // Restore generation state from DB: if any cards exist, a timetable was generated.
      final existingCards = await _db!.select(_db!.cards).get();
      _hasGeneratedTimetable = existingCards.isNotEmpty;
      _scheduledLessonCount = existingCards.length;

      hydrated = true;
      notifyListeners();
      debugPrint('--- HYDRATE FINISHED (SUCCESS) ---');
    });
  }

  Future<void> _persist() async {
    await _lock.synchronized(() async {
      final json = <String, dynamic>{
        'draftName': draftName,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'sessionName': sessionName,
        'sessionStartDate': sessionStartDate,
        'sessionEndDate': sessionEndDate,
        'schoolName': schoolName,
        'workingDays': workingDays,
        'softWeights': softWeights,
        'cardRelationships': cardRelationships.map((r) => r.toJson()).toList(),
        'bellTimes': bellTimes,
        'scheduleEntries': scheduleEntries.map((e) => e.toJson()).toList(),
        'subjects': subjects
            .map((s) => {
                  'id': s.id,
                  'name': s.name,
                  'abbr': s.abbr,
                  'color': s.color,
                  'relationshipGroupKey': s.relationshipGroupKey,
                  'timeOff': s.timeOff.map((k, v) => MapEntry(k, v.index)),
                })
            .toList(),
        'classes': classes
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'abbr': c.abbr,
                  'color': c.color,
                  'classTeacherId': c.classTeacherId,
                  'timeOff': c.timeOff.map((k, v) => MapEntry(k, v.index)),
                })
            .toList(),
        'divisions': divisions
            .map((d) => {
                  'id': d.id,
                  'classId': d.classId,
                  'name': d.name,
                  'code': d.code
                })
            .toList(),
        'teachers': teachers
            .map((t) => {
                  'id': t.id,
                  'firstName': t.firstName,
                  'lastName': t.lastName,
                  'abbr': t.abbr,
                  'color': t.color,
                  'maxGapsPerDay': t.maxGapsPerDay,
                  'maxConsecutivePeriods': t.maxConsecutivePeriods,
                  'timeOff': t.timeOff.map((k, v) => MapEntry(k, v.index)),
                  'email': t.email,
                  'phone': t.phone,
                  'designation': t.designation,
                })
            .toList(),
        'classrooms': classrooms
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'roomType': r.roomType,
                  'abbr': r.abbr,
                  'buildingName': r.buildingName,
                  'capacity': r.capacity,
                  'color': r.color,
                  'groupId': r.groupId,
                  'assignedTeacherIds': r.assignedTeacherIds,
                  'assignedClassIds': r.assignedClassIds,
                  'timeOff': r.timeOff.map((k, v) => MapEntry(k, v.index)),
                })
            .toList(),
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
        dbId = await db.savePlannerSnapshot(json, dbId);
      }
    });
  }

  Future<void> _touch() async {
    notifyListeners();
    await _persist();
  }

  String _randomGuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hx(int x) => x.toRadixString(16).padLeft(2, '0');
    final h = b.map(hx).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  Future<void> pinLessonToSlot({
    required String lessonId,
    required int day,
    required int period,
  }) async {
    await _lock.synchronized(() async {
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
    });
  }

  bool get hasMinimumData =>
      subjects.isNotEmpty && classes.isNotEmpty && teachers.isNotEmpty;

  /// Tracks whether a timetable has been generated in this session.
  bool _hasGeneratedTimetable = false;
  bool get hasGeneratedTimetable => _hasGeneratedTimetable;

  DateTime? _lastGeneratedAt;
  DateTime? get lastGeneratedAt => _lastGeneratedAt;

  int _scheduledLessonCount = 0;
  int get scheduledLessonCount => _scheduledLessonCount;

  void markTimetableGenerated({int scheduledCount = 0}) {
    _hasGeneratedTimetable = true;
    _lastGeneratedAt = DateTime.now();
    _scheduledLessonCount = scheduledCount;
    notifyListeners();
  }

  Map<String, dynamic> toSolverPayload() {
    final solverLessons = <Map<String, dynamic>>[];
    final lessonClassesRows =
        <Map<String, dynamic>>[]; // emulates junction table writes

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
      'timeoutMs': 60000,
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
        'softWeights': softWeights,
        'cardRelationships': cardRelationships.map((r) => r.toJson()).toList(),
      },
      'debug': {
        'lessonClassesRows': lessonClassesRows,
      }
    };
  }
}
