// Excel Export Service — generates .xlsx files matching ASC Timetable format.
//
// Layout: Days as ROWS, Periods as COLUMNS (transposed from original).
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
  static const _dayAbbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // ── Clean professional styling ──
  static const _headerBgHex = '2F2F2F';   // Dark header
  static const _headerFontHex = 'FFFFFF';
  static const _breakBgHex = 'D9D9D9';    // Light gray for breaks

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

    // Extract class teacher mapping from planner snapshot.
    final classTeacherMap = <String, String>{};
    final rawClasses = (plannerSnapshot?['classes'] as List?) ?? const [];
    for (final c in rawClasses) {
      if (c is Map<String, dynamic>) {
        final classId = c['id']?.toString() ?? '';
        final teacherId = c['classTeacherId']?.toString();
        if (classId.isNotEmpty && teacherId != null && teacherId.isNotEmpty) {
          classTeacherMap[classId] = catalog.teacherLabel(teacherId);
        }
      }
    }

    final schoolName = plannerSnapshot?['schoolName']?.toString() ?? '';

    final excel = Excel.createExcel();

    // ── Master Overview ──
    _buildMasterSheet(excel, cards, lessonById, catalog, slots, dayCount, schoolName);

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
      final classTeacher = classTeacherMap[classId];
      _buildEntitySheet(
        excel: excel,
        sheetName: sheetName,
        title: classLabel,
        subtitle: classTeacher != null ? 'Class teacher: $classTeacher' : null,
        schoolName: schoolName,
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
        title: teacherLabel,
        schoolName: schoolName,
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
        title: roomLabel,
        schoolName: schoolName,
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

    // Convert solver assignments to CardRow/LessonRow.
    final cards = <CardRow>[];
    final lessonById = <String, LessonRow>{};
    for (final a in assignments) {
      cards.add(CardRow(
        id: a.lessonId,
        lessonId: a.lessonId,
        dayIndex: a.day - 1,
        periodIndex: a.period - 1,
        roomId: a.roomId.isEmpty ? null : a.roomId,
        isLocked: false,
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
    _buildMasterSheet(excel, cards, lessonById, catalog, slots, days, '');

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
        title: classLabel,
        schoolName: '',
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
        title: teacherLabel,
        schoolName: '',
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
        title: roomLabel,
        schoolName: '',
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

  // ─── Build flat slots (merge consecutive breaks) ───────────────────────────

  List<_FlatSlot> _buildFlatSlots(List<TimetableSlotDescriptor> slots) {
    final flat = <_FlatSlot>[];
    int periodOrdinal = 0;
    int i = 0;
    while (i < slots.length) {
      if (slots[i].isBreak) {
        // Merge consecutive breaks
        final labels = <String>[];
        final start = i;
        while (i < slots.length && slots[i].isBreak) {
          labels.add(slots[i].label);
          i++;
        }
        flat.add(_FlatSlot(
          isBreak: true,
          label: labels.join(' '),
          timeRange: slots[start].timeRange,
        ));
      } else {
        flat.add(_FlatSlot(
          isBreak: false,
          label: _ordinalLabel(periodOrdinal),
          timeRange: slots[i].timeRange,
          slotIndex: i,
        ));
        periodOrdinal++;
        i++;
      }
    }
    return flat;
  }

  // ─── Master Overview Sheet ─────────────────────────────────────────────────

  void _buildMasterSheet(
    Excel excel,
    List<CardRow> cards,
    Map<String, LessonRow> lessonById,
    TimetableDisplayCatalog catalog,
    List<TimetableSlotDescriptor> slots,
    int dayCount,
    String schoolName,
  ) {
    final sheet = excel['Master Overview'];
    final flatSlots = _buildFlatSlots(slots);

    // Title row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(schoolName.isNotEmpty ? '$schoolName — Master Timetable' : 'SmartTime AI — Master Timetable');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: flatSlots.length, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle =
        CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#$_headerFontHex'),
      backgroundColorHex: ExcelColor.fromHexString('#$_headerBgHex'),
    );

    // Header row: Day \ Period | 1st (time) | Break | 2nd (time) | ...
    final headerRow = 2;
    _setCellWithStyle(sheet, headerRow, 0, 'Day', isHeader: true);
    for (int c = 0; c < flatSlots.length; c++) {
      final fs = flatSlots[c];
      final headerText = fs.isBreak
          ? 'Break'
          : fs.timeRange != null
              ? '${fs.label}\n${fs.timeRange}'
              : fs.label;
      _setCellWithStyle(sheet, headerRow, c + 1, headerText, isHeader: true, isBreak: fs.isBreak);
    }

    // Build grid lookup
    final slotIndexByPeriod = <int, int>{
      for (var i = 0; i < slots.length; i++)
        if (slots[i].periodIndex != null) slots[i].periodIndex!: i,
    };

    // Day rows
    for (int d = 0; d < dayCount; d++) {
      final row = headerRow + 1 + d;
      _setCellWithStyle(sheet, row, 0, d < _dayNames.length ? _dayNames[d] : 'Day ${d + 1}', isRowHeader: true);

      for (int c = 0; c < flatSlots.length; c++) {
        final fs = flatSlots[c];
        if (fs.isBreak) {
          _setCellWithStyle(sheet, row, c + 1, '', isBreak: true);
          continue;
        }
        
        final matchingCards = cards.where((card) =>
            card.dayIndex == d && slotIndexByPeriod[card.periodIndex] == fs.slotIndex);

        if (matchingCards.isEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: row)).value =
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

        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: row));
        cell.value = TextCellValue(cellParts.join('\n'));
        cell.cellStyle = CellStyle(
          textWrapping: TextWrapping.WrapText,
          fontSize: 9,
        );
      }
    }

    // Set column widths
    sheet.setColumnWidth(0, 14);
    for (int c = 0; c < flatSlots.length; c++) {
      sheet.setColumnWidth(c + 1, flatSlots[c].isBreak ? 8 : 20);
    }
  }

  // ─── Entity Sheet (Class/Teacher/Room) ─────────────────────────────────────

  void _buildEntitySheet({
    required Excel excel,
    required String sheetName,
    required String title,
    String? subtitle,
    required String schoolName,
    required List<CardRow> cards,
    required Map<String, LessonRow> lessonById,
    required TimetableDisplayCatalog catalog,
    required List<TimetableSlotDescriptor> slots,
    required int dayCount,
    required String Function(LessonRow lesson) secondaryFn,
  }) {
    final sheet = excel[sheetName];
    final flatSlots = _buildFlatSlots(slots);

    // Title row
    final titleText = schoolName.isNotEmpty ? '$schoolName — $title' : title;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(titleText);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: flatSlots.length, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle =
        CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#$_headerFontHex'),
      backgroundColorHex: ExcelColor.fromHexString('#$_headerBgHex'),
    );

    // Subtitle row (class teacher, etc.)
    int headerRow = 2;
    if (subtitle != null) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
          TextCellValue(subtitle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: flatSlots.length, rowIndex: 1),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle =
          CellStyle(bold: true, fontSize: 10);
      headerRow = 3;
    }

    // Header row
    _setCellWithStyle(sheet, headerRow, 0, 'Day', isHeader: true);
    for (int c = 0; c < flatSlots.length; c++) {
      final fs = flatSlots[c];
      final headerText = fs.isBreak
          ? 'Break'
          : fs.timeRange != null
              ? '${fs.label}\n${fs.timeRange}'
              : fs.label;
      _setCellWithStyle(sheet, headerRow, c + 1, headerText, isHeader: true, isBreak: fs.isBreak);
    }

    final slotIndexByPeriod = <int, int>{
      for (var i = 0; i < slots.length; i++)
        if (slots[i].periodIndex != null) slots[i].periodIndex!: i,
    };

    // Day rows
    for (int d = 0; d < dayCount; d++) {
      final row = headerRow + 1 + d;
      _setCellWithStyle(sheet, row, 0, d < _dayAbbrs.length ? _dayAbbrs[d] : 'D${d + 1}', isRowHeader: true);

      for (int c = 0; c < flatSlots.length; c++) {
        final fs = flatSlots[c];
        if (fs.isBreak) {
          _setCellWithStyle(sheet, row, c + 1, '', isBreak: true);
          continue;
        }

        final matchingCards = cards.where((card) =>
            card.dayIndex == d && slotIndexByPeriod[card.periodIndex] == fs.slotIndex);

        if (matchingCards.isEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: row)).value =
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

        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: row));
        cell.value = TextCellValue(cellParts.join('\n'));
        cell.cellStyle = CellStyle(
          textWrapping: TextWrapping.WrapText,
          fontSize: 9,
        );
      }
    }

    // Column widths
    sheet.setColumnWidth(0, 10);
    for (int c = 0; c < flatSlots.length; c++) {
      sheet.setColumnWidth(c + 1, flatSlots[c].isBreak ? 8 : 18);
    }
  }

  // ─── Styling Helpers ───────────────────────────────────────────────────────

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
        fontColorHex: isBreak ? ExcelColor.fromHexString('#333333') : ExcelColor.fromHexString('#$_headerFontHex'),
        backgroundColorHex: isBreak ? ExcelColor.fromHexString('#$_breakBgHex') : ExcelColor.fromHexString('#$_headerBgHex'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
    } else if (isRowHeader) {
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    } else if (isBreak) {
      cell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#$_breakBgHex'),
        fontSize: 8,
      );
    }
  }

  /// ASC-style ordinal labels
  static String _ordinalLabel(int index) {
    final n = index + 1;
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
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

// ─── Internal helper classes ─────────────────────────────────────────────────

class _FlatSlot {
  final bool isBreak;
  final String label;
  final String? timeRange;
  final int? slotIndex;
  const _FlatSlot({
    required this.isBreak,
    required this.label,
    this.timeRange,
    this.slotIndex,
  });
}
