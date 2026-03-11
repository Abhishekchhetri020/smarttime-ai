import 'package:flutter/material.dart';

import '../../../../core/database.dart';
import '../../data/timetable_pdf_service.dart';
import '../../data/timetable_service.dart';
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
  static const _periods = <PeriodSlot>[
    PeriodSlot(id: 'p1', label: 'P1'),
    PeriodSlot(id: 'p2', label: 'P2'),
    PeriodSlot(id: 'p3', label: 'P3'),
    PeriodSlot(id: 'br1', label: 'Break', isBreak: true),
    PeriodSlot(id: 'p4', label: 'P4'),
    PeriodSlot(id: 'p5', label: 'P5'),
    PeriodSlot(id: 'p6', label: 'P6'),
    PeriodSlot(id: 'p7', label: 'P7'),
  ];

  Stream<_CockpitVm> _vmStream() {
    return widget.db.select(widget.db.cards).watch().asyncMap((cards) async {
      final lessons = await widget.db.select(widget.db.lessons).get();
      final subjects = await widget.db.select(widget.db.subjects).get();
      final teachers = await widget.db.select(widget.db.teachers).get();
      final classes = await widget.db.select(widget.db.classes).get();

      final subjectById = {for (final s in subjects) s.id: s};
      final teacherById = {for (final t in teachers) t.id: t};
      final classById = {for (final c in classes) c.id: c};
      final lessonById = {for (final l in lessons) l.id: l};

      final cells = <String, TimetableCellData>{};
      for (final c in cards) {
        final lesson = lessonById[c.lessonId];
        if (lesson == null) continue;

        final row = c.dayIndex.clamp(0, _days.length - 1);
        final col = _periodColumnFromPeriodIndex(c.periodIndex);
        if (col < 0) continue;

        final subject = subjectById[lesson.subjectId]?.abbr ?? lesson.subjectId;
        final teacherAbbr = lesson.teacherIds
            .map((id) => teacherById[id]?.abbreviation ?? id)
            .join(', ');
        final classAbbr =
            lesson.classIds.map((id) => classById[id]?.abbr ?? id).join(', ');

        final secondary = switch (_mode) {
          ViewMode.teacher => classAbbr,
          ViewMode.classView => teacherAbbr,
          ViewMode.room => '$classAbbr / $teacherAbbr',
        };

        cells[UniversalTimetableGrid.keyFor(row, col)] = TimetableCellData(
          id: lesson.id,
          primary: subject,
          secondary: secondary,
          tertiary: c.roomId,
        );
      }

      return _CockpitVm(cells);
    });
  }

  int _periodColumnFromPeriodIndex(int periodIndex) {
    // We render a break column after P3, so shift periods >=3 by +1.
    if (periodIndex < 0) return -1;
    if (periodIndex >= 3) return periodIndex + 1;
    return periodIndex;
  }

  int? _periodIndexFromColumn(int col) {
    if (col < 0 || col >= _periods.length) return null;
    final slot = _periods[col];
    if (slot.isBreak) return null;
    if (col >= 4) return col - 1;
    return col;
  }

  Future<String?> _moveLessonValidated(
      String lessonId, int row, int col) async {
    final periodIndex = _periodIndexFromColumn(col);
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
                  return UniversalTimetableGrid(
                    viewMode: _mode,
                    rowLabels: _days,
                    periods: _periods,
                    cells: snap.data!.cells,
                    onMoveCell: _moveLessonValidated,
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

  const _CockpitVm(this.cells);
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
