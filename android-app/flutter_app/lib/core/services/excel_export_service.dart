// Excel Export Service — generates .xlsx files with teacher-wise, class-wise,
// and room-wise sheets.
//
// Uses the `excel` Dart package. Data can come from either the Cards table
// in SQLite, or directly from solver results (List<TimetableAssignment>).

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/timetable/presentation/controllers/solver_controller.dart';
import '../../features/timetable/timetable_display.dart';
import '../database.dart';

class ExcelExportService {
  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  // ── Mother Sage branding colors ──
  static const _headerBgHex = '7B906F';   // Mother Sage
  static const _headerFontHex = 'FFFFFF';
  static const _subHeaderBgHex = 'F4EBD9'; // Mother Almond
  static const _altRowBgHex = 'F5F5F0';

  /// Build and share a complete .xlsx timetable workbook.
  Future<void> exportAndShare(AppDatabase db, int dbId) async {
    final bytes = await buildWorkbook(db, dbId);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartTime_Timetable.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      text: 'SmartTime AI Timetable Export',
    );
  }

  /// Build a complete .xlsx workbook and return raw bytes.
  Future<Uint8List> buildWorkbook(AppDatabase db, int dbId) async {
    final cards = await db.select(db.cards).get();
    final lessons = await db.select(db.lessons).get();
    final subjects = await db.select(db.subjects).get();
    final teachers = await db.select(db.teachers).get();
    final classes = await db.select(db.classes).get();
    final plannerSnapshot = await db.loadPlannerSnapshot(dbId);

    final lessonById = {for (final l in lessons) l.id: l};
    final catalog = TimetableDisplayCatalog.fromDatabase(
      subjects: subjects,
      teachers: teachers,
      classes: classes,
      plannerSnapshot: plannerSnapshot,
    );

    final slots = buildTimetableSlots(
      plannerSnapshot: plannerSnapshot,
      usedPeriodIndexes: cards.map((c) => c.periodIndex),
    );

    final dayCount = cards.isEmpty
        ? 5
        : (cards.map((c) => c.dayIndex).reduce((a, b) => a > b ? a : b) + 1).clamp(1, 6);

    final excel = Excel.createExcel();

    // ── Sheet 1: Master Overview ──
    _buildMasterSheet(excel, cards, lessonById, catalog, slots, dayCount);

    // ── Class-wise sheets ──
    final sortedClassIds = classes.map((c) => c.id).toList()..sort();
    for (final classId in sortedClassIds) {
      final classCards = cards.where((c) {
        final lesson = lessonById[c.lessonId];
        return lesson != null && lesson.classIds.contains(classId);
      }).toList();
      if (classCards.isEmpty) continue;

      final classLabel = catalog.classLabel(classId);
      final sheetName = _sanitizeSheetName('C_$classLabel');
      _buildEntitySheet(
        excel: excel,
        sheetName: sheetName,
        title: 'Class: $classLabel',
        cards: classCards,
        lessonById: lessonById,
        catalog: catalog,
        slots: slots,
        dayCount: dayCount,
        secondaryFn: (lesson) => catalog.joinTeacherLabels(lesson.teacherIds),
      );
    }

    // ── Teacher-wise sheets ──
    final sortedTeacherIds = teachers.map((t) => t.id).toList()..sort();
    for (final teacherId in sortedTeacherIds) {
      final teacherCards = cards.where((c) {
        final lesson = lessonById[c.lessonId];
        return lesson != null && lesson.teacherIds.contains(teacherId);
      }).toList();
      if (teacherCards.isEmpty) continue;

      final teacherLabel = catalog.teacherLabel(teacherId);
      final sheetName = _sanitizeSheetName('T_$teacherLabel');
      _buildEntitySheet(
        excel: excel,
        sheetName: sheetName,
        title: 'Teacher: $teacherLabel',
        cards: teacherCards,
        lessonById: lessonById,
        catalog: catalog,
        slots: slots,
        dayCount: dayCount,
        secondaryFn: (lesson) => catalog.joinClassLabels(lesson.classIds),
      );
    }

    // ── Room-wise sheets ──
    final roomIds = cards
        .map((c) => c.roomId)
        .where((id) => id != null && id.trim().isNotEmpty)
        .map((id) => id!)
        .toSet()
        .toList()
      ..sort();
    for (final roomId in roomIds) {
      final roomCards = cards
          .where((c) => c.roomId == roomId)
          .toList();
      if (roomCards.isEmpty) continue;

      final roomLabel = catalog.roomLabel(roomId) ?? roomId;
      final sheetName = _sanitizeSheetName('R_$roomLabel');
      _buildEntitySheet(
        excel: excel,
        sheetName: sheetName,
        title: 'Room: $roomLabel',
        cards: roomCards,
        lessonById: lessonById,
        catalog: catalog,
        slots: slots,
        dayCount: dayCount,
        secondaryFn: (lesson) {
          final cls = catalog.joinClassLabels(lesson.classIds);
          final tch = catalog.joinTeacherLabels(lesson.teacherIds);
          return [cls, tch].where((s) => s.trim().isNotEmpty).join(' | ');
        },
      );
    }

    // Remove default "Sheet1" that Excel creates
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw StateError('Failed to encode Excel workbook');
    return Uint8List.fromList(encoded);
  }

  /// Build a workbook directly from solver results (no DB required).
  Future<Uint8List> buildFromAssignments({
    required List<TimetableAssignment> assignments,
    required int days,
    required int periodsPerDay,
    required TimetableDisplayCatalog catalog,
  }) async {
    // Build simple slot descriptors.
    final slots = List.generate(
      periodsPerDay,
      (i) => TimetableSlotDescriptor(
        id: 'period_${i + 1}',
        label: 'P${i + 1}',
        periodIndex: i,
      ),
      growable: false,
    );

    // Convert solver assignments to CardRow/LessonRow for reuse of existing sheet builders.
    final cards = <CardRow>[];
    final lessonById = <String, LessonRow>{};
    for (final a in assignments) {
      cards.add(CardRow(
        id: a.lessonId,
        lessonId: a.lessonId,
        dayIndex: a.day - 1,
        periodIndex: a.period - 1,
        roomId: a.roomId.isEmpty ? null : a.roomId,
      ));
      lessonById.putIfAbsent(
        a.lessonId,
        () => LessonRow(
          id: a.lessonId,
          classIds: a.classIds,
          teacherIds: a.teacherIds,
          subjectId: a.subjectId,
          periodsPerWeek: 1,
          isPinned: false,
          relationshipType: 0,
        ),
      );
    }

    final excel = Excel.createExcel();

    // ── Master Overview ──
    _buildMasterSheet(excel, cards, lessonById, catalog, slots, days);

    // ── Class-wise sheets ──
    final classIds = assignments.expand((a) => a.classIds).toSet().toList()..sort();
    for (final classId in classIds) {
      final classCards = cards.where((c) {
        final lesson = lessonById[c.lessonId];
        return lesson != null && lesson.classIds.contains(classId);
      }).toList();
      if (classCards.isEmpty) continue;
      final classLabel = catalog.classLabel(classId);
      _buildEntitySheet(
        excel: excel,
        sheetName: _sanitizeSheetName('C_$classLabel'),
        title: 'Class: $classLabel',
        cards: classCards,
        lessonById: lessonById,
        catalog: catalog,
        slots: slots,
        dayCount: days,
        secondaryFn: (lesson) => catalog.joinTeacherLabels(lesson.teacherIds),
      );
    }

    // ── Teacher-wise sheets ──
    final teacherIds = assignments.expand((a) => a.teacherIds).toSet().toList()..sort();
    for (final teacherId in teacherIds) {
      final teacherCards = cards.where((c) {
        final lesson = lessonById[c.lessonId];
        return lesson != null && lesson.teacherIds.contains(teacherId);
      }).toList();
      if (teacherCards.isEmpty) continue;
      final teacherLabel = catalog.teacherLabel(teacherId);
      _buildEntitySheet(
        excel: excel,
        sheetName: _sanitizeSheetName('T_$teacherLabel'),
        title: 'Teacher: $teacherLabel',
        cards: teacherCards,
        lessonById: lessonById,
        catalog: catalog,
        slots: slots,
        dayCount: days,
        secondaryFn: (lesson) => catalog.joinClassLabels(lesson.classIds),
      );
    }

    // ── Room-wise sheets ──
    final roomIds = assignments
        .map((a) => a.roomId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    for (final roomId in roomIds) {
      final roomCards = cards
          .where((c) => c.roomId == roomId)
          .toList();
      if (roomCards.isEmpty) continue;
      final roomLabel = catalog.roomLabel(roomId) ?? roomId;
      _buildEntitySheet(
        excel: excel,
        sheetName: _sanitizeSheetName('R_$roomLabel'),
        title: 'Room: $roomLabel',
        cards: roomCards,
        lessonById: lessonById,
        catalog: catalog,
        slots: slots,
        dayCount: days,
        secondaryFn: (lesson) {
          final cls = catalog.joinClassLabels(lesson.classIds);
          final tch = catalog.joinTeacherLabels(lesson.teacherIds);
          return [cls, tch].where((s) => s.trim().isNotEmpty).join(' | ');
        },
      );
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw StateError('Failed to encode Excel workbook');
    return Uint8List.fromList(encoded);
  }

  /// Export from solver results and share.
  Future<void> exportAndShareFromAssignments({
    required List<TimetableAssignment> assignments,
    required int days,
    required int periodsPerDay,
    required TimetableDisplayCatalog catalog,
  }) async {
    final bytes = await buildFromAssignments(
      assignments: assignments,
      days: days,
      periodsPerDay: periodsPerDay,
      catalog: catalog,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartTime_Timetable.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      text: 'SmartTime AI Timetable Export',
    );
  }

  void _buildMasterSheet(
    Excel excel,
    List<CardRow> cards,
    Map<String, LessonRow> lessonById,
    TimetableDisplayCatalog catalog,
    List<TimetableSlotDescriptor> slots,
    int dayCount,
  ) {
    final sheet = excel['Master Overview'];

    // Title row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('SmartTime AI — Master Timetable');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: dayCount, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle =
        CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#4A3F35'),
      backgroundColorHex: ExcelColor.fromHexString('#$_subHeaderBgHex'),
    );

    // Summary row
    final totalLessons = cards.length;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('Total scheduled: $totalLessons lessons across $dayCount days');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: dayCount, rowIndex: 1),
    );

    // Header row: Day/Period | Day1 | Day2 | ...
    final headerRow = 3;
    _setCellWithStyle(sheet, headerRow, 0, 'Period / Day', isHeader: true);
    for (int d = 0; d < dayCount; d++) {
      _setCellWithStyle(sheet, headerRow, d + 1, d < _dayNames.length ? _dayNames[d] : 'Day ${d + 1}', isHeader: true);
    }

    // Build grid
    final slotIndexByPeriod = <int, int>{
      for (var i = 0; i < slots.length; i++)
        if (slots[i].periodIndex != null) slots[i].periodIndex!: i,
    };

    for (int s = 0; s < slots.length; s++) {
      final row = headerRow + 1 + s;
      final slot = slots[s];
      _setCellWithStyle(sheet, row, 0, slot.label, isRowHeader: true, isBreak: slot.isBreak);

      if (slot.isBreak) {
        for (int d = 0; d < dayCount; d++) {
          _setCellWithStyle(sheet, row, d + 1, '', isBreak: true);
        }
        continue;
      }

      for (int d = 0; d < dayCount; d++) {
        final matchingCards = cards.where((c) =>
            c.dayIndex == d && slotIndexByPeriod[c.periodIndex] == s);

        if (matchingCards.isEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: d + 1, rowIndex: row)).value =
              TextCellValue('');
          continue;
        }

        final cellParts = <String>[];
        for (final card in matchingCards) {
          final lesson = lessonById[card.lessonId];
          if (lesson == null) continue;
          final subject = catalog.subjectLabel(lesson.subjectId);
          final teacher = catalog.joinTeacherLabels(lesson.teacherIds);
          final cls = catalog.joinClassLabels(lesson.classIds);
          cellParts.add('$subject ($teacher) [$cls]');
        }

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: d + 1, rowIndex: row)).value =
            TextCellValue(cellParts.join('\n'));

        // Alternate row coloring
        if (s % 2 == 1) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: d + 1, rowIndex: row)).cellStyle =
              CellStyle(
            backgroundColorHex: ExcelColor.fromHexString('#$_altRowBgHex'),
            textWrapping: TextWrapping.WrapText,
            fontSize: 9,
          );
        } else {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: d + 1, rowIndex: row)).cellStyle =
              CellStyle(
            textWrapping: TextWrapping.WrapText,
            fontSize: 9,
          );
        }
      }
    }

    // Set column widths
    sheet.setColumnWidth(0, 18);
    for (int d = 0; d < dayCount; d++) {
      sheet.setColumnWidth(d + 1, 28);
    }
  }

  void _buildEntitySheet({
    required Excel excel,
    required String sheetName,
    required String title,
    required List<CardRow> cards,
    required Map<String, LessonRow> lessonById,
    required TimetableDisplayCatalog catalog,
    required List<TimetableSlotDescriptor> slots,
    required int dayCount,
    required String Function(LessonRow lesson) secondaryFn,
  }) {
    final sheet = excel[sheetName];

    // Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(title);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: dayCount, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle =
        CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#4A3F35'),
      backgroundColorHex: ExcelColor.fromHexString('#$_subHeaderBgHex'),
    );

    // Header row
    final headerRow = 2;
    _setCellWithStyle(sheet, headerRow, 0, 'Period / Day', isHeader: true);
    for (int d = 0; d < dayCount; d++) {
      _setCellWithStyle(sheet, headerRow, d + 1, d < _dayNames.length ? _dayNames[d] : 'Day ${d + 1}', isHeader: true);
    }

    final slotIndexByPeriod = <int, int>{
      for (var i = 0; i < slots.length; i++)
        if (slots[i].periodIndex != null) slots[i].periodIndex!: i,
    };

    for (int s = 0; s < slots.length; s++) {
      final row = headerRow + 1 + s;
      final slot = slots[s];
      _setCellWithStyle(sheet, row, 0, slot.label, isRowHeader: true, isBreak: slot.isBreak);

      if (slot.isBreak) {
        for (int d = 0; d < dayCount; d++) {
          _setCellWithStyle(sheet, row, d + 1, '', isBreak: true);
        }
        continue;
      }

      for (int d = 0; d < dayCount; d++) {
        final matchingCards = cards.where((c) =>
            c.dayIndex == d && slotIndexByPeriod[c.periodIndex] == s);

        if (matchingCards.isEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: d + 1, rowIndex: row)).value =
              TextCellValue('');
          continue;
        }

        final cellParts = <String>[];
        for (final card in matchingCards) {
          final lesson = lessonById[card.lessonId];
          if (lesson == null) continue;
          final subject = catalog.subjectLabel(lesson.subjectId);
          final secondary = secondaryFn(lesson);
          cellParts.add(secondary.isNotEmpty ? '$subject\n$secondary' : subject);
        }

        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: d + 1, rowIndex: row));
        cell.value = TextCellValue(cellParts.join('\n'));
        cell.cellStyle = s % 2 == 1
            ? CellStyle(
                textWrapping: TextWrapping.WrapText,
                fontSize: 9,
                backgroundColorHex: ExcelColor.fromHexString('#$_altRowBgHex'),
              )
            : CellStyle(
                textWrapping: TextWrapping.WrapText,
                fontSize: 9,
              );
      }
    }

    // Column widths
    sheet.setColumnWidth(0, 18);
    for (int d = 0; d < dayCount; d++) {
      sheet.setColumnWidth(d + 1, 22);
    }
  }

  void _setCellWithStyle(
    Sheet sheet,
    int row,
    int col,
    String text, {
    bool isHeader = false,
    bool isRowHeader = false,
    bool isBreak = false,
  }) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);

    if (isHeader) {
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#$_headerFontHex'),
        backgroundColorHex: ExcelColor.fromHexString('#$_headerBgHex'),
        horizontalAlign: HorizontalAlign.Center,
      );
    } else if (isRowHeader) {
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 9,
        backgroundColorHex: isBreak
            ? ExcelColor.fromHexString('#E0E0E0')
            : ExcelColor.fromHexString('#$_subHeaderBgHex'),
        horizontalAlign: HorizontalAlign.Center,
      );
    } else if (isBreak) {
      cell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
        fontSize: 8,
      );
    }
  }

  /// Sanitize sheet name for Excel (max 31 chars, no special chars)
  String _sanitizeSheetName(String name) {
    var clean = name
        .replaceAll(RegExp(r'[\\/*?\[\]:]'), '')
        .trim();
    if (clean.length > 31) clean = clean.substring(0, 31);
    if (clean.isEmpty) clean = 'Sheet';
    return clean;
  }

  /// Build and share a unified pre-filled .xlsx Setup Template workbook.
  Future<void> exportMasterDataToTemplate(AppDatabase db, int dbId) async {
    final excel = Excel.createExcel();

    final plannerSnapshot = (await db.loadPlannerSnapshot(dbId))!;
    
    // Use the processed planner snapshot which has the correct structure for export
    final teachers = plannerSnapshot['teachers'] as List<dynamic>;
    final classes = plannerSnapshot['classes'] as List<dynamic>;
    final subjects = plannerSnapshot['subjects'] as List<dynamic>;
    final rooms = plannerSnapshot['classrooms'] as List<dynamic>;
    final lessons = plannerSnapshot['lessons'] as List<dynamic>;

    // ── Pre-fill Teachers Sheet ──
    final tSheet = excel['Teachers_Constraints'];
    tSheet.appendRow([
      TextCellValue('teacher_name'),
      TextCellValue('teacher_abbr'),
      TextCellValue('off_days'),
      TextCellValue('off_slots'),
      TextCellValue('max_periods_per_day'),
      TextCellValue('max_gaps_per_day')
    ]);
    for (final t in teachers) {
      final tMap = t as Map<String, dynamic>;
      final timeOff = tMap['timeOff'] as Map<String, dynamic>? ?? {};
      final offSlotsStr = timeOff.entries
          .where((e) => e.value != 0) // not available
          .map((e) => e.key)
          .join(',');
      
      final firstName = tMap['firstName'] as String? ?? '';
      final lastName = tMap['lastName'] as String? ?? '';
      final fullName = firstName + (lastName.isNotEmpty ? ' $lastName' : '');
          
      tSheet.appendRow([
        TextCellValue(fullName),
        TextCellValue(tMap['abbr'] as String? ?? ''),
        TextCellValue(''), // off_days left blank for explicit slots
        TextCellValue(offSlotsStr),
        TextCellValue('${tMap['maxPeriodsPerDay'] ?? ""}'),
        TextCellValue('${tMap['maxGapsPerDay'] ?? ""}')
      ]);
    }

    // ── Pre-fill Lessons Sheet ──
    final lSheet = excel['Lessons_Master'];
    lSheet.appendRow([
      TextCellValue('lesson_id'),
      TextCellValue('class_name'),
      TextCellValue('subject_name'),
      TextCellValue('teacher_name'),
      TextCellValue('weekly_lessons'),
      TextCellValue('lesson_length'),
      TextCellValue('preferred_room')
    ]);

    final subjectById = {for (final s in subjects) s['id'] as String: s};
    final teacherById = {for (final t in teachers) t['id'] as String: t};
    final classById = {for (final c in classes) c['id'] as String: c};
    final roomById = {for (final r in rooms) r['id'] as String: r};

    for (final l in lessons) {
      final lMap = l as Map<String, dynamic>;
      final subj = subjectById[lMap['subjectId']];
      
      final classIds = (lMap['classIds'] as List<dynamic>?) ?? [];
      final rCls = classIds.map((c) => classById[c]?['name'] ?? '').join(',');
      
      final teacherIds = (lMap['teacherIds'] as List<dynamic>?) ?? [];
      final rTeacher = teacherIds.map((t) => teacherById[t]?['firstName'] ?? '').join(',');
      
      final reqRoom = lMap['requiredClassroomId'] as String?;
      final rRoom = reqRoom != null ? (roomById[reqRoom]?['name'] ?? '') : '';
      
      lSheet.appendRow([
        TextCellValue(lMap['id'] as String? ?? ''),
        TextCellValue(rCls),
        TextCellValue(subj?['name'] as String? ?? ''),
        TextCellValue(rTeacher),
        TextCellValue('${lMap['countPerWeek'] ?? ""}'),
        TextCellValue(lMap['length'] as String? ?? ''),
        TextCellValue(rRoom)
      ]);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw StateError('Failed to encode Excel Template');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartTime_Setup_Template.xlsx');
    await file.writeAsBytes(encoded, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      text: 'SmartTime AI Unified Setup Template',
    );
  }
}
