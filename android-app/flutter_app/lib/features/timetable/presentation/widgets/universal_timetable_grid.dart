import 'package:flutter/material.dart';

/// Pivot mode for the same grid surface.
enum ViewMode { teacher, classView, room }

/// One X-axis slot. Break slots are rendered as shaded separators.
class PeriodSlot {
  final String id;
  final String label;
  final bool isBreak;

  const PeriodSlot(
      {required this.id, required this.label, this.isBreak = false});
}

/// One cell payload after view-mode pivoting.
///
/// Keep this UI model decoupled from Drift entities.
class TimetableCellData {
  final String id;
  final String primary; // subject
  final String secondary; // teacher/class abbreviation
  final String? tertiary; // room
  final Color? accent;

  const TimetableCellData({
    required this.id,
    required this.primary,
    required this.secondary,
    this.tertiary,
    this.accent,
  });
}

class UniversalTimetableGrid extends StatelessWidget {
  const UniversalTimetableGrid({
    super.key,
    required this.viewMode,
    required this.rowLabels,
    required this.periods,
    required this.cells,
    this.onMoveCell,
  });

  final ViewMode viewMode;
  final List<String> rowLabels; // ex: Monday..Saturday
  final List<PeriodSlot> periods;

  /// Key format: `rowIndex|periodIndex`
  final Map<String, TimetableCellData> cells;
  final Future<String?> Function(String lessonId, int row, int col)? onMoveCell;

  static const double _headerH = 42;
  static const double _rowLabelW = 86;
  static const double _cellW = 132;
  static const double _breakW = 16;
  static const double _cellH = 72;

  static String keyFor(int row, int col) => '$row|$col';

  @override
  Widget build(BuildContext context) {
    final totalGridWidth = periods.fold<double>(
        0, (sum, p) => sum + (p.isBreak ? _breakW : _cellW));
    final fullWidth = _rowLabelW + totalGridWidth;
    final fullHeight = _headerH + (rowLabels.length * _cellH);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _modeLabel(viewMode),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(220),
              child: SizedBox(
                width: fullWidth,
                height: fullHeight,
                child: Stack(
                  children: [
                    _GridBackdrop(
                      rowLabels: rowLabels,
                      periods: periods,
                      rowLabelW: _rowLabelW,
                      headerH: _headerH,
                      cellW: _cellW,
                      breakW: _breakW,
                      cellH: _cellH,
                    ),
                    ..._buildCells(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCells() {
    final out = <Widget>[];

    for (var r = 0; r < rowLabels.length; r++) {
      double x = _rowLabelW;
      for (var c = 0; c < periods.length; c++) {
        final slot = periods[c];
        final w = slot.isBreak ? _breakW : _cellW;
        if (!slot.isBreak) {
          final data = cells[keyFor(r, c)];
          out.add(
            Positioned(
              left: x + 3,
              top: _headerH + (r * _cellH) + 3,
              width: w - 6,
              height: _cellH - 6,
              child: TimetableDropCell(
                row: r,
                col: c,
                data: data,
                onMoveCell: onMoveCell,
              ),
            ),
          );
        }
        x += w;
      }
    }

    return out;
  }

  String _modeLabel(ViewMode mode) {
    switch (mode) {
      case ViewMode.teacher:
        return 'Teacher View';
      case ViewMode.classView:
        return 'Class View';
      case ViewMode.room:
        return 'Room View';
    }
  }
}

class TimetableDropCell extends StatelessWidget {
  const TimetableDropCell({
    super.key,
    required this.row,
    required this.col,
    required this.data,
    required this.onMoveCell,
  });

  final int row;
  final int col;
  final TimetableCellData? data;
  final Future<String?> Function(String lessonId, int row, int col)? onMoveCell;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => data == null,
      onAcceptWithDetails: (details) async {
        final move = onMoveCell;
        if (move == null) return;
        final error = await move(details.data, row, col);
        if (!context.mounted) return;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      },
      builder: (context, candidateData, rejectedData) {
        if (data == null) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox.expand(),
          );
        }
        return LongPressDraggable<String>(
          data: data!.id,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
                width: 126, height: 66, child: TimetableCell(data: data!)),
          ),
          childWhenDragging:
              Opacity(opacity: 0.25, child: TimetableCell(data: data!)),
          child: TimetableCell(data: data!),
        );
      },
    );
  }
}

class TimetableCell extends StatelessWidget {
  const TimetableCell({super.key, required this.data});

  final TimetableCellData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.accent ?? const Color(0xFF2B5EC8);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const Spacer(),
            if (data.tertiary != null && data.tertiary!.isNotEmpty)
              Text(
                data.tertiary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridBackdrop extends StatelessWidget {
  const _GridBackdrop({
    required this.rowLabels,
    required this.periods,
    required this.rowLabelW,
    required this.headerH,
    required this.cellW,
    required this.breakW,
    required this.cellH,
  });

  final List<String> rowLabels;
  final List<PeriodSlot> periods;
  final double rowLabelW;
  final double headerH;
  final double cellW;
  final double breakW;
  final double cellH;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // Top-left corner
    children.add(Positioned(
      left: 0,
      top: 0,
      width: rowLabelW,
      height: headerH,
      child: _headerBox('Day'),
    ));

    // Period headers + break markers
    double x = rowLabelW;
    for (final p in periods) {
      final w = p.isBreak ? breakW : cellW;
      children.add(Positioned(
        left: x,
        top: 0,
        width: w,
        height: headerH,
        child: p.isBreak
            ? Container(color: Colors.black.withValues(alpha: 0.06))
            : _headerBox(p.label),
      ));
      x += w;
    }

    // Day labels and grid body (with vertical break strips)
    for (var r = 0; r < rowLabels.length; r++) {
      final y = headerH + (r * cellH);
      children.add(Positioned(
        left: 0,
        top: y,
        width: rowLabelW,
        height: cellH,
        child: _rowLabelBox(rowLabels[r]),
      ));

      double gx = rowLabelW;
      for (final p in periods) {
        final w = p.isBreak ? breakW : cellW;
        children.add(Positioned(
          left: gx,
          top: y,
          width: w,
          height: cellH,
          child: Container(
            decoration: BoxDecoration(
              color: p.isBreak ? Colors.black.withValues(alpha: 0.06) : null,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.7),
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.7),
              ),
            ),
          ),
        ));
        gx += w;
      }
    }

    return Stack(children: children);
  }

  Widget _headerBox(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        border: Border.all(color: const Color(0xFFD6DCE5), width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _rowLabelBox(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        border: Border.all(color: const Color(0xFFD6DCE5), width: 0.8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
