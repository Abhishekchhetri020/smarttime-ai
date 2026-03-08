import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<Uint8List> buildTeacherSchedulePdf({
    required String teacherId,
    required List<TimetableAssignment> assignments,
    required int days,
    required int periodsPerDay,
  }) async {
    final filtered = assignments.where((a) => a.teacherIds.contains(teacherId)).toList();
    return buildMasterGridPdf(
      assignments: filtered,
      days: days,
      periodsPerDay: periodsPerDay,
      title: 'Teacher Schedule: $teacherId',
    );
  }

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

Future<Uint8List> _buildMasterPdfBytes(Map<String, dynamic> input) async {
  final title = input['title'] as String;
  final days = input['days'] as int;
  final periodsPerDay = input['periodsPerDay'] as int;
  final rows = (input['rows'] as List).cast<Map>();

  final doc = pw.Document();

  final grid = List.generate(periodsPerDay, (_) => List<String?>.filled(days, null));
  final colorGrid = List.generate(periodsPerDay, (_) => List<PdfColor?>.filled(days, null));

  for (final r in rows) {
    final d = (r['day'] as num).toInt();
    final p = (r['period'] as num).toInt();
    if (d < 1 || d > days || p < 1 || p > periodsPerDay) continue;
    final subject = r['subjectId']?.toString() ?? 'SUB';
    final teachers = ((r['teacherIds'] as List?) ?? const []).map((e) => e.toString()).join('|');
    final classes = ((r['classIds'] as List?) ?? const []).map((e) => e.toString()).join('|');

    grid[p - 1][d - 1] = '$subject\nT:$teachers\nC:$classes';
    colorGrid[p - 1][d - 1] = _subjectPdfColor(subject);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
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
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
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
