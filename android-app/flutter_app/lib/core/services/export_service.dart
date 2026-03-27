import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database.dart';

class ExportService {
  Future<File> exportSmarttimeFile(AppDatabase db) async {
    final subjects = await db.select(db.subjects).get();
    final classes = await db.select(db.classes).get();
    final teachers = await db.select(db.teachers).get();
    final lessons = await db.select(db.lessons).get();
    final cards = await db.select(db.cards).get();

    final payload = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'subjects': subjects
          .map((s) => {
                'id': s.id,
                'guid': s.guid,
                'name': s.name,
                'abbr': s.abbr,
                'groupId': s.groupId,
                'roomTypeId': s.roomTypeId,
                'color': s.color,
              })
          .toList(growable: false),
      'classes': classes
          .map((c) => {
                'id': c.id,
                'guid': c.guid,
                'name': c.name,
                'abbr': c.abbr,
              })
          .toList(growable: false),
      'teachers': teachers
          .map((t) => {
                'id': t.id,
                'guid': t.guid,
                'name': t.name,
                'abbreviation': t.abbreviation,
                'maxPeriodsPerDay': t.maxPeriodsPerDay,
                'maxGapsPerDay': t.maxGapsPerDay,
              })
          .toList(growable: false),
      'lessons': lessons
          .map((l) => {
                'id': l.id,
                'subjectId': l.subjectId,
                'periodsPerWeek': l.periodsPerWeek,
                'teacherIds': l.teacherIds,
                'classIds': l.classIds,
                'classId': l.classId,
                'classDivisionId': l.classDivisionId,
                'isPinned': l.isPinned,
                'fixedDay': l.fixedDay,
                'fixedPeriod': l.fixedPeriod,
                'roomTypeId': l.roomTypeId,
                'relationshipType': l.relationshipType,
                'relationshipGroupKey': l.relationshipGroupKey,
              })
          .toList(growable: false),
      'cards': cards
          .map((c) => {
                'id': c.id,
                'lessonId': c.lessonId,
                'dayIndex': c.dayIndex,
                'periodIndex': c.periodIndex,
                'roomId': c.roomId,
              })
          .toList(growable: false),
    };

    final jsonBytes = utf8.encode(jsonEncode(payload));
    final gzBytes = GZipCodec().encode(jsonBytes);

    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/school_schedule.smarttime');
    await file.writeAsBytes(gzBytes, flush: true);
    return file;
  }

  Future<void> shareSmarttimeFile(AppDatabase db) async {
    final file = await exportSmarttimeFile(db);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/octet-stream')],
      text: 'SmartTime schedule export (.smarttime)',
    );
  }

  Future<void> importSmarttimeFromPicker(AppDatabase db) async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
    } on PlatformException catch (e) {
      throw StateError(
          'File picker unavailable on this device: ${e.message ?? e.code}');
    }

    if (picked == null || picked.files.isEmpty) return;

    final f = picked.files.first;
    if (!f.name.toLowerCase().endsWith('.smarttime')) {
      throw StateError('Please select a .smarttime file');
    }

    List<int>? bytes;
    try {
      if (f.bytes != null) {
        bytes = f.bytes!;
      } else if (f.path != null && f.path!.isNotEmpty) {
        bytes = await File(f.path!).readAsBytes();
      }
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) throw StateError('Selected file is not readable');

    final raw = GZipCodec().decode(bytes);
    final map = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;

    final subjects = ((map['subjects'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final classes = ((map['classes'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final teachers = ((map['teachers'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final lessons = ((map['lessons'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final cards = ((map['cards'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

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

      if (subjects.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.subjects,
            subjects
                .map(
                  (s) => SubjectsCompanion.insert(
                    id: s['id'].toString(),
                    guid: Value(s['guid']?.toString()),
                    name: s['name']?.toString() ?? '',
                    abbr: s['abbr']?.toString() ?? '',
                    groupId: Value(s['groupId']?.toString()),
                    roomTypeId: Value((s['roomTypeId'] as num?)?.toInt()),
                    color: Value((s['color'] as num?)?.toInt() ?? 0xFF4F46E5),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (classes.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.classes,
            classes
                .map(
                  (c) => ClassesCompanion.insert(
                    id: c['id'].toString(),
                    guid: Value(c['guid']?.toString()),
                    name: c['name']?.toString() ?? '',
                    abbr: c['abbr']?.toString() ?? '',
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (teachers.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.teachers,
            teachers
                .map(
                  (t) => TeachersCompanion.insert(
                    id: t['id'].toString(),
                    guid: Value(t['guid']?.toString()),
                    name: t['name']?.toString() ?? '',
                    abbreviation: t['abbreviation']?.toString() ?? '',
                    maxPeriodsPerDay:
                        Value((t['maxPeriodsPerDay'] as num?)?.toInt()),
                    maxGapsPerDay: Value((t['maxGapsPerDay'] as num?)?.toInt()),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (lessons.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.lessons,
            lessons
                .map(
                  (l) => LessonsCompanion.insert(
                    id: l['id'].toString(),
                    subjectId: l['subjectId'].toString(),
                    periodsPerWeek:
                        Value((l['periodsPerWeek'] as num?)?.toInt() ?? 1),
                    teacherIds: Value(((l['teacherIds'] as List?) ?? const [])
                        .map((e) => e.toString())
                        .toList()),
                    classIds: Value(((l['classIds'] as List?) ?? const [])
                        .map((e) => e.toString())
                        .toList()),
                    classId: Value(l['classId']?.toString()),
                    classDivisionId: Value(l['classDivisionId']?.toString()),
                    isPinned: Value(l['isPinned'] == true),
                    fixedDay: Value((l['fixedDay'] as num?)?.toInt()),
                    fixedPeriod: Value((l['fixedPeriod'] as num?)?.toInt()),
                    roomTypeId: Value((l['roomTypeId'] as num?)?.toInt()),
                    relationshipType:
                        Value((l['relationshipType'] as num?)?.toInt() ?? 0),
                    relationshipGroupKey:
                        Value(l['relationshipGroupKey']?.toString()),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (cards.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.cards,
            cards
                .map(
                  (c) => CardsCompanion.insert(
                    id: c['id'].toString(),
                    lessonId: c['lessonId'].toString(),
                    dayIndex: (c['dayIndex'] as num?)?.toInt() ?? 0,
                    periodIndex: (c['periodIndex'] as num?)?.toInt() ?? 0,
                    roomId: Value(c['roomId']?.toString()),
                  ),
                )
                .toList(growable: false),
          );
        });
      }
    });
  }
}
