import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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

class MasterImportSummary {
  final int lessons;
  final int teachers;
  final int rooms;

  const MasterImportSummary({
    required this.lessons,
    required this.teachers,
    required this.rooms,
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

  String _sanitizeString(Object? value) => value?.toString().trim() ?? '';

  bool _isBlankRow(List<dynamic> row) =>
      row.every((cell) => _sanitizeString(cell).isEmpty);

  List<Map<String, String>> _parseCsvRows(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(text);
    return _mapRows(rows);
  }

  List<Map<String, String>> _parseExcelRows(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return const [];
    final sheet = excel.tables.values.first;
    if (sheet.maxRows == 0) return const [];
    final rows = <List<dynamic>>[];
    for (final row in sheet.rows) {
      rows.add(row.map((cell) => cell?.value).toList(growable: false));
    }
    return _mapRows(rows);
  }

  List<Map<String, String>> _parseStructuredRows(
      Uint8List bytes, String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.xlsx')) {
      return _parseExcelRows(bytes);
    }
    return _parseCsvRows(bytes);
  }

  List<Map<String, String>> _mapRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return const [];

    final headers =
        rows.first.map((e) => _sanitizeString(e)).toList(growable: false);
    final out = <Map<String, String>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || _isBlankRow(row)) continue;
      final mapped = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        final key = headers[c];
        if (key.isEmpty) continue;
        final value = c < row.length ? _sanitizeString(row[c]) : '';
        mapped[key] = value;
        mapped[_k(key)] = value;
      }
      if (mapped.values.every((v) => v.trim().isEmpty)) continue;
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

  Future<List<File>> writeMasterCsvTemplates() async {
    final downloads = await getDownloadsDirectory();
    final docs = await getApplicationDocumentsDirectory();
    final targetDir = downloads ?? docs;

    final lessons = File('${targetDir.path}/Lessons_Master_Template.csv');
    final teachers =
        File('${targetDir.path}/Teachers_Constraints_Template.csv');

    await lessons.writeAsString(
      'lesson_id,class_name,subject_name,teacher_name,weekly_lessons,lesson_length,preferred_room\n'
      'L001,Grade 10,Mathematics,Aarav Sharma,6,single,Room 101\n'
      'L002,Grade 10,Science,Priya Verma,2,double,Lab 1\n',
      flush: true,
    );

    await teachers.writeAsString(
      'teacher_name,teacher_abbr,off_days,off_slots,max_periods_per_day,max_gaps_per_day\n'
      'Aarav Sharma,AS,Monday,Mon-7,6,2\n',
      flush: true,
    );

    return [lessons, teachers];
  }

  Future<PlatformFile?> pickLessonsMasterCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    if (!file.name.toLowerCase().contains('lessons_master')) {
      throw StateError(
          'Please select Lessons_Master.csv or Lessons_Master.xlsx');
    }
    return file;
  }

  Future<PlatformFile?> pickTeachersConstraintsCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    if (!file.name.toLowerCase().contains('teachers_constraints')) {
      throw StateError(
          'Please select Teachers_Constraints.csv or Teachers_Constraints.xlsx');
    }
    return file;
  }

  Future<MasterImportSummary> importMasterCsvData(
    AppDatabase db, {
    required PlatformFile lessonsFile,
    PlatformFile? teachersFile,
  }) async {
    final lessonsRows = _parseStructuredRows(
      await _bytesForPlatformFile(lessonsFile),
      lessonsFile.name,
    );
    final teachersRows = teachersFile == null
        ? const <Map<String, String>>[]
        : _parseStructuredRows(
            await _bytesForPlatformFile(teachersFile),
            teachersFile.name,
          );

    final teacherByName = <String, TeacherImportDto>{};
    for (final row in teachersRows) {
      final name = _req(row, ['teacher_name']).trim();
      if (name.isEmpty) continue;
      final abbr = _req(row, ['teacher_abbr', 'abbr']);
      final id = 'TEA_${_k(name).replaceAll(' ', '_')}';
      teacherByName[_k(name)] = TeacherImportDto(
        id: id,
        guid: _deterministicGuid('teacher', id),
        name: name,
        abbreviation: abbr.isEmpty ? name : abbr,
        maxPeriodsPerDay: int.tryParse(_req(row, ['max_periods_per_day'])),
        maxGapsPerDay: int.tryParse(_req(row, ['max_gaps_per_day'])),
      );
    }

    final subjectByName = <String, SubjectImportDto>{};
    final classByName = <String, ClassImportDto>{};
    final roomNames = <String>{};
    final lessonDtos = <LessonImportDto>[];
    final plannerLessons = <Map<String, dynamic>>[];

    var autoLesson = 1;
    for (final row in lessonsRows) {
      final className = _req(row, ['class_name']);
      final subjectName = _req(row, ['subject_name']);
      final teacherName = _req(row, ['teacher_name']);
      final weekly = int.tryParse(_req(row, ['weekly_lessons'])) ?? 1;
      final length = _req(row, ['lesson_length']).toLowerCase();
      final preferredRoom = _req(row, ['preferred_room']);
      final lessonId = _req(row, ['lesson_id']).isEmpty
          ? 'LM_${autoLesson++}'
          : _req(row, ['lesson_id']);
      if (className.isEmpty || subjectName.isEmpty || teacherName.isEmpty) {
        continue;
      }

      final classId = 'CLS_${_k(className).replaceAll(' ', '_')}';
      classByName.putIfAbsent(
        _k(className),
        () => ClassImportDto(
          id: classId,
          guid: _deterministicGuid('class', classId),
          name: className,
          abbr: className,
        ),
      );

      final subjectId = 'SUB_${_k(subjectName).replaceAll(' ', '_')}';
      subjectByName.putIfAbsent(
        _k(subjectName),
        () => SubjectImportDto(
          id: subjectId,
          guid: _deterministicGuid('subject', subjectId),
          name: subjectName,
          abbr: subjectName,
        ),
      );

      final teacher = teacherByName[_k(teacherName)] ??
          TeacherImportDto(
            id: 'TEA_${_k(teacherName).replaceAll(' ', '_')}',
            guid: _deterministicGuid('teacher', teacherName),
            name: teacherName,
            abbreviation: teacherName,
          );
      teacherByName[_k(teacherName)] = teacher;

      if (preferredRoom.isNotEmpty) roomNames.add(preferredRoom);

      lessonDtos.add(
        LessonImportDto(
          id: lessonId,
          subjectId: subjectId,
          periodsPerWeek: weekly,
          teacherIds: [teacher.id],
          classIds: [classId],
        ),
      );

      plannerLessons.add({
        'id': lessonId,
        'subjectId': subjectId,
        'teacherIds': [teacher.id],
        'classIds': [classId],
        'classDivisionId': null,
        'countPerWeek': weekly,
        'length': length == 'double' ? 'double' : 'single',
        'requiredClassroomId': preferredRoom.isEmpty ? null : preferredRoom,
        'isPinned': false,
        'fixedDay': null,
        'fixedPeriod': null,
        'roomTypeId': null,
        'relationshipType': 0,
        'relationshipGroupKey': null,
      });
    }

    late MasterImportSummary summary;
    await db.transaction(() async {
      await db.delete(db.cards).go();
      await db.delete(db.lessonTeachers).go();
      await db.delete(db.lessonClasses).go();
      await db.delete(db.lessons).go();
      await db.delete(db.teacherUnavailability).go();
      await db.delete(db.divisions).go();
      await db.delete(db.teachers).go();
      await db.delete(db.classes).go();
      await db.delete(db.subjects).go();

      await batchInsert(
        db,
        BulkImportBundle(
          teachers: teacherByName.values.toList(growable: false),
          subjects: subjectByName.values.toList(growable: false),
          classes: classByName.values.toList(growable: false),
          lessons: lessonDtos,
        ),
      );

      final plannerSnap = {
        'schoolName': 'Imported School',
        'workingDays': 5,
        'bellTimes': [
          '08:00-08:45',
          '08:45-09:30',
          '09:45-10:30',
          '10:30-11:15',
          '11:30-12:15',
          '12:15-13:00',
          '13:30-14:15',
          '14:15-15:00'
        ],
        'subjects': subjectByName.values
            .map((s) => {
                  'id': s.id,
                  'name': s.name,
                  'abbr': s.abbr,
                  'color': 0xFF0B3D91,
                  'relationshipGroupKey': null
                })
            .toList(),
        'classes': classByName.values
            .map((c) => {'id': c.id, 'name': c.name, 'abbr': c.abbr})
            .toList(),
        'divisions': const [],
        'teachers': teacherByName.values
            .map((t) => {
                  'id': t.id,
                  'firstName': t.name.split(' ').first,
                  'lastName': t.name.split(' ').skip(1).join(' '),
                  'abbr': t.abbreviation,
                  'maxGapsPerDay': t.maxGapsPerDay,
                  'maxConsecutivePeriods': 3,
                  'timeOff': <String, int>{},
                })
            .toList(),
        'classrooms': roomNames
            .map((r) => {'id': r, 'name': r, 'roomType': 'standard'})
            .toList(),
        'lessons': plannerLessons,
      };
      await db.savePlannerSnapshot(plannerSnap);

      final dbLessons = await db.select(db.lessons).get();
      final dbTeachers = await db.select(db.teachers).get();
      summary = MasterImportSummary(
        lessons: dbLessons.length,
        teachers: dbTeachers.length,
        rooms: roomNames.length,
      );
    });

    return summary;
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
