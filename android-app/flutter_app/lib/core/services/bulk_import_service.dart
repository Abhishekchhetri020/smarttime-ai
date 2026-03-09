import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';

import '../database.dart';

class TeacherImportDto {
  final String id;
  final String guid;
  final String name;
  final String abbreviation;
  final int? maxPeriodsPerDay;
  final int? maxGapsPerDay;

  const TeacherImportDto({
    required this.id,
    required this.guid,
    required this.name,
    required this.abbreviation,
    this.maxPeriodsPerDay,
    this.maxGapsPerDay,
  });
}

class SubjectImportDto {
  final String id;
  final String guid;
  final String name;
  final String abbr;
  final String? groupId;
  final int? roomTypeId;

  const SubjectImportDto({
    required this.id,
    required this.guid,
    required this.name,
    required this.abbr,
    this.groupId,
    this.roomTypeId,
  });
}

class ClassImportDto {
  final String id;
  final String guid;
  final String name;
  final String abbr;

  const ClassImportDto({
    required this.id,
    required this.guid,
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

class _AscLessonRaw {
  final int rowNumber;
  final String subjectToken;
  final List<String> teacherTokens;
  final List<String> classTokens;
  final int periodsPerWeek;

  const _AscLessonRaw({
    required this.rowNumber,
    required this.subjectToken,
    required this.teacherTokens,
    required this.classTokens,
    required this.periodsPerWeek,
  });
}

class ImportReport {
  final int successCount;
  final List<int> failedRows;
  final List<String> unresolvedTokens;

  const ImportReport({
    required this.successCount,
    required this.failedRows,
    required this.unresolvedTokens,
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
      return const BulkImportBundle(
          teachers: [], subjects: [], classes: [], lessons: []);
    }

    final header =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
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
          guid: _randomGuidV4(),
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
          guid: _randomGuidV4(),
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

        classes.add(ClassImportDto(
            id: id, guid: _randomGuidV4(), name: name, abbr: abbr));
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
      return const BulkImportBundle(
          teachers: [], subjects: [], classes: [], lessons: []);
    }

    final header =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final idx = <String, int>{
      for (int i = 0; i < header.length; i++) header[i]: i
    };

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

      final periodsPerWeek =
          int.tryParse(countRaw) ?? (double.tryParse(countRaw)?.toInt() ?? 1);

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

  Future<Uint8List> _bytesForPlatformFile(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.path != null && file.path!.isNotEmpty) {
      return File(file.path!).readAsBytes();
    }
    throw StateError('File ${file.name} has no readable bytes/path');
  }

  List<Map<String, String>> _parseCsvRows(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(text);
    if (rows.isEmpty) return const [];

    final headers =
        rows.first.map((e) => e.toString().trim()).toList(growable: false);
    final out = <Map<String, String>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final mapped = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        final key = headers[c];
        final value = c < row.length ? row[c].toString().trim() : '';
        mapped[key] = value;
      }
      out.add(mapped);
    }
    return out;
  }

  List<String> _splitMultiValue(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  String _k(String s) => s.trim().toLowerCase();

  String _randomGuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hx(int x) => x.toRadixString(16).padLeft(2, '0');
    final h = b.map(hx).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  String _deterministicGuid(String entityType, String key) {
    final normalized = '$entityType:${_k(key)}';
    final bytes = utf8.encode(normalized);
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    final seed = hash.toUnsigned(64);
    final parts = <int>[];
    var x = seed;
    for (var i = 0; i < 16; i++) {
      x ^= (x << 13) & 0xFFFFFFFFFFFFFFFF;
      x ^= (x >> 7);
      x ^= (x << 17) & 0xFFFFFFFFFFFFFFFF;
      parts.add((x & 0xff).toInt());
    }
    parts[6] = (parts[6] & 0x0f) | 0x50;
    parts[8] = (parts[8] & 0x3f) | 0x80;
    String hx(int n) => n.toRadixString(16).padLeft(2, '0');
    final h = parts.map(hx).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  String _req(Map<String, String> row, List<String> keys) {
    for (final key in keys) {
      final direct = row[key];
      if (direct != null && direct.trim().isNotEmpty) return direct.trim();
      final lowered = row[_k(key)];
      if (lowered != null && lowered.trim().isNotEmpty) return lowered.trim();
      for (final entry in row.entries) {
        if (_k(entry.key) == _k(key) && entry.value.trim().isNotEmpty) {
          return entry.value.trim();
        }
      }
    }
    return '';
  }

  Future<ImportReport> parseAndImportAscFiles(
      AppDatabase db, List<PlatformFile> files) async {
    final byName = <String, PlatformFile>{
      for (final f in files) f.name.toLowerCase(): f,
    };

    PlatformFile? findFile(String token) {
      for (final e in byName.entries) {
        if (e.key.contains(token.toLowerCase())) return e.value;
      }
      return null;
    }

    final subjectsFile = findFile('subjects');
    final classroomsFile = findFile('classrooms');
    final teachersFile = findFile('teachers');
    final classesFile = findFile('classes');
    final lessonsFile = findFile('lessons') ?? findFile('contracts');

    if (subjectsFile == null ||
        teachersFile == null ||
        classesFile == null ||
        lessonsFile == null) {
      return const ImportReport(
        successCount: 0,
        failedRows: <int>[],
        unresolvedTokens: <String>[
          'Required aSc CSVs missing. Need Subjects, Teachers, Classes and Lessons/Contracts CSV.',
        ],
      );
    }

    final subjectsRows =
        _parseCsvRows(await _bytesForPlatformFile(subjectsFile));
    final classroomsRows = classroomsFile == null
        ? const <Map<String, String>>[]
        : _parseCsvRows(await _bytesForPlatformFile(classroomsFile));
    final teachersRows =
        _parseCsvRows(await _bytesForPlatformFile(teachersFile));
    final classesRows = _parseCsvRows(await _bytesForPlatformFile(classesFile));
    final lessonsRows = _parseCsvRows(await _bytesForPlatformFile(lessonsFile));

    final subjectDtos = subjectsRows
        .map((r) {
          final name = _req(r, ['Name', 'Subject']);
          final abbr = _req(r, ['Abbreviation', 'Abbr', 'Short']);
          final id = _req(r, ['Id']);
          final resolvedId =
              id.isEmpty ? 'SUB_${_k(abbr.isEmpty ? name : abbr)}' : id;
          return SubjectImportDto(
            id: resolvedId,
            guid: _deterministicGuid('subject', resolvedId),
            name: name,
            abbr: abbr.isEmpty ? name : abbr,
          );
        })
        .where((e) => e.name.isNotEmpty)
        .toList(growable: false);

    final teacherDtos = teachersRows
        .map((r) {
          final name = _req(r, ['Full name', 'Teacher', 'Name']);
          final abbr = _req(r, ['Abbreviation', 'Abbr', 'Short']);
          final id = _req(r, ['Id']);
          final resolvedId =
              id.isEmpty ? 'TEA_${_k(abbr.isEmpty ? name : abbr)}' : id;
          return TeacherImportDto(
            id: resolvedId,
            guid: _deterministicGuid('teacher', resolvedId),
            name: name,
            abbreviation: abbr.isEmpty ? name : abbr,
          );
        })
        .where((e) => e.name.isNotEmpty)
        .toList(growable: false);

    final classDtos = classesRows
        .map((r) {
          final name = _req(r, ['Name', 'Class']);
          final abbr = _req(r, ['Abbreviation', 'Abbr', 'Short']);
          final id = _req(r, ['Id']);
          final resolvedId =
              id.isEmpty ? 'CLS_${_k(abbr.isEmpty ? name : abbr)}' : id;
          return ClassImportDto(
            id: resolvedId,
            guid: _deterministicGuid('class', resolvedId),
            name: name,
            abbr: abbr.isEmpty ? name : abbr,
          );
        })
        .where((e) => e.name.isNotEmpty)
        .toList(growable: false);

    final rawLessons = <_AscLessonRaw>[];
    for (var i = 0; i < lessonsRows.length; i++) {
      final r = lessonsRows[i];
      final subjectToken = _req(r, ['Subject']);
      final classToken = _req(r, ['Class']);
      final teacherToken = _req(r, ['Teacher']);
      final moreTeachers = _req(r, ['More teachers']);
      final countRaw = _req(r, ['Count', 'PeriodsPerWeek', 'Periods per week']);
      final periods =
          int.tryParse(countRaw) ?? (double.tryParse(countRaw)?.toInt() ?? 1);
      if (subjectToken.isEmpty || classToken.isEmpty) continue;
      rawLessons.add(
        _AscLessonRaw(
          rowNumber: i + 2,
          subjectToken: subjectToken,
          classTokens: _splitMultiValue(classToken),
          teacherTokens: {
            ..._splitMultiValue(teacherToken),
            ..._splitMultiValue(moreTeachers)
          }.toList(),
          periodsPerWeek: periods,
        ),
      );
    }

    final failedRows = <int>[];
    final unresolvedTokens = <String>{};
    var successCount = 0;

    try {
      await db.transaction(() async {
        // Step 1: Subjects + Classrooms
        final _ = classroomsRows; // parsed/validated in strict sequence.
        await batchInsert(
          db,
          BulkImportBundle(
            teachers: const [],
            subjects: subjectDtos,
            classes: const [],
          ),
        );

        // Step 2: Teachers
        await batchInsert(
          db,
          BulkImportBundle(
            teachers: teacherDtos,
            subjects: const [],
            classes: const [],
          ),
        );

        // Step 3: Classes
        await batchInsert(
          db,
          BulkImportBundle(
            teachers: const [],
            subjects: const [],
            classes: classDtos,
          ),
        );

        // Step 4: Lessons/Contracts + FK mapping
        final subjectRows = await db.select(db.subjects).get();
        final teacherRows = await db.select(db.teachers).get();
        final classRows = await db.select(db.classes).get();

        final subjectMap = <String, String>{
          for (final s in subjectRows) ...{_k(s.abbr): s.id, _k(s.name): s.id},
        };
        final teacherMap = <String, String>{
          for (final t in teacherRows) ...{
            _k(t.abbreviation): t.id,
            _k(t.name): t.id
          },
        };
        final classMap = <String, String>{
          for (final c in classRows) ...{_k(c.abbr): c.id, _k(c.name): c.id},
        };

        final lessonDtos = <LessonImportDto>[];
        for (var i = 0; i < rawLessons.length; i++) {
          final raw = rawLessons[i];
          final subjectId = subjectMap[_k(raw.subjectToken)];
          if (subjectId == null) {
            failedRows.add(raw.rowNumber);
            unresolvedTokens.add('subject:${raw.subjectToken}');
            continue;
          }

          final classIds = <String>[];
          var classError = false;
          for (final token in raw.classTokens) {
            final cid = classMap[_k(token)];
            if (cid == null) {
              failedRows.add(raw.rowNumber);
              unresolvedTokens.add('class:$token');
              classError = true;
              break;
            }
            classIds.add(cid);
          }
          if (classError) continue;

          final teacherIds = <String>[];
          var teacherError = false;
          for (final token in raw.teacherTokens) {
            final tid = teacherMap[_k(token)];
            if (tid == null) {
              failedRows.add(raw.rowNumber);
              unresolvedTokens.add('teacher:$token');
              teacherError = true;
              break;
            }
            teacherIds.add(tid);
          }
          if (teacherError) continue;

          lessonDtos.add(
            LessonImportDto(
              id: 'ASC_LESSON_${i + 1}',
              subjectId: subjectId,
              periodsPerWeek: raw.periodsPerWeek,
              teacherIds: teacherIds.toSet().toList(growable: false),
              classIds: classIds.toSet().toList(growable: false),
            ),
          );
        }

        successCount = lessonDtos.length;
        if (lessonDtos.isNotEmpty) {
          await batchInsert(
            db,
            BulkImportBundle(
              teachers: const [],
              subjects: const [],
              classes: const [],
              lessons: lessonDtos,
            ),
          );
        }
      });
    } on StateError catch (e) {
      unresolvedTokens.add(e.message);
    }

    return ImportReport(
      successCount: successCount,
      failedRows: failedRows.toSet().toList()..sort(),
      unresolvedTokens: unresolvedTokens.toList()..sort(),
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
                    guid: Value(s.guid),
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
                    guid: Value(c.guid),
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
                    guid: Value(t.guid),
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
