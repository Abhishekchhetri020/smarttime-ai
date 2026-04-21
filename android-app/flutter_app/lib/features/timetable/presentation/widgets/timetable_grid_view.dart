import 'package:flutter/material.dart';

import '../controllers/solver_controller.dart';
import '../../timetable_display.dart';
import '../../../../core/theme/app_theme.dart';

enum ExportOption { pdf, excel, csv, print }

class TimetableGridView extends StatelessWidget {
  const TimetableGridView({
    super.key,
    required this.assignments,
    required this.days,
    required this.periodsPerDay,
    this.onExportSelected,
    this.onRunSolver,
  });

  final List<TimetableAssignment> assignments;
  final int days;
  final int periodsPerDay;
  final ValueChanged<ExportOption>? onExportSelected;
  final VoidCallback? onRunSolver;

  static const double _cellW = 120;
  static const double _cellH = 72;

  @override
  Widget build(BuildContext context) {
    final width = days * _cellW;
    final height = periodsPerDay * _cellH;

    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            PopupMenuButton<ExportOption>(
              tooltip: 'Export Options',
              onSelected: onExportSelected,
              itemBuilder: (context) => const [
                PopupMenuItem(
                    value: ExportOption.pdf,
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('Export as PDF'),
                      subtitle: Text('Class / Teacher / Room views'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
                PopupMenuItem(
                    value: ExportOption.excel,
                    child: ListTile(
                      leading: Icon(Icons.table_chart),
                      title: Text('Export as Excel'),
                      subtitle: Text('Sheets per class, teacher, room'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
                PopupMenuItem(
                    value: ExportOption.csv,
                    child: ListTile(
                      leading: Icon(Icons.description_outlined),
                      title: Text('Export as CSV'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
                PopupMenuItem(
                    value: ExportOption.print,
                    child: ListTile(
                      leading: Icon(Icons.print),
                      title: Text('Print'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ios_share),
                    SizedBox(width: 6),
                    Text('Export Options'),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (assignments.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart_outlined,
                      size: 72, color: Colors.grey.shade500),
                  const SizedBox(height: 12),
                  const Text('Ready to Generate',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text(
                      'No assignments yet. Run solver to populate the timetable.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onRunSolver,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Solver'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(180),
              constrained: false,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: _GridPainter(days: days, periods: periodsPerDay),
                    ),
                    ...assignments.map((a) => Positioned(
                          left: (a.day - 1) * _cellW,
                          top: (a.period - 1) * _cellH,
                          width: _cellW,
                          height: _cellH,
                          child: _LessonCard(a: a),
                        )),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Color subjectColor(String subjectId) {
    final colors = [
      AppTheme.indigo,
      AppTheme.successGreen,
      AppTheme.warningOrange,
      AppTheme.accentAmber.withOpacity(0.9),
      Colors.cyan.shade600,
      AppTheme.indigoDark,
      AppTheme.errorRed,
      AppTheme.slate800,
    ];
    final idx = subjectId.hashCode.abs() % colors.length;
    return colors[idx];
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.days, required this.periods});

  final int days;
  final int periods;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    for (var d = 0; d <= days; d++) {
      final x = d * TimetableGridView._cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var p = 0; p <= periods; p++) {
      final y = p * TimetableGridView._cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.days != days || oldDelegate.periods != periods;
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.a});

  final TimetableAssignment a;
  static const _catalog = TimetableDisplayCatalog();

  @override
  Widget build(BuildContext context) {
    final color = TimetableGridView.subjectColor(a.subjectId);
    final subject = _catalog.subjectLabel(a.subjectId);
    final teachers = _catalog.joinTeacherLabels(a.teacherIds);
    final classes = _catalog.joinClassLabels(a.classIds);
    final room = _catalog.roomLabel(a.roomId);

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF5E7FB4), width: 1.0),
          right: BorderSide(color: Color(0xFF5E7FB4), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black, fontSize: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (teachers.isNotEmpty)
              Text(teachers,
                  style: const TextStyle(fontSize: 10, color: Colors.black87)),
            if (classes.isNotEmpty)
              Text(classes,
                  style: const TextStyle(fontSize: 10, color: Colors.black87)),
            if (room != null && room.isNotEmpty)
              Text(room,
                  style: const TextStyle(fontSize: 10, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
