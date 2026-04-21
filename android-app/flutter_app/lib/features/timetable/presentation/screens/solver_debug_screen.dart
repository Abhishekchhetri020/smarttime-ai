import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/excel_export_service.dart';
import '../../../admin/planner_state.dart';
import '../../data/conflict_service.dart';
import '../../data/csv_export_service.dart';
import '../../data/native_solver_client.dart';
import '../../data/solver_payload_mapper.dart';
import '../../data/timetable_pdf_service.dart';
import '../../timetable_display.dart';
import '../controllers/solver_controller.dart';
import '../widgets/preflight_warnings_panel.dart';
import '../widgets/timetable_grid_view.dart';

class SolverDebugScreen extends StatefulWidget {
  const SolverDebugScreen({super.key});

  @override
  State<SolverDebugScreen> createState() => _SolverDebugScreenState();
}

class _SolverDebugScreenState extends State<SolverDebugScreen> {
  late final SolverController controller;
  final _pdf = TimetablePdfService();
  final _csv = CsvExportService();
  final _excel = ExcelExportService();

  @override
  void initState() {
    super.initState();
    controller = SolverController(
      client: NativeSolverClient(),
      mapper: SolverPayloadMapper(),
      conflictService: ConflictService(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Build a catalog from the current PlannerState for label resolution.
  TimetableDisplayCatalog _buildCatalog(PlannerState planner) {
    return TimetableDisplayCatalog(
      subjectById: {
        for (final s in planner.subjects)
          s.id: s.abbr.isNotEmpty ? s.abbr : s.name,
      },
      teacherById: {
        for (final t in planner.teachers)
          t.id: t.abbr.isNotEmpty ? t.abbr : t.firstName,
      },
      classById: {
        for (final c in planner.classes)
          c.id: c.abbr.isNotEmpty ? c.abbr : c.name,
      },
      roomById: {
        for (final r in planner.classrooms) r.id: r.name,
      },
    );
  }

  Future<void> _onExport(ExportOption option, PlannerState planner) async {
    if (controller.assignments.isEmpty) return;

    final catalog = _buildCatalog(planner);

    if (option == ExportOption.pdf) {
      // Full multi-view PDF: class-wise + teacher-wise + room-wise pages.
      final bytes = await _pdf.buildFromAssignments(
        assignments: controller.assignments,
        days: planner.workingDays,
        periodsPerDay: planner.bellTimes.length,
        catalog: catalog,
        schoolName: planner.schoolName,
      );
      await _pdf.sharePdf(bytes, filename: 'SmartTime_Timetable.pdf');
    } else if (option == ExportOption.excel) {
      // Full multi-sheet Excel: master + class + teacher + room sheets.
      await _excel.exportAndShareFromAssignments(
        assignments: controller.assignments,
        days: planner.workingDays,
        periodsPerDay: planner.bellTimes.length,
        catalog: catalog,
      );
    } else if (option == ExportOption.print) {
      final bytes = await _pdf.buildFromAssignments(
        assignments: controller.assignments,
        days: planner.workingDays,
        periodsPerDay: planner.bellTimes.length,
        catalog: catalog,
        schoolName: planner.schoolName,
      );
      await _pdf.printPdf(bytes);
    } else {
      // CSV fallback.
      final csv = _csv.buildAssignmentsCsv(controller.assignments);
      final bytes = Uint8List.fromList(csv.codeUnits);
      await _pdf.sharePdf(bytes, filename: 'timetable.csv');
    }
  }

  void _jumpToConflict(PreflightWarning warning) {
    final msg = 'Jump to ${warning.targetType}:${warning.targetId}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPdfPreview(PlannerState planner) async {
    final catalog = _buildCatalog(planner);
    final bytes = await _pdf.buildFromAssignments(
      assignments: controller.assignments,
      days: planner.workingDays,
      periodsPerDay: planner.bellTimes.length,
      catalog: catalog,
      schoolName: planner.schoolName,
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 900,
          height: 640,
          child: PdfPreview(
            canChangePageFormat: false,
            canDebug: false,
            build: (_) async => bytes,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final warnings = ConflictService().preflight(planner);

    return Scaffold(
      appBar: AppBar(title: const Text('Solver Grid Debug')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.run(planner);
                              if (!context.mounted) return;
                              if (controller.status == 'SEED_NOT_FOUND' ||
                                  controller.status ==
                                      'SEED_INFEASIBLE_INPUT') {
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: Text(
                                        controller.status == 'SEED_NOT_FOUND'
                                            ? 'No feasible seed found'
                                            : 'Infeasible input'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Likely causes:'),
                                        const SizedBox(height: 6),
                                        for (final h in controller.failureHints)
                                          Text('• $h'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (controller.status == 'SUCCESS' ||
                                  controller.status == 'SEED_FOUND') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '✅ Timetable generated successfully')),
                                );
                                await _openPdfPreview(planner);
                              }
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                          controller.isLoading ? 'Running...' : 'Run Solver'),
                    ),
                    const SizedBox(width: 12),
                    if (controller.status != null)
                      Text('Status: ${controller.status}'),
                  ],
                ),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 8),
                PreflightWarningsPanel(
                    warnings: warnings, onJump: _jumpToConflict),
                const SizedBox(height: 8),
                Expanded(
                  child: TimetableGridView(
                    assignments: controller.assignments,
                    days: planner.workingDays,
                    periodsPerDay: planner.bellTimes.length,
                    onExportSelected: (o) => _onExport(o, planner),
                    onRunSolver: controller.isLoading
                        ? null
                        : () => controller.run(planner),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
