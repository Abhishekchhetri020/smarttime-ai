import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database.dart';
import '../presentation/controllers/solver_controller.dart';

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
              })
          .toList(),
    };

    return compute(_buildMasterPdfBytes, input);
  }

  Future<Uint8List> buildCockpitMasterPdf(AppDatabase db) async {
    final cards = await db.select(db.cards).get();
    final lessons = await db.select(db.lessons).get();
    final subjects = await db.select(db.subjects).get();
    final teachers = await db.select(db.teachers).get();
    final classes = await db.select(db.classes).get();

    final lessonById = {for (final l in lessons) l.id: l};
    final subjectById = {
      for (final s in subjects) s.id: (s.abbr.isNotEmpty ? s.abbr : s.name)
    };
    final teacherById = {
      for (final t in teachers)
        t.id: (t.abbreviation.isNotEmpty ? t.abbreviation : t.name)
    };
    final classById = {
      for (final c in classes) c.id: (c.abbr.isNotEmpty ? c.abbr : c.name)
    };

    final dayCount = cards.isEmpty
        ? 5
        : (cards.map((e) => e.dayIndex).reduce((a, b) => a > b ? a : b) + 1)
            .clamp(1, 6);
    final periodCount = cards.isEmpty
        ? 8
        : (cards.map((e) => e.periodIndex).reduce((a, b) => a > b ? a : b) + 1)
            .clamp(1, 12);

    final classIds = classes.map((e) => e.id).toList()..sort();
    final teacherIds = teachers.map((e) => e.id).toList()..sort();

    final doc = pw.Document();

    for (final classId in classIds) {
      final pageCards = cards.where((c) {
        final l = lessonById[c.lessonId];
        return l != null && l.classIds.contains(classId);
      }).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => _buildGridPage(
            title: 'Class Timetable: ${classById[classId] ?? classId}',
            cards: pageCards,
            lessonById: lessonById,
            subjectById: subjectById,
            teacherById: teacherById,
            classById: classById,
            days: dayCount,
            periodsPerDay: periodCount,
            secondaryMode: 'teacher',
          ),
        ),
      );
    }

    for (final teacherId in teacherIds) {
      final pageCards = cards.where((c) {
        final l = lessonById[c.lessonId];
        return l != null && l.teacherIds.contains(teacherId);
      }).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => _buildGridPage(
            title: 'Teacher Timetable: ${teacherById[teacherId] ?? teacherId}',
            cards: pageCards,
            lessonById: lessonById,
            subjectById: subjectById,
            teacherById: teacherById,
            classById: classById,
            days: dayCount,
            periodsPerDay: periodCount,
            secondaryMode: 'class',
          ),
        ),
      );
    }

    return doc.save();
  }

  Future<void> printCockpitMasterPdf(AppDatabase db) async {
    final bytes = await buildCockpitMasterPdf(db);
    await Printing.layoutPdf(
        onLayout: (_) async => bytes, name: 'smarttime_master_report.pdf');
  }

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

pw.Widget _buildGridPage({
  required String title,
  required List<CardRow> cards,
  required Map<String, LessonRow> lessonById,
  required Map<String, String> subjectById,
  required Map<String, String> teacherById,
  required Map<String, String> classById,
  required int days,
  required int periodsPerDay,
  required String secondaryMode,
}) {
  final grid =
      List.generate(periodsPerDay, (_) => List<String?>.filled(days, null));
  final colorGrid =
      List.generate(periodsPerDay, (_) => List<PdfColor?>.filled(days, null));

  for (final c in cards) {
    final lesson = lessonById[c.lessonId];
    if (lesson == null) continue;
    final d = c.dayIndex;
    final p = c.periodIndex;
    if (d < 0 || d >= days || p < 0 || p >= periodsPerDay) continue;

    final subject = subjectById[lesson.subjectId] ?? lesson.subjectId;
    final teacherText =
        lesson.teacherIds.map((id) => teacherById[id] ?? id).join(', ');
    final classText =
        lesson.classIds.map((id) => classById[id] ?? id).join(', ');
    final secondary = secondaryMode == 'teacher' ? teacherText : classText;

    grid[p][d] =
        '$subject\n$secondary${(c.roomId ?? '').isNotEmpty ? '\n${c.roomId}' : ''}';
    colorGrid[p][d] = _subjectPdfColor(subject);
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey700),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            children: [
              _headerCell('P\\D'),
              for (int d = 1; d <= days; d++) _headerCell('Day $d'),
            ],
          ),
          for (int p = 1; p <= periodsPerDay; p++)
            pw.TableRow(
              children: [
                _headerCell('P$p'),
                for (int d = 1; d <= days; d++)
                  pw.Container(
                    color: colorGrid[p - 1][d - 1] ?? PdfColors.white,
                    padding: const pw.EdgeInsets.all(4),
                    height: 46,
                    child: pw.Text(
                      grid[p - 1][d - 1] ?? '',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: grid[p - 1][d - 1] == null
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

Future<Uint8List> _buildMasterPdfBytes(Map<String, dynamic> input) async {
  final title = input['title'] as String;
  final days = input['days'] as int;
  final periodsPerDay = input['periodsPerDay'] as int;
  final rows = (input['rows'] as List).cast<Map>();

  final doc = pw.Document();

  final grid =
      List.generate(periodsPerDay, (_) => List<String?>.filled(days, null));
  final colorGrid =
      List.generate(periodsPerDay, (_) => List<PdfColor?>.filled(days, null));

  for (final r in rows) {
    final d = (r['day'] as num).toInt();
    final p = (r['period'] as num).toInt();
    if (d < 1 || d > days || p < 1 || p > periodsPerDay) continue;
    final subject = r['subjectId']?.toString() ?? 'SUB';
    final teachers = ((r['teacherIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .join('|');
    final classes = ((r['classIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .join('|');

    grid[p - 1][d - 1] = '$subject\nT:$teachers\nC:$classes';
    colorGrid[p - 1][d - 1] = _subjectPdfColor(subject);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey700),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.TableRow(
              children: [
                _headerCell('P\\D'),
                for (int d = 1; d <= days; d++) _headerCell('Day $d'),
              ],
            ),
            for (int p = 1; p <= periodsPerDay; p++)
              pw.TableRow(
                children: [
                  _headerCell('P$p'),
                  for (int d = 1; d <= days; d++)
                    pw.Container(
                      color: colorGrid[p - 1][d - 1] ?? PdfColors.white,
                      padding: const pw.EdgeInsets.all(4),
                      height: 42,
                      child: pw.Text(
                        grid[p - 1][d - 1] ?? '',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: grid[p - 1][d - 1] == null
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

pw.Widget _headerCell(String text) {
  return pw.Container(
    color: PdfColors.blueGrey100,
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
  );
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
