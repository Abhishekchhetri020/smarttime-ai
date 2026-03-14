// PDF Export Service — generates professional timetable PDFs with actual data.
//
// Delegates to TimetablePdfService which produces teacher-wise and
// class-wise pages from the Cards table in SQLite.

import 'package:printing/printing.dart';

import '../../features/admin/planner_state.dart';
import '../../features/timetable/data/timetable_pdf_service.dart';
import '../database.dart';

class PdfExportService {
  final _cockpitService = TimetablePdfService();

  /// Export a complete timetable PDF with class-wise and teacher-wise pages.
  Future<void> exportTimetable(PlannerState planner) async {
    final db = planner.db;
    if (db == null) throw StateError('Database not available');

    await _cockpitService.printCockpitMasterPdf(db);
  }

  /// Build and return the PDF bytes without printing (for sharing).
  Future<void> shareAsPdf(AppDatabase db) async {
    final bytes = await _cockpitService.buildCockpitMasterPdf(db);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'SmartTime_Timetable.pdf',
    );
  }
}
