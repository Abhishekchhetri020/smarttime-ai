// Excel Export Service — generates .xlsx files with teacher-wise and class-wise sheets.
//
// Uses the `excel` Dart package. All data comes from the Cards table in SQLite.

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  Future<void> exportAndShare(AppDatabase db) async {
    final bytes = await buildWorkbook(db);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartTime_Timetable.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      text: 'SmartTime AI Timetable Export',
    );
  }

  /// Build a complete .xlsx workbook and return raw bytes.
  Future<Uint8List> buildWorkbook(AppDatabase db) async {
    final cards = await db.select(db.cards).get();
    final lessons = await db.select(db.lessons).get();
    final subjects = await db.select(db.subjects).get();
    final teachers = await db.select(db.teachers).get();
    final classes = await db.select(db.classes).get();
    final plannerSnapshot = await db.loadPlannerSnapshot();

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

    // Remove default "Sheet1" that Excel creates
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw StateError('Failed to encode Excel workbook');
    return Uint8List.fromList(encoded);
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
}
