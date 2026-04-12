import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database.dart';
import '../presentation/controllers/solver_controller.dart';
import '../timetable_display.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ASC-style Timetable PDF Service
//
// Produces industry-standard timetable PDFs matching the aSc Timetables format:
//   – Days as ROWS (Mo, Tu, We, …), periods as COLUMNS
//   – Two-line column headers (ordinal + time range)
//   – Break columns with rotated vertical text
//   – School header with logo placeholder, entity name, class teacher
//   – Clean black-and-white bordered cells (B&W print friendly)
//   – Footer with effective date and branding
// ─────────────────────────────────────────────────────────────────────────────

class TimetablePdfService {

  Future<Uint8List> buildMasterGridPdf({
    required List<TimetableAssignment> assignments,
    required int days,
    required int periodsPerDay,
    String title = 'Timetable',
  }) async {
    final input = {
      'title': title,
      'days': days,
      'periodsPerDay': periodsPerDay,
      'rows': assignments
          .map((a) => {
                'lessonId': a.lessonId,
                'day': a.day,
                'period': a.period,
                'subjectId': a.subjectId,
                'teacherIds': a.teacherIds,
                'classIds': a.classIds,
                'roomId': a.roomId,
              })
          .toList(),
    };

    return compute(_buildMasterPdfBytes, input);
  }

  /// Build a complete multi-perspective PDF workbook from DB.
  Future<Uint8List> buildWorkbookPdf(AppDatabase db, int dbId) async {
    final cards = await db.select(db.cards).get();
    final lessons = await db.select(db.lessons).get();
    final subjects = await db.select(db.subjects).get();
    final teachers = await db.select(db.teachers).get();
    final classes = await db.select(db.classes).get();
    final plannerSnapshot = await db.loadPlannerSnapshot(dbId);

    final lessonById = {for (final lesson in lessons) lesson.id: lesson};
    final catalog = TimetableDisplayCatalog.fromDatabase(
      subjects: subjects,
      teachers: teachers,
      classes: classes,
      plannerSnapshot: plannerSnapshot,
    );
    final slots = buildTimetableSlots(
      plannerSnapshot: plannerSnapshot,
      usedPeriodIndexes: cards.map((card) => card.periodIndex),
    );
    final dayCount = cards.isEmpty
        ? 5
        : (cards.map((card) => card.dayIndex).reduce((a, b) => a > b ? a : b) +
                1)
            .clamp(1, 6);

    final resolvedSchoolName = plannerSnapshot?['schoolName']?.toString() ?? '';

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

    final generatedAt = DateTime.now();
    final dateStamp =
        '${generatedAt.day.toString().padLeft(2, '0')}.${generatedAt.month.toString().padLeft(2, '0')}.${generatedAt.year}';

    final classIds = classes.map((item) => item.id).toList()..sort();
    final teacherIds = teachers.map((item) => item.id).toList()..sort();

    // Collect unique room IDs from cards.
    final roomIds = cards
        .map((c) => c.roomId)
        .where((id) => id != null && id.trim().isNotEmpty)
        .map((id) => id!)
        .toSet()
        .toList()
      ..sort();

    final doc = pw.Document();

    // ── Class-wise pages ──
    for (final classId in classIds) {
      final pageCards = cards.where((card) {
        final lesson = lessonById[card.lessonId];
        return lesson != null && lesson.classIds.contains(classId);
      }).toList(growable: false);
      final classLabel = catalog.classLabel(classId);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => _buildAscPage(
            schoolName: resolvedSchoolName,
            entityName: classLabel,
            subtitle: classTeacherMap[classId] != null
                ? 'Class teacher: ${classTeacherMap[classId]}'
                : null,
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: dayCount,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.teacher,
            dateStamp: dateStamp,
          ),
        ),
      );
    }

    // ── Teacher-wise pages ──
    for (final teacherId in teacherIds) {
      final pageCards = cards.where((card) {
        final lesson = lessonById[card.lessonId];
        return lesson != null && lesson.teacherIds.contains(teacherId);
      }).toList(growable: false);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => _buildAscPage(
            schoolName: resolvedSchoolName,
            entityName: catalog.teacherLabel(teacherId),
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: dayCount,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classroom,
            dateStamp: dateStamp,
          ),
        ),
      );
    }

    // ── Room-wise pages ──
    for (final roomId in roomIds) {
      final pageCards = cards
          .where((card) => card.roomId == roomId)
          .toList(growable: false);
      if (pageCards.isEmpty) continue;
      final roomLabel = catalog.roomLabel(roomId) ?? roomId;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => _buildAscPage(
            schoolName: resolvedSchoolName,
            entityName: roomLabel,
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: dayCount,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classAndTeacher,
            dateStamp: dateStamp,
          ),
        ),
      );
    }

    return doc.save();
  }

  /// Build a PDF directly from solver results (no DB required).
  Future<Uint8List> buildFromAssignments({
    required List<TimetableAssignment> assignments,
    required int days,
    required int periodsPerDay,
    required TimetableDisplayCatalog catalog,
    String schoolName = '',
  }) async {
    final generatedAt = DateTime.now();
    final dateStamp =
        '${generatedAt.day.toString().padLeft(2, '0')}.${generatedAt.month.toString().padLeft(2, '0')}.${generatedAt.year}';

    // Build simple slot descriptors (no breaks, just P1..Pn).
    final slots = List.generate(
      periodsPerDay,
      (i) => TimetableSlotDescriptor(
        id: 'period_${i + 1}',
        label: 'P${i + 1}',
        periodIndex: i,
      ),
      growable: false,
    );

    // Convert assignments to card-like + lesson-like format.
    final cards = <CardRow>[];
    final lessonById = <String, LessonRow>{};
    for (final a in assignments) {
      cards.add(_assignmentToCard(a));
      lessonById.putIfAbsent(a.lessonId, () => _assignmentToLesson(a));
    }

    // Collect entity IDs.
    final classIds = assignments.expand((a) => a.classIds).toSet().toList()..sort();
    final teacherIds = assignments.expand((a) => a.teacherIds).toSet().toList()..sort();
    final roomIds = assignments
        .map((a) => a.roomId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final doc = pw.Document();

    // ── Class-wise pages ──
    for (final classId in classIds) {
      final pageCards = cards.where((c) {
        final lesson = lessonById[c.lessonId];
        return lesson != null && lesson.classIds.contains(classId);
      }).toList(growable: false);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => _buildAscPage(
            schoolName: schoolName,
            entityName: catalog.classLabel(classId),
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: days,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.teacher,
            dateStamp: dateStamp,
          ),
        ),
      );
    }

    // ── Teacher-wise pages ──
    for (final teacherId in teacherIds) {
      final pageCards = cards.where((c) {
        final lesson = lessonById[c.lessonId];
        return lesson != null && lesson.teacherIds.contains(teacherId);
      }).toList(growable: false);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => _buildAscPage(
            schoolName: schoolName,
            entityName: catalog.teacherLabel(teacherId),
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: days,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classroom,
            dateStamp: dateStamp,
          ),
        ),
      );
    }

    // ── Room-wise pages ──
    for (final roomId in roomIds) {
      final pageCards = cards
          .where((c) => c.roomId == roomId)
          .toList(growable: false);
      if (pageCards.isEmpty) continue;
      final roomLabel = catalog.roomLabel(roomId) ?? roomId;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => _buildAscPage(
            schoolName: schoolName,
            entityName: roomLabel,
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: days,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classAndTeacher,
            dateStamp: dateStamp,
          ),
        ),
      );
    }

    return doc.save();
  }

  Future<void> printCockpitMasterPdf(AppDatabase db, int dbId, {String? schoolName}) async {
    final bytes = await buildWorkbookPdf(db, dbId);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'smarttime_master_report.pdf',
    );
  }

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

// ─── Enums & Helpers ─────────────────────────────────────────────────────────

enum _PdfSecondaryMode { teacher, classroom, classAndTeacher }

const _dayAbbrs = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

/// ASC-style ordinal labels: 1st, 2nd, 3rd, 4th, …
String _ordinalLabel(int index) {
  final n = index + 1;
  if (n == 1) return '1st';
  if (n == 2) return '2nd';
  if (n == 3) return '3rd';
  return '${n}th';
}

// ─── ASC Page Builder ────────────────────────────────────────────────────────

pw.Widget _buildAscPage({
  required String schoolName,
  required String entityName,
  String? subtitle,
  required List<CardRow> cards,
  required Map<String, LessonRow> lessonById,
  required TimetableDisplayCatalog catalog,
  required int days,
  required List<TimetableSlotDescriptor> slots,
  required _PdfSecondaryMode secondaryMode,
  required String dateStamp,
}) {
  return pw.Column(
    children: [
      // ── Header ──
      _buildAscHeader(schoolName: schoolName, entityName: entityName, subtitle: subtitle),
      pw.SizedBox(height: 6),

      // ── Grid ──
      pw.Expanded(
        child: _buildAscGrid(
          cards: cards,
          lessonById: lessonById,
          catalog: catalog,
          days: days,
          slots: slots,
          secondaryMode: secondaryMode,
        ),
      ),

      // ── Footer ──
      pw.SizedBox(height: 4),
      _buildAscFooter(dateStamp: dateStamp),
    ],
  );
}

// ─── ASC Header ──────────────────────────────────────────────────────────────

pw.Widget _buildAscHeader({
  required String schoolName,
  required String entityName,
  String? subtitle,
}) {
  return pw.Column(
    children: [
      // School name - large, bold, centered
      if (schoolName.isNotEmpty)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo placeholder — gray circle with initial
            pw.Container(
              width: 38,
              height: 38,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.grey700, width: 1.5),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    schoolName.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 48), // balance the logo
          ],
        ),

      // Entity name (class/teacher) — very large
      pw.Text(
        entityName,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
        ),
      ),

      // Subtitle row: school name repeated + class teacher
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            schoolName.isNotEmpty ? schoolName.toUpperCase() : '',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
          if (subtitle != null)
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
        ],
      ),
    ],
  );
}

// ─── ASC Footer ──────────────────────────────────────────────────────────────

pw.Widget _buildAscFooter({required String dateStamp}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'W.E.F  $dateStamp',
        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
      ),
      pw.Text(
        'SmartTime AI',
        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
      ),
    ],
  );
}

// ─── ASC Grid (Days as rows, Periods as columns) ─────────────────────────────

pw.Widget _buildAscGrid({
  required List<CardRow> cards,
  required Map<String, LessonRow> lessonById,
  required TimetableDisplayCatalog catalog,
  required int days,
  required List<TimetableSlotDescriptor> slots,
  required _PdfSecondaryMode secondaryMode,
}) {
  // Build a lookup: grid[dayIndex][slotIndex] = {subject, secondary}
  final slotIndexByPeriodIndex = <int, int>{
    for (var i = 0; i < slots.length; i++)
      if (slots[i].periodIndex != null) slots[i].periodIndex!: i,
  };

  final grid = List.generate(
    days,
    (_) => List<_CellContent?>.filled(slots.length, null),
  );

  for (final card in cards) {
    final lesson = lessonById[card.lessonId];
    if (lesson == null) continue;
    final dayIdx = card.dayIndex;
    final slotIdx = slotIndexByPeriodIndex[card.periodIndex];
    if (slotIdx == null || dayIdx < 0 || dayIdx >= days) continue;

    final subject = catalog.subjectLabel(lesson.subjectId);
    final secondary = switch (secondaryMode) {
      _PdfSecondaryMode.teacher => catalog.joinTeacherLabels(lesson.teacherIds),
      _PdfSecondaryMode.classroom => catalog.joinClassLabels(lesson.classIds),
      _PdfSecondaryMode.classAndTeacher => [
          catalog.joinClassLabels(lesson.classIds),
          catalog.joinTeacherLabels(lesson.teacherIds),
        ].where((s) => s.trim().isNotEmpty).join(' | '),
    };

    // If cell already has content (multiple lessons in same slot), append
    final existing = grid[dayIdx][slotIdx];
    if (existing != null) {
      grid[dayIdx][slotIdx] = _CellContent(
        subject: '${existing.subject}\n$subject',
        secondary: '${existing.secondary}\n$secondary',
      );
    } else {
      grid[dayIdx][slotIdx] = _CellContent(subject: subject, secondary: secondary);
    }
  }

  // ── Identify break groups (consecutive break slots to merge) ──
  final breakGroups = <_BreakGroup>[];
  int? breakStart;
  for (int s = 0; s < slots.length; s++) {
    if (slots[s].isBreak) {
      breakStart ??= s;
    } else {
      if (breakStart != null) {
        breakGroups.add(_BreakGroup(startSlot: breakStart, endSlot: s - 1));
        breakStart = null;
      }
    }
  }
  if (breakStart != null) {
    breakGroups.add(_BreakGroup(startSlot: breakStart, endSlot: slots.length - 1));
  }

  // Count period slots (non-break) for ordinal labeling
  var periodOrdinal = 0;
  final ordinalBySlot = <int, int>{};
  for (int s = 0; s < slots.length; s++) {
    if (!slots[s].isBreak) {
      ordinalBySlot[s] = periodOrdinal;
      periodOrdinal++;
    }
  }

  // ── Column widths ──
  // Day column is wider, period columns are equal, break columns are narrow
  final breakColWidth = 28.0;
  final dayColWidth = 42.0;
  // Calculate period column width to fill remaining space
  final availableWidth = PdfPageFormat.a4.landscape.width - 40; // margins
  final totalBreakWidth = breakGroups.fold<double>(0, (sum, bg) => sum + breakColWidth);
  final nonBreakSlots = slots.where((s) => !s.isBreak).length;
  final periodColWidth = nonBreakSlots > 0
      ? (availableWidth - dayColWidth - totalBreakWidth) / nonBreakSlots
      : 80.0;

  // Build column widths map
  final colWidths = <int, pw.TableColumnWidth>{};
  colWidths[0] = pw.FixedColumnWidth(dayColWidth);
  int colIdx = 1;
  for (int s = 0; s < slots.length; s++) {
    if (slots[s].isBreak) {
      // Check if this break is the first in its group
      final bg = breakGroups.firstWhere((g) => g.startSlot == s, orElse: () => _BreakGroup(startSlot: -1, endSlot: -1));
      if (bg.startSlot == s) {
        colWidths[colIdx] = pw.FixedColumnWidth(breakColWidth);
        colIdx++;
      }
      // Skip non-first break slots in the group (they're merged)
    } else {
      colWidths[colIdx] = pw.FixedColumnWidth(periodColWidth);
      colIdx++;
    }
  }

  // ── Build flat column list (merging consecutive breaks into one column) ──
  final flatSlots = <_FlatSlot>[];
  for (int s = 0; s < slots.length; s++) {
    if (slots[s].isBreak) {
      final bg = breakGroups.firstWhere((g) => g.startSlot <= s && g.endSlot >= s);
      if (bg.startSlot == s) {
        // Build break label from all break slots in the group
        final labels = <String>[];
        for (int bs = bg.startSlot; bs <= bg.endSlot; bs++) {
          labels.add(slots[bs].label);
        }
        final timeRange = slots[bg.startSlot].timeRange;
        flatSlots.add(_FlatSlot(
          isBreak: true,
          label: labels.join(' '),
          timeRange: timeRange,
        ));
      }
      // Skip non-first break slots
    } else {
      flatSlots.add(_FlatSlot(
        isBreak: false,
        label: _ordinalLabel(ordinalBySlot[s]!),
        timeRange: slots[s].timeRange,
        slotIndex: s,
      ));
    }
  }

  // ── Build Table Rows ──
  final tableRows = <pw.TableRow>[];

  // Header row: empty corner + period headers (two-line) + break headers
  tableRows.add(pw.TableRow(
    children: [
      // Corner cell (empty)
      pw.Container(
        height: 36,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.6),
        ),
      ),
      // Period/break headers
      for (final fs in flatSlots)
        pw.Container(
          height: 36,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.6),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: fs.isBreak
              ? pw.Text(
                  'Break',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                )
              : pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      fs.label,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    if (fs.timeRange != null)
                      pw.Text(
                        fs.timeRange!,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                  ],
                ),
        ),
    ],
  ));

  // Day rows
  for (int d = 0; d < days; d++) {
    final dayLabel = d < _dayAbbrs.length ? _dayAbbrs[d] : 'D${d + 1}';
    final cellHeight = 60.0;

    tableRows.add(pw.TableRow(
      children: [
        // Day cell
        pw.Container(
          height: cellHeight,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.6),
          ),
          child: pw.Text(
            dayLabel,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        // Period/break cells
        for (final fs in flatSlots)
          fs.isBreak
              ? _buildBreakCell(fs.label, cellHeight)
              : _buildContentCell(grid[d][fs.slotIndex!], cellHeight, secondaryMode),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(width: 0.6),
    columnWidths: colWidths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: tableRows,
  );
}

// ─── Break Cell (vertical rotated text) ──────────────────────────────────────

pw.Widget _buildBreakCell(String label, double height) {
  return pw.Container(
    height: height,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.6),
      color: PdfColors.grey200,
    ),
    child: pw.Transform.rotateBox(
      angle: -math.pi / 2,
      child: pw.Text(
        label.toUpperCase(),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    ),
  );
}

// ─── Content Cell ────────────────────────────────────────────────────────────

pw.Widget _buildContentCell(_CellContent? content, double height, _PdfSecondaryMode mode) {
  if (content == null) {
    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.6),
      ),
    );
  }

  return pw.Container(
    height: height,
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        // Subject name — bold, larger
        pw.Text(
          content.subject,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            lineSpacing: 1.0,
          ),
        ),
        pw.SizedBox(height: 2),
        // Secondary (teacher / class) — smaller
        if (content.secondary.isNotEmpty)
          pw.Text(
            content.secondary,
            maxLines: 3,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              fontSize: mode == _PdfSecondaryMode.classroom ? 10 : 7.5,
              fontWeight: mode == _PdfSecondaryMode.classroom
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              lineSpacing: 1.0,
            ),
          ),
      ],
    ),
  );
}

// ─── Data Classes ────────────────────────────────────────────────────────────

class _CellContent {
  final String subject;
  final String secondary;
  const _CellContent({required this.subject, required this.secondary});
}

class _BreakGroup {
  final int startSlot;
  final int endSlot;
  const _BreakGroup({required this.startSlot, required this.endSlot});
}

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

// ─── Converters ──────────────────────────────────────────────────────────────

/// Convert a [TimetableAssignment] into a [CardRow] for the grid builder.
CardRow _assignmentToCard(TimetableAssignment a) {
  return CardRow(
    id: a.lessonId,
    lessonId: a.lessonId,
    dayIndex: a.day - 1,
    periodIndex: a.period - 1,
    roomId: a.roomId,
    isLocked: false,
  );
}

/// Convert a [TimetableAssignment] into a [LessonRow] stub for the grid builder.
LessonRow _assignmentToLesson(TimetableAssignment a) {
  return LessonRow(
    id: a.lessonId,
    classIds: a.classIds,
    teacherIds: a.teacherIds,
    subjectId: a.subjectId,
    periodsPerWeek: 1,
    isPinned: false,
    relationshipType: 0,
  );
}

// ─── Legacy master grid builder (for isolate compute) ────────────────────────

Future<Uint8List> _buildMasterPdfBytes(Map<String, dynamic> input) async {
  final title = input['title'] as String;
  final days = input['days'] as int;
  final periodsPerDay = input['periodsPerDay'] as int;
  final rows = (input['rows'] as List)
      .map((entry) => Map<String, dynamic>.from(entry as Map))
      .toList(growable: false);

  final doc = pw.Document();

  final grid =
      List.generate(periodsPerDay, (_) => List<String?>.filled(days, null));

  for (final row in rows) {
    final day = (row['day'] as num).toInt();
    final period = (row['period'] as num).toInt();
    if (day < 1 || day > days || period < 1 || period > periodsPerDay) continue;

    final subject = humanizeTimetableId(row['subjectId']?.toString() ?? 'SUB');
    final teachers = ((row['teacherIds'] as List?) ?? const [])
        .map((value) => humanizeTimetableId(value.toString()))
        .where((value) => value.isNotEmpty)
        .join(', ');
    final classes = ((row['classIds'] as List?) ?? const [])
        .map((value) => humanizeTimetableId(value.toString()))
        .where((value) => value.isNotEmpty)
        .join(', ');

    grid[period - 1][day - 1] = [subject, teachers, classes]
        .where((v) => v.trim().isNotEmpty)
        .join('\n');
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style:
                    pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '$days days × $periodsPerDay periods',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey700),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.TableRow(
              children: [
                _legacyHeaderCell('P\\D'),
                for (int day = 1; day <= days; day++) _legacyHeaderCell('Day $day'),
              ],
            ),
            for (int period = 1; period <= periodsPerDay; period++)
              pw.TableRow(
                children: [
                  _legacyHeaderCell('P$period'),
                  for (int day = 1; day <= days; day++)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 4,
                      ),
                      height: 50,
                      child: pw.Text(
                        grid[period - 1][day - 1] ?? '',
                        maxLines: 3,
                        softWrap: true,
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          lineSpacing: 1.1,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _legacyHeaderCell(String text, {bool shaded = false}) {
  return pw.Container(
    color: shaded ? PdfColors.grey300 : PdfColors.blueGrey100,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    ),
  );
}

@visibleForTesting
String pdfCellText({
  required String subject,
  required String secondary,
}) {
  return [subject.trim(), secondary.trim()]
      .where((line) => line.isNotEmpty)
      .join('\n');
}
