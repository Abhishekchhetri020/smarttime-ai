import 'package:flutter/material.dart';

import '../../../../core/database.dart';
import '../../data/timetable_pdf_service.dart';
import '../../data/timetable_service.dart';
import '../../timetable_display.dart';
import '../widgets/universal_timetable_grid.dart';

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  ViewMode _mode = ViewMode.classView;
  final _service = TimetableService();
  final _pdfService = TimetablePdfService();

  static const _days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Stream<_CockpitVm> _vmStream() {
    return widget.db.select(widget.db.cards).watch().asyncMap((cards) async {
      final lessons = await widget.db.select(widget.db.lessons).get();
      final subjects = await widget.db.select(widget.db.subjects).get();
      final teachers = await widget.db.select(widget.db.teachers).get();
      final classes = await widget.db.select(widget.db.classes).get();

      final lessonById = {for (final l in lessons) l.id: l};
      final plannerSnap = await widget.db.loadPlannerSnapshot();
      final catalog = TimetableDisplayCatalog.fromDatabase(
        subjects: subjects,
        teachers: teachers,
        classes: classes,
        plannerSnapshot: plannerSnap,
      );
      final periods = buildTimetableSlots(
        plannerSnapshot: plannerSnap,
        usedPeriodIndexes: cards.map((card) => card.periodIndex),
      )
          .map(
            (slot) => PeriodSlot(
              id: slot.id,
              label: slot.label,
              isBreak: slot.isBreak,
              periodIndex: slot.periodIndex,
            ),
          )
          .toList(growable: false);
      final periodColumnByPeriodIndex = <int, int>{};
      for (var i = 0; i < periods.length; i++) {
        final p = periods[i];
        final idx = p.periodIndex;
        if (idx != null) {
          periodColumnByPeriodIndex[idx] = i;
        }
      }

      final cells = <String, TimetableCellData>{};
      for (final c in cards) {
        final lesson = lessonById[c.lessonId];
        if (lesson == null) continue;

        final row = c.dayIndex.clamp(0, _days.length - 1);
        final col = periodColumnByPeriodIndex[c.periodIndex];
        if (col == null) continue;

        final subject = catalog.subjectLabel(lesson.subjectId);
        final teacherAbbr = catalog.joinTeacherLabels(lesson.teacherIds);
        final classAbbr = catalog.joinClassLabels(lesson.classIds);

        final secondary = switch (_mode) {
          ViewMode.teacher => classAbbr,
          ViewMode.classView => teacherAbbr,
          ViewMode.room => [classAbbr, teacherAbbr]
              .where((value) => value.trim().isNotEmpty)
              .join(' / '),
        };

        cells[UniversalTimetableGrid.keyFor(row, col)] = TimetableCellData(
          id: lesson.id,
          primary: subject,
          secondary: secondary,
          tertiary: catalog.roomLabel(c.roomId),
          accent: _subjectAccent(catalog.subjectColor(lesson.subjectId)),
        );
      }

      return _CockpitVm(cells: cells, periods: periods);
    });
  }

  int? _periodIndexFromColumn(List<PeriodSlot> periods, int col) {
    if (col < 0 || col >= periods.length) return null;
    final slot = periods[col];
    return slot.periodIndex;
  }

  Future<String?> _moveLessonValidated(
      String lessonId, int row, int col, List<PeriodSlot> periods) async {
    final periodIndex = _periodIndexFromColumn(periods, col);
    if (periodIndex == null) return 'Cannot drop onto a break column.';
    final result = await _service.moveLessonValidated(
        widget.db, lessonId, '$row:$periodIndex');
    return switch (result) {
      MoveLessonSuccess() => null,
      MoveLessonTeacherConflict(:final message) => message,
      MoveLessonClassConflict(:final message) => message,
      MoveLessonRoomConflict(:final message) => message,
      MoveLessonNotFound(:final message) => message,
    };
  }

  Future<void> _printMasterPdf() async {
    await _pdfService.printCockpitMasterPdf(widget.db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cockpit'),
        actions: [
          IconButton(
            tooltip: 'Download/Print PDF',
            onPressed: _printMasterPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ModeTab(
                    label: 'Teacher',
                    selected: _mode == ViewMode.teacher,
                    onTap: () => setState(() => _mode = ViewMode.teacher),
                  ),
                  const SizedBox(width: 8),
                  _ModeTab(
                    label: 'Class',
                    selected: _mode == ViewMode.classView,
                    onTap: () => setState(() => _mode = ViewMode.classView),
                  ),
                  const SizedBox(width: 8),
                  _ModeTab(
                    label: 'Room',
                    selected: _mode == ViewMode.room,
                    onTap: () => setState(() => _mode = ViewMode.room),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<_CockpitVm>(
                stream: _vmStream(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.data!.cells.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.calendar_month_outlined, size: 52),
                          SizedBox(height: 12),
                          Text(
                            'No Schedule Generated Yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Run Pre-Flight and generate a schedule to view the cockpit.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  final vm = snap.data!;
                  return UniversalTimetableGrid(
                    viewMode: _mode,
                    rowLabels: _days,
                    periods: vm.periods,
                    cells: vm.cells,
                    onMoveCell: (lessonId, row, col) =>
                        _moveLessonValidated(lessonId, row, col, vm.periods),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CockpitVm {
  final Map<String, TimetableCellData> cells;
  final List<PeriodSlot> periods;

  const _CockpitVm({required this.cells, required this.periods});
}

Color? _subjectAccent(int? rawColor) {
  if (rawColor == null) return null;
  return Color(rawColor);
}

class _ModeTab extends StatelessWidget {
  const _ModeTab(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
