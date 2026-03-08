import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;

import '../database.dart';

class TeacherImportDto {
  final String id;
  final String name;
  final String abbreviation;
  final int? maxPeriodsPerDay;
  final int? maxGapsPerDay;

  const TeacherImportDto({
    required this.id,
    required this.name,
    required this.abbreviation,
    this.maxPeriodsPerDay,
    this.maxGapsPerDay,
  });
}

class SubjectImportDto {
  final String id;
  final String name;
  final String abbr;
  final String? groupId;
  final int? roomTypeId;

  const SubjectImportDto({
    required this.id,
    required this.name,
    required this.abbr,
    this.groupId,
    this.roomTypeId,
  });
}

class ClassImportDto {
  final String id;
  final String name;
  final String abbr;

  const ClassImportDto({
    required this.id,
    required this.name,
    required this.abbr,
  });
}

class LessonImportDto {
  final String id;
  final String subjectId;
  final int periodsPerWeek;
  final List<String> teacherIds;
  final List<String> classIds;

  const LessonImportDto({
    required this.id,
    required this.subjectId,
    required this.periodsPerWeek,
    required this.teacherIds,
    required this.classIds,
  });
}

class BulkImportBundle {
  final List<TeacherImportDto> teachers;
  final List<SubjectImportDto> subjects;
  final List<ClassImportDto> classes;
  final List<LessonImportDto> lessons;

  const BulkImportBundle({
    required this.teachers,
    required this.subjects,
    required this.classes,
    this.lessons = const [],
  });
}

class BulkImportService {
  /// Parses CSV bytes into strongly typed DTOs.
  /// Expected headers:
  /// type,id,name,abbr,max_periods_per_day,max_gaps_per_day,group_id,room_type_id
  ///
  /// type values: teacher | subject | class
  BulkImportBundle parseCsv(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(text);
    if (rows.isEmpty) {
      return const BulkImportBundle(teachers: [], subjects: [], classes: [], lessons: []);
    }

    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final idx = <String, int>{
      for (int i = 0; i < header.length; i++) header[i]: i,
    };

    String value(List<dynamic> row, String key) {
      final i = idx[key];
      if (i == null || i < 0 || i >= row.length) return '';
      return row[i].toString().trim();
    }

    final teachers = <TeacherImportDto>[];
    final subjects = <SubjectImportDto>[];
    final classes = <ClassImportDto>[];

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      final type = value(row, 'type').toLowerCase();
      if (type.isEmpty) continue;

      if (type == 'teacher') {
        final id = value(row, 'id');
        final name = value(row, 'name');
        final abbr = value(row, 'abbr');
        if (id.isEmpty || name.isEmpty || abbr.isEmpty) continue;

        teachers.add(TeacherImportDto(
          id: id,
          name: name,
          abbreviation: abbr,
          maxPeriodsPerDay: int.tryParse(value(row, 'max_periods_per_day')),
          maxGapsPerDay: int.tryParse(value(row, 'max_gaps_per_day')),
        ));
      } else if (type == 'subject') {
        final id = value(row, 'id');
        final name = value(row, 'name');
        final abbr = value(row, 'abbr');
        if (id.isEmpty || name.isEmpty || abbr.isEmpty) continue;

        final groupId = value(row, 'group_id');
        final roomTypeRaw = value(row, 'room_type_id');
        final roomTypeId = int.tryParse(roomTypeRaw);

        subjects.add(SubjectImportDto(
          id: id,
          name: name,
          abbr: abbr,
          groupId: groupId.isEmpty ? null : groupId,
          roomTypeId: roomTypeId,
        ));
      } else if (type == 'class') {
        final id = value(row, 'id');
        final name = value(row, 'name');
        final abbr = value(row, 'abbr');
        if (id.isEmpty || name.isEmpty || abbr.isEmpty) continue;

        classes.add(ClassImportDto(id: id, name: name, abbr: abbr));
      }
    }

    return BulkImportBundle(
      teachers: teachers,
      subjects: subjects,
      classes: classes,
      lessons: const [],
    );
  }

  /// Parses aSc `contracts.xlsx` exported-as-CSV rows.
  /// Header expected: Teacher,Class,Group,Subject,Length,Count,Available classrooms,Week,More teachers,Classrooms
  BulkImportBundle parseAscContractsCsv(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(text);
    if (rows.isEmpty) {
      return const BulkImportBundle(teachers: [], subjects: [], classes: [], lessons: []);
    }

    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final idx = <String, int>{for (int i = 0; i < header.length; i++) header[i]: i};

    String value(List<dynamic> row, String key) {
      final i = idx[key];
      if (i == null || i < 0 || i >= row.length) return '';
      return row[i].toString().trim();
    }

    List<String> splitNames(String raw) => raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final lessons = <LessonImportDto>[];

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      final teacher = value(row, 'teacher');
      final moreTeachers = value(row, 'more teachers');
      final className = value(row, 'class');
      final subject = value(row, 'subject');
      final countRaw = value(row, 'count');

      if (subject.isEmpty || className.isEmpty) continue;

      final teacherNames = <String>{
        ...splitNames(teacher),
        ...splitNames(moreTeachers),
      }.toList(growable: false);

      final periodsPerWeek = int.tryParse(countRaw) ??
          (double.tryParse(countRaw)?.toInt() ?? 1);

      lessons.add(
        LessonImportDto(
          id: 'ASC_CONTRACT_${r + 1}',
          subjectId: subject,
          periodsPerWeek: periodsPerWeek,
          teacherIds: teacherNames,
          classIds: [className],
        ),
      );
    }

    return BulkImportBundle(
      teachers: const [],
      subjects: const [],
      classes: const [],
      lessons: lessons,
    );
  }

  /// Atomic high-throughput insert path.
  /// Inserts up to thousands of rows in one SQLite transaction to avoid UI lag.
  Future<void> batchInsert(AppDatabase db, BulkImportBundle bundle) async {
    await db.transaction(() async {
      if (bundle.subjects.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.subjects,
            bundle.subjects
                .map(
                  (s) => SubjectsCompanion.insert(
                    id: s.id,
                    name: s.name,
                    abbr: s.abbr,
                    groupId: Value(s.groupId),
                    roomTypeId: Value(s.roomTypeId),
                  ),
                )
                .toList(),
          );
        });
      }

      if (bundle.classes.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.classes,
            bundle.classes
                .map(
                  (c) => ClassesCompanion.insert(
                    id: c.id,
                    name: c.name,
                    abbr: c.abbr,
                  ),
                )
                .toList(),
          );
        });
      }

      if (bundle.teachers.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.teachers,
            bundle.teachers
                .map(
                  (t) => TeachersCompanion.insert(
                    id: t.id,
                    name: t.name,
                    abbreviation: t.abbreviation,
                    maxPeriodsPerDay: Value(t.maxPeriodsPerDay),
                    maxGapsPerDay: Value(t.maxGapsPerDay),
                  ),
                )
                .toList(),
          );
        });
      }

      if (bundle.lessons.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.lessons,
            bundle.lessons
                .map(
                  (l) => LessonsCompanion.insert(
                    id: l.id,
                    subjectId: l.subjectId,
                    periodsPerWeek: Value(l.periodsPerWeek),
                    teacherIds: Value(l.teacherIds),
                    classIds: Value(l.classIds),
                  ),
                )
                .toList(),
          );
        });
      }
    });
  }
}
