import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database.dart';
import '../presentation/controllers/solver_controller.dart';
import '../timetable_display.dart';

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

  /// Build a complete multi-perspective PDF grid
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

    // Resolve school name from planner snapshot.
    final resolvedSchoolName = plannerSnapshot?['schoolName']?.toString() ??
        '';

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

    final generatedAt = DateTime.now();
    final timestamp =
        '${generatedAt.year}-${generatedAt.month.toString().padLeft(2, '0')}-${generatedAt.day.toString().padLeft(2, '0')} '
        '${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';

    final doc = pw.Document();

    // ── Class-wise pages ──
    for (final classId in classIds) {
      final pageCards = cards.where((card) {
        final lesson = lessonById[card.lessonId];
        return lesson != null && lesson.classIds.contains(classId);
      }).toList(growable: false);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => _buildBrandedGridPage(
            schoolName: resolvedSchoolName,
            title: 'Class Timetable: ${catalog.classLabel(classId)}',
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: dayCount,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.teacher,
            timestamp: timestamp,
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
          build: (_) => _buildBrandedGridPage(
            schoolName: resolvedSchoolName,
            title: 'Teacher Timetable: ${catalog.teacherLabel(teacherId)}',
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: dayCount,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classroom,
            timestamp: timestamp,
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
          build: (_) => _buildBrandedGridPage(
            schoolName: resolvedSchoolName,
            title: 'Room Timetable: $roomLabel',
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: dayCount,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classAndTeacher,
            timestamp: timestamp,
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
    final timestamp =
        '${generatedAt.year}-${generatedAt.month.toString().padLeft(2, '0')}-${generatedAt.day.toString().padLeft(2, '0')} '
        '${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';

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

    // Convert assignments to a card-like + lesson-like format the grid builder expects.
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
          build: (_) => _buildBrandedGridPage(
            schoolName: schoolName,
            title: 'Class Timetable: ${catalog.classLabel(classId)}',
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: days,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.teacher,
            timestamp: timestamp,
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
          build: (_) => _buildBrandedGridPage(
            schoolName: schoolName,
            title: 'Teacher Timetable: ${catalog.teacherLabel(teacherId)}',
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: days,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classroom,
            timestamp: timestamp,
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
          build: (_) => _buildBrandedGridPage(
            schoolName: schoolName,
            title: 'Room Timetable: $roomLabel',
            cards: pageCards,
            lessonById: lessonById,
            catalog: catalog,
            days: days,
            slots: slots,
            secondaryMode: _PdfSecondaryMode.classAndTeacher,
            timestamp: timestamp,
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

enum _PdfSecondaryMode { teacher, classroom, classAndTeacher }

pw.Widget _buildGridPage({
  required String title,
  required List<CardRow> cards,
  required Map<String, LessonRow> lessonById,
  required TimetableDisplayCatalog catalog,
  required int days,
  required List<TimetableSlotDescriptor> slots,
  required _PdfSecondaryMode secondaryMode,
}) {
  final grid =
      List.generate(slots.length, (_) => List<String?>.filled(days, null));
  final colorGrid =
      List.generate(slots.length, (_) => List<PdfColor?>.filled(days, null));
  final slotIndexByPeriodIndex = <int, int>{
    for (var index = 0; index < slots.length; index++)
      if (slots[index].periodIndex != null) slots[index].periodIndex!: index,
  };

  for (final card in cards) {
    final lesson = lessonById[card.lessonId];
    if (lesson == null) continue;
    final dayIndex = card.dayIndex;
    final rowIndex = slotIndexByPeriodIndex[card.periodIndex];
    if (rowIndex == null || dayIndex < 0 || dayIndex >= days) continue;

    final subject = catalog.subjectLabel(lesson.subjectId);
    final secondary = switch (secondaryMode) {
      _PdfSecondaryMode.teacher => catalog.joinTeacherLabels(lesson.teacherIds),
      _PdfSecondaryMode.classroom => catalog.joinClassLabels(lesson.classIds),
      _PdfSecondaryMode.classAndTeacher => [
          catalog.joinClassLabels(lesson.classIds),
          catalog.joinTeacherLabels(lesson.teacherIds),
        ].where((s) => s.trim().isNotEmpty).join(' | '),
    };

    grid[rowIndex][dayIndex] =
        pdfCellText(subject: subject, secondary: secondary);
    colorGrid[rowIndex][dayIndex] = _subjectPdfColor(subject);
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
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
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '$days days × ${slots.where((slot) => !slot.isBreak).length} periods',
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
              _headerCell('Slot'),
              for (int day = 1; day <= days; day++) _headerCell('Day $day'),
            ],
          ),
          for (int rowIndex = 0; rowIndex < slots.length; rowIndex++)
            pw.TableRow(
              children: [
                _headerCell(slots[rowIndex].label,
                    shaded: slots[rowIndex].isBreak),
                for (int day = 1; day <= days; day++)
                  pw.Container(
                    color: slots[rowIndex].isBreak
                        ? PdfColors.grey200
                        : (colorGrid[rowIndex][day - 1] ?? PdfColors.white),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    constraints: pw.BoxConstraints(
                      minHeight: slots[rowIndex].isBreak ? 28 : 54,
                    ),
                    child: pw.Text(
                      slots[rowIndex].isBreak
                          ? ''
                          : (grid[rowIndex][day - 1] ?? ''),
                      maxLines: 3,
                      softWrap: true,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        lineSpacing: 1.1,
                        color: grid[rowIndex][day - 1] == null
                            ? PdfColors.black
                            : PdfColors.white,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ],
  );
}

/// Wraps _buildGridPage with a school name banner and timestamp footer.
pw.Widget _buildBrandedGridPage({
  required String schoolName,
  required String title,
  required List<CardRow> cards,
  required Map<String, LessonRow> lessonById,
  required TimetableDisplayCatalog catalog,
  required int days,
  required List<TimetableSlotDescriptor> slots,
  required _PdfSecondaryMode secondaryMode,
  required String timestamp,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // School name banner (only if name is provided).
      if (schoolName.isNotEmpty)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.31, 0.27, 0.21), // #4F4536 dark sage
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            schoolName,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
      if (schoolName.isNotEmpty) pw.SizedBox(height: 6),

      // The main grid.
      pw.Expanded(
        child: _buildGridPage(
          title: title,
          cards: cards,
          lessonById: lessonById,
          catalog: catalog,
          days: days,
          slots: slots,
          secondaryMode: secondaryMode,
        ),
      ),

      // Timestamp footer.
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by SmartTime AI',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            timestamp,
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    ],
  );
}

/// Convert a [TimetableAssignment] into a [CardRow] for the grid builder.
CardRow _assignmentToCard(TimetableAssignment a) {
  return CardRow(
    id: a.lessonId,
    lessonId: a.lessonId,
    dayIndex: a.day - 1,
    periodIndex: a.period - 1,
    roomId: a.roomId,
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
  final colorGrid =
      List.generate(periodsPerDay, (_) => List<PdfColor?>.filled(days, null));

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
    final room = humanizeTimetableId(row['roomId']?.toString() ?? '');

    grid[period - 1][day - 1] = pdfCellText(
      subject: subject,
      secondary: [teachers, classes, room]
          .where((value) => value.trim().isNotEmpty)
          .join(' | '),
    );
    colorGrid[period - 1][day - 1] = _subjectPdfColor(subject);
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
                _headerCell('P\\D'),
                for (int day = 1; day <= days; day++) _headerCell('Day $day'),
              ],
            ),
            for (int period = 1; period <= periodsPerDay; period++)
              pw.TableRow(
                children: [
                  _headerCell('P$period'),
                  for (int day = 1; day <= days; day++)
                    pw.Container(
                      color: colorGrid[period - 1][day - 1] ?? PdfColors.white,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 4,
                      ),
                      height: 50,
                      child: pw.Text(
                        grid[period - 1][day - 1] ?? '',
                        maxLines: 3,
                        softWrap: true,
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          lineSpacing: 1.1,
                          color: grid[period - 1][day - 1] == null
                              ? PdfColors.black
                              : PdfColors.white,
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

pw.Widget _headerCell(String text, {bool shaded = false}) {
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

PdfColor _subjectPdfColor(String subjectId) {
  const palette = [
    0xFF4F46E5,
    0xFF059669,
    0xFFD97706,
    0xFFDB2777,
    0xFF0284C7,
    0xFF7C3AED,
    0xFFDC2626,
    0xFF0891B2,
  ];
  final hex = palette[subjectId.hashCode.abs() % palette.length];
  final r = ((hex >> 16) & 0xFF) / 255.0;
  final g = ((hex >> 8) & 0xFF) / 255.0;
  final b = (hex & 0xFF) / 255.0;
  return PdfColor(r, g, b);
}
