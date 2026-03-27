import 'package:flutter/material.dart';

/// Pivot mode for the same grid surface.
enum ViewMode { teacher, classView, room }

/// One X-axis slot. Break slots are rendered as shaded separators.
class PeriodSlot {
  final String id;
  final String label;
  final bool isBreak;
  final int? periodIndex;

  const PeriodSlot({
    required this.id,
    required this.label,
    this.isBreak = false,
    this.periodIndex,
  });
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
    this.onValidateMove,
  });

  final ViewMode viewMode;
  final List<String> rowLabels; // ex: Monday..Saturday
  final List<PeriodSlot> periods;

  /// Key format: `rowIndex|periodIndex`
  final Map<String, TimetableCellData> cells;
  final Future<String?> Function(String lessonId, int row, int col)? onMoveCell;
  final bool Function(String lessonId, int row, int col)? onValidateMove;

  static const double _headerH = 56;
  static const double _rowLabelW = 110;
  static const double _cellW = 152;
  static const double _breakW = 56;
  static const double _cellH = 98;

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
                  clipBehavior: Clip.none,
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
                onValidateMove: onValidateMove,
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

class TimetableDropCell extends StatefulWidget {
  const TimetableDropCell({
    super.key,
    required this.row,
    required this.col,
    required this.data,
    required this.onMoveCell,
    this.onValidateMove,
  });

  final int row;
  final int col;
  final TimetableCellData? data;
  final Future<String?> Function(String lessonId, int row, int col)? onMoveCell;
  final bool Function(String lessonId, int row, int col)? onValidateMove;

  @override
  State<TimetableDropCell> createState() => _TimetableDropCellState();
}

class _TimetableDropCellState extends State<TimetableDropCell> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.data != null;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true, // Accept on both empty & occupied cells
      onAcceptWithDetails: (details) async {
        final move = widget.onMoveCell;
        if (move == null) return;
        final error = await move(details.data, widget.row, widget.col);
        if (!context.mounted) return;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        if (!hasData) {
          // Empty cell
          Color bgColor = Colors.transparent;
          Color borderColor = Colors.transparent;

          if (isHovering) {
            final lessonId = candidateData.first;
            final isValid = widget.onValidateMove?.call(lessonId!, widget.row, widget.col) ?? true;
            
            if (isValid) {
              bgColor = const Color(0xFF4F46E5).withOpacity(0.3);
              borderColor = const Color(0xFF4F46E5);
            } else {
              bgColor = const Color(0xFF8B3A3A).withOpacity(0.3);
              borderColor = const Color(0xFF8B3A3A);
            }
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: const SizedBox.expand(),
          );
        }

        // Cell with data — draggable + accepts drops (for collision handling)
        return Stack(
          children: [
            LongPressDraggable<String>(
              data: widget.data!.id,
              onDragStarted: () => setState(() => _dragging = true),
              onDragEnd: (_) => setState(() => _dragging = false),
              onDraggableCanceled: (_, __) => setState(() => _dragging = false),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 140,
                  height: 86,
                  child: TimetableCell(data: widget.data!, isDragging: true),
                ),
              ),
              childWhenDragging:
                  Opacity(opacity: 0.20, child: TimetableCell(data: widget.data!)),
              child: TimetableCell(data: widget.data!, isDragging: _dragging),
            ),
            // Collision hover overlay
            if (isHovering)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.swap_horiz, color: Color(0xFFEF4444), size: 24),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TimetableCell extends StatelessWidget {
  const TimetableCell({super.key, required this.data, this.isDragging = false});

  final TimetableCellData data;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final accent = data.accent ?? const Color(0xFF4F46E5);

    return AnimatedScale(
      scale: isDragging ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: AnimatedOpacity(
        opacity: isDragging ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          elevation: isDragging ? 12 : 2,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withOpacity(0.90),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.primary,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        data.secondary,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  if (data.tertiary != null && data.tertiary!.isNotEmpty)
                    const SizedBox(height: 3),
                  if (data.tertiary != null && data.tertiary!.isNotEmpty)
                    Text(
                      data.tertiary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
          ),
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
        child: p.isBreak ? _breakHeaderBox(p.label) : _headerBox(p.label),
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
              color: p.isBreak ? const Color(0xFFEFE8FF) : null,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.7),
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.7),
              ),
            ),
            child: p.isBreak
                ? Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        p.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5D429E),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  )
                : null,
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

  Widget _breakHeaderBox(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE9DEFF),
        border: Border.all(color: const Color(0xFFCDB9FA), width: 0.8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4B2F85),
          letterSpacing: 0.2,
        ),
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
