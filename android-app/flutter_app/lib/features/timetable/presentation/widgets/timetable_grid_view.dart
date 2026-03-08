import 'package:flutter/material.dart';

import '../controllers/solver_controller.dart';

enum ExportOption { pdf, csv, print }

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
                PopupMenuItem(value: ExportOption.pdf, child: Text('Save as PDF')),
                PopupMenuItem(value: ExportOption.csv, child: Text('Save as Excel (CSV)')),
                PopupMenuItem(value: ExportOption.print, child: Text('Print')),
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
                  Icon(Icons.table_chart_outlined, size: 72, color: Colors.grey.shade500),
                  const SizedBox(height: 12),
                  const Text('Ready to Generate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('No assignments yet. Run solver to populate the timetable.'),
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
                        left: (a.day - 1) * _cellW + 4,
                        top: (a.period - 1) * _cellH + 4,
                        width: _cellW - 8,
                        height: _cellH - 8,
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
      const Color(0xFF4F46E5),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
      const Color(0xFF0284C7),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
      const Color(0xFF0891B2),
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

  @override
  Widget build(BuildContext context) {
    final color = TimetableGridView.subjectColor(a.subjectId);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(6),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.subjectId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text('T:${a.teacherIds.join(',')}'),
            Text('C:${a.classIds.join(',')}'),
          ],
        ),
      ),
    );
  }
}
