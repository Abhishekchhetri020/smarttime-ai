// PDF Export Service — generates professional timetable PDFs with actual data.
//
// Delegates to TimetablePdfService which produces teacher-wise, class-wise,
// and room-wise pages from the Cards table in SQLite, or directly from
// solver results (TimetableAssignment list).

import 'package:printing/printing.dart';

import '../../features/admin/planner_state.dart';
import '../../features/timetable/data/timetable_pdf_service.dart';
import '../../features/timetable/presentation/controllers/solver_controller.dart';
import '../../features/timetable/timetable_display.dart';
import '../database.dart';

class PdfExportService {
  final _cockpitService = TimetablePdfService();

  /// Export a complete timetable PDF with class-wise, teacher-wise, and room-wise pages.
  Future<void> exportTimetable(PlannerState planner) async {
    final db = planner.db;
    if (db == null) throw StateError('Database not available');

    final schoolName = planner.schoolName;
    await _cockpitService.printCockpitMasterPdf(db, planner.dbId, schoolName: schoolName);
  }

  /// Build and return the PDF bytes without printing (for sharing).
  Future<void> shareAsPdf(AppDatabase db, int dbId, {String? schoolName}) async {
    final bytes = await _cockpitService.buildWorkbookPdf(
      db,
      dbId,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'SmartTime_Timetable.pdf',
    );
  }

  /// Export directly from solver results — no DB persistence required.
  Future<void> shareFromAssignments({
    required List<TimetableAssignment> assignments,
    required int days,
    required int periodsPerDay,
    required TimetableDisplayCatalog catalog,
    String schoolName = '',
  }) async {
    final bytes = await _cockpitService.buildFromAssignments(
      assignments: assignments,
      days: days,
      periodsPerDay: periodsPerDay,
      catalog: catalog,
      schoolName: schoolName,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'SmartTime_Timetable.pdf',
    );
  }
}
