import 'package:flutter/material.dart';

/// Pivot mode for the same grid surface.
enum ViewMode { teacher, classView, room }

/// One X-axis slot. Break slots are rendered as shaded separators.
class PeriodSlot {
  final String id;
  final String label;
  final bool isBreak;
  final int? periodIndex;
  /// Which day this slot belongs to (0-based). Used for day-group headers.
  final int? dayIndex;

  const PeriodSlot({
    required this.id,
    required this.label,
    this.isBreak = false,
    this.periodIndex,
    this.dayIndex,
  });
}

/// One cell payload after view-mode pivoting.
class TimetableCellData {
  final String id; // lesson ID (used for drag)
  final String cardId; // card DB ID (used for tap actions)
  final String primary; // subject
  final String secondary; // teacher/class abbreviation
  final String? tertiary; // room
  final Color? accent;

  const TimetableCellData({
    required this.id,
    required this.cardId,
    required this.primary,
    required this.secondary,
    this.tertiary,
    this.accent,
  });
}

/// Describes a day group spanning multiple period columns.
class DayGroup {
  final String label;
  final int startCol;
  final int colCount;
  const DayGroup({required this.label, required this.startCol, required this.colCount});
}

class UniversalTimetableGrid extends StatefulWidget {
  const UniversalTimetableGrid({
    super.key,
    required this.viewMode,
    required this.rowLabels,
    required this.periods,
    required this.cells,
    this.dayGroups = const [],
    this.cornerTitle,
    this.cornerCount,
    this.onMoveCell,
    this.onValidateMove,
    this.onTapCell,
    this.onTapRowLabel,
    this.lockedIds,
  });

  final ViewMode viewMode;
  final List<String> rowLabels;
  final List<PeriodSlot> periods;

  /// Key format: `rowIndex|colIndex`
  final Map<String, TimetableCellData> cells;

  /// Day grouping for two-level header (e.g. Mon spans cols 0-7, Tue spans 8-15).
  final List<DayGroup> dayGroups;

  /// Title shown in the corner (e.g. "Section", "Teacher").
  final String? cornerTitle;
  /// Count shown next to the title (e.g. 3).
  final int? cornerCount;

  final Future<String?> Function(String lessonId, int row, int col)? onMoveCell;
  final bool Function(String lessonId, int row, int col)? onValidateMove;
  final void Function(String cardId, String lessonId)? onTapCell;
  final void Function(int rowIndex, String rowLabel)? onTapRowLabel;
  final Set<String>? lockedIds;

  static const double _dayHeaderH = 36;
  static const double _periodHeaderH = 32;
  static const double _rowLabelW = 90;
  static const double _cellW = 120;
  static const double _breakW = 44;
  static const double _cellH = 72;

  static double get totalHeaderH => _dayHeaderH + _periodHeaderH;

  static String keyFor(int row, int col) => '$row|$col';

  @override
  State<UniversalTimetableGrid> createState() => _UniversalTimetableGridState();
}

class _UniversalTimetableGridState extends State<UniversalTimetableGrid> {
  final _transformCtrl = TransformationController();
  bool _initialFitDone = false;
  double _translateX = 0;
  double _translateY = 0;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformCtrl.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onTransformChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final m = _transformCtrl.value;
    final tx = m.getTranslation().x;
    final ty = m.getTranslation().y;
    final s = m.getMaxScaleOnAxis();
    if (tx != _translateX || ty != _translateY || s != _scale) {
      setState(() {
        _translateX = tx;
        _translateY = ty;
        _scale = s;
      });
    }
  }

  /// On first layout, scale the grid so the entire width fits the viewport.
  /// This makes all days visible immediately, matching Timetable Master UX.
  /// We prioritize width-fit because the grid can scroll vertically for rows.
  void _applyInitialFit(double viewportW, double viewportH) {
    final totalW = _totalGridWidth;
    if (totalW <= 0) return;

    // Scale to fit width — all days/periods visible on load
    final fitScale = (viewportW / totalW).clamp(0.15, 1.0);
    _transformCtrl.value = Matrix4.identity()..scale(fitScale, fitScale);
  }

  double get _totalGridWidth => widget.periods.fold<double>(
      0, (sum, p) => sum + (p.isBreak ? UniversalTimetableGrid._breakW : UniversalTimetableGrid._cellW));

  double get _totalGridHeight => widget.rowLabels.length * UniversalTimetableGrid._cellH;

  @override
  Widget build(BuildContext context) {
    const headerH = UniversalTimetableGrid._dayHeaderH + UniversalTimetableGrid._periodHeaderH;
    const rowLabelW = UniversalTimetableGrid._rowLabelW;
    final totalW = _totalGridWidth;
    final totalH = _totalGridHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate auto-fit on first build once we know the viewport size
        if (!_initialFitDone && widget.periods.isNotEmpty) {
          _initialFitDone = true;
          final viewportW = constraints.maxWidth - rowLabelW;
          final viewportH = constraints.maxHeight - headerH;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyInitialFit(viewportW, viewportH);
          });
        }

        return Stack(
          children: [
            // ── Main scrollable grid (bottom-right) ──
            Positioned(
              left: rowLabelW,
              top: headerH,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: InteractiveViewer(
                  constrained: false,
                  minScale: 0.15,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(80),
                  transformationController: _transformCtrl,
                  child: SizedBox(
                    width: totalW,
                    height: totalH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _GridBody(
                          rowLabels: widget.rowLabels,
                          periods: widget.periods,
                          cellW: UniversalTimetableGrid._cellW,
                          breakW: UniversalTimetableGrid._breakW,
                          cellH: UniversalTimetableGrid._cellH,
                        ),
                        ..._buildCells(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Sticky two-level column header (top-right) ──
            Positioned(
              left: rowLabelW,
              top: 0,
              right: 0,
              height: headerH,
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(_translateX, 0.0)
                    ..scale(_scale, _scale),
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: totalW,
                    height: headerH,
                    child: _TwoLevelHeader(
                      periods: widget.periods,
                      dayGroups: widget.dayGroups,
                      cellW: UniversalTimetableGrid._cellW,
                      breakW: UniversalTimetableGrid._breakW,
                      dayHeaderH: UniversalTimetableGrid._dayHeaderH,
                      periodHeaderH: UniversalTimetableGrid._periodHeaderH,
                    ),
                  ),
                ),
              ),
            ),

            // ── Sticky row labels (bottom-left) ──
            Positioned(
              left: 0,
              top: headerH,
              width: rowLabelW,
              bottom: 0,
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(0.0, _translateY)
                    ..scale(_scale, _scale),
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: rowLabelW,
                    height: totalH,
                    child: _RowLabelColumn(
                      rowLabels: widget.rowLabels,
                      cellH: UniversalTimetableGrid._cellH,
                      rowLabelW: rowLabelW,
                      onTapRowLabel: widget.onTapRowLabel,
                    ),
                  ),
                ),
              ),
            ),

            // ── Static corner cell (top-left) ──
            Positioned(
              left: 0,
              top: 0,
              width: rowLabelW,
              height: headerH,
              child: _CornerCell(
                title: widget.cornerTitle,
                count: widget.cornerCount,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCells() {
    final out = <Widget>[];
    for (var r = 0; r < widget.rowLabels.length; r++) {
      double x = 0;
      for (var c = 0; c < widget.periods.length; c++) {
        final slot = widget.periods[c];
        final w = slot.isBreak ? UniversalTimetableGrid._breakW : UniversalTimetableGrid._cellW;
        if (!slot.isBreak) {
          final data = widget.cells[UniversalTimetableGrid.keyFor(r, c)];
          out.add(
            Positioned(
              left: x + 2,
              top: (r * UniversalTimetableGrid._cellH) + 2,
              width: w - 4,
              height: UniversalTimetableGrid._cellH - 4,
              child: TimetableDropCell(
                row: r,
                col: c,
                data: data,
                onMoveCell: widget.onMoveCell,
                onValidateMove: widget.onValidateMove,
                onTapCell: widget.onTapCell,
                isLocked: data != null && (widget.lockedIds?.contains(data.cardId) ?? false),
              ),
            ),
          );
        }
        x += w;
      }
    }
    return out;
  }
}

// ─── Corner Cell ─────────────────────────────────────────────────────────────

class _CornerCell extends StatelessWidget {
  const _CornerCell({this.title, this.count});
  final String? title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.8),
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title ?? 'Section',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                if (count != null)
                  Text(
                    ' ($count)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            // Search hint
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text('Search...', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Two-Level Header (Day row + Period row) ─────────────────────────────────

class _TwoLevelHeader extends StatelessWidget {
  const _TwoLevelHeader({
    required this.periods,
    required this.dayGroups,
    required this.cellW,
    required this.breakW,
    required this.dayHeaderH,
    required this.periodHeaderH,
  });
  final List<PeriodSlot> periods;
  final List<DayGroup> dayGroups;
  final double cellW;
  final double breakW;
  final double dayHeaderH;
  final double periodHeaderH;

  @override
  Widget build(BuildContext context) {
    // Pre-compute column X offsets
    final colX = <double>[];
    double x = 0;
    for (final p in periods) {
      colX.add(x);
      x += p.isBreak ? breakW : cellW;
    }

    return Stack(
      children: [
        // ── Day name row (top) ──
        for (final dg in dayGroups)
          Positioned(
            left: _colLeft(colX, dg.startCol),
            top: 0,
            width: _colSpanWidth(colX, dg.startCol, dg.colCount),
            height: dayHeaderH,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
                  right: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
              ),
              child: Text(
                dg.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        // If no dayGroups provided, show a single row
        if (dayGroups.isEmpty)
          Positioned(
            left: 0, top: 0, width: x, height: dayHeaderH,
            child: Container(color: Colors.white),
          ),
        // ── Period time row (bottom) ──
        for (var i = 0; i < periods.length; i++)
          Positioned(
            left: colX[i],
            top: dayHeaderH,
            width: periods[i].isBreak ? breakW : cellW,
            height: periodHeaderH,
            child: periods[i].isBreak
                ? _breakHeader(periods[i].label)
                : _periodHeader(periods[i].label),
          ),
      ],
    );
  }

  double _colLeft(List<double> colX, int col) =>
      col < colX.length ? colX[col] : 0;

  double _colSpanWidth(List<double> colX, int startCol, int count) {
    if (startCol >= colX.length) return 0;
    double w = 0;
    for (var i = startCol; i < startCol + count && i < periods.length; i++) {
      w += periods[i].isBreak ? breakW : cellW;
    }
    return w;
  }

  Widget _periodHeader(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
      ),
    );
  }

  Widget _breakHeader(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5FF),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
          right: BorderSide(color: const Color(0xFFCDB9FA), width: 0.5),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B4DB5),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Row Label Column ────────────────────────────────────────────────────────

class _RowLabelColumn extends StatelessWidget {
  const _RowLabelColumn({
    required this.rowLabels,
    required this.cellH,
    required this.rowLabelW,
    this.onTapRowLabel,
  });
  final List<String> rowLabels;
  final double cellH;
  final double rowLabelW;
  final void Function(int rowIndex, String rowLabel)? onTapRowLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var r = 0; r < rowLabels.length; r++)
          Positioned(
            left: 0, top: r * cellH, width: rowLabelW, height: cellH,
            child: _rowLabelBox(rowLabels[r], r),
          ),
      ],
    );
  }

  Widget _rowLabelBox(String label, int rowIndex) {
    return GestureDetector(
      onTap: onTapRowLabel != null ? () => onTapRowLabel!(rowIndex, label) : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.8),
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onTapRowLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.menu, size: 14, color: Colors.grey.shade400),
              ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Body ───────────────────────────────────────────────────────────────

class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.rowLabels,
    required this.periods,
    required this.cellW,
    required this.breakW,
    required this.cellH,
  });

  final List<String> rowLabels;
  final List<PeriodSlot> periods;
  final double cellW;
  final double breakW;
  final double cellH;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var r = 0; r < rowLabels.length; r++) {
      final y = r * cellH;
      double gx = 0;
      for (final p in periods) {
        final w = p.isBreak ? breakW : cellW;
        children.add(Positioned(
          left: gx, top: y, width: w, height: cellH,
          child: Container(
            decoration: BoxDecoration(
              color: p.isBreak ? const Color(0xFFF3EDFF) : null,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
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
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF6B4DB5)),
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
}

// ─── Drop Cell ───────────────────────────────────────────────────────────────

class TimetableDropCell extends StatefulWidget {
  const TimetableDropCell({
    super.key,
    required this.row,
    required this.col,
    required this.data,
    required this.onMoveCell,
    this.onValidateMove,
    this.onTapCell,
    this.isLocked = false,
  });

  final int row;
  final int col;
  final TimetableCellData? data;
  final Future<String?> Function(String lessonId, int row, int col)? onMoveCell;
  final bool Function(String lessonId, int row, int col)? onValidateMove;
  final void Function(String cardId, String lessonId)? onTapCell;
  final bool isLocked;

  @override
  State<TimetableDropCell> createState() => _TimetableDropCellState();
}

class _TimetableDropCellState extends State<TimetableDropCell> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.data != null;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) async {
        final move = widget.onMoveCell;
        if (move == null) return;
        final error = await move(details.data, widget.row, widget.col);
        if (!context.mounted) return;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        if (!hasData) {
          Color bgColor = Colors.transparent;
          Color borderColor = Colors.transparent;
          if (isHovering) {
            final lessonId = candidateData.first;
            final isValid = widget.onValidateMove?.call(lessonId!, widget.row, widget.col) ?? true;
            if (isValid) {
              bgColor = const Color(0xFF4F46E5).withValues(alpha: 0.3);
              borderColor = const Color(0xFF4F46E5);
            } else {
              bgColor = const Color(0xFF8B3A3A).withValues(alpha: 0.3);
              borderColor = const Color(0xFF8B3A3A);
            }
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: const SizedBox.expand(),
          );
        }

        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.onTapCell != null && widget.data != null) {
                  widget.onTapCell!(widget.data!.cardId, widget.data!.id);
                }
              },
              child: LongPressDraggable<String>(
                data: widget.data!.id,
                onDragStarted: () => setState(() => _dragging = true),
                onDragEnd: (_) => setState(() => _dragging = false),
                onDraggableCanceled: (_, __) => setState(() => _dragging = false),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 110,
                    height: 64,
                    child: TimetableCell(data: widget.data!, isDragging: true),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.20, child: TimetableCell(data: widget.data!)),
                child: TimetableCell(data: widget.data!, isDragging: _dragging, isLocked: widget.isLocked),
              ),
            ),
            if (isHovering)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEF4444), width: 2),
                  ),
                  child: const Center(child: Icon(Icons.swap_horiz, color: Color(0xFFEF4444), size: 20)),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Timetable Cell ──────────────────────────────────────────────────────────

class TimetableCell extends StatelessWidget {
  const TimetableCell({
    super.key,
    required this.data,
    this.isDragging = false,
    this.isLocked = false,
  });

  final TimetableCellData data;
  final bool isDragging;
  final bool isLocked;

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
          elevation: isDragging ? 12 : 1.5,
          shadowColor: Colors.black45,
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isLocked ? Colors.amber.shade300 : Colors.black12,
                    width: isLocked ? 2.0 : 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.primary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            data.secondary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
