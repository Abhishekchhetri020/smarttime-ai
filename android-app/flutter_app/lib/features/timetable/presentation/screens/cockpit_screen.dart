import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../../core/database.dart';
import '../../../../core/services/excel_export_service.dart';
import '../../../../core/solver/solver_engine.dart';
import '../../../../core/solver/solver_models.dart';
import '../../data/timetable_pdf_service.dart';
import '../../data/timetable_service.dart';
import '../../timetable_display.dart';
import '../widgets/filter_unscheduled_sheet.dart';
import '../widgets/generation_insights_sheet.dart';
import '../widgets/universal_timetable_grid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cockpit Screen – Phase 22 overhaul
// ─────────────────────────────────────────────────────────────────────────────

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key, required this.db, required this.dbId});

  final AppDatabase db;
  final int dbId;

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  ViewMode _mode = ViewMode.classView;
  final _service = TimetableService();
  final _pdfService = TimetablePdfService();
  final _excelService = ExcelExportService();

  String? _selectedTeacherId;
  String? _selectedClassId;
  String? _selectedRoomId;

  // Lock tracking (in-memory)
  final Set<String> _lockedCardIds = {};

  // Bottom bar
  bool _bottomExpanded = true;

  // ── Data stream ──────────────────────────────────────────────────────────

  Stream<_CockpitVm> _vmStream() {
    return widget.db.select(widget.db.cards).watch().asyncMap((cards) async {
      final lessons = await widget.db.select(widget.db.lessons).get();
      final subjects = await widget.db.select(widget.db.subjects).get();
      final teachers = await widget.db.select(widget.db.teachers).get();
      final classes = await widget.db.select(widget.db.classes).get();

      final lessonById = {for (final l in lessons) l.id: l};
      final plannerSnap = await widget.db.loadPlannerSnapshot(widget.dbId);
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

      // Build grid cells
      final cells = <String, TimetableCellData>{};
      final workingDays = (plannerSnap?['workingDays'] as int?) ?? 6;

      for (final c in cards) {
        final lesson = lessonById[c.lessonId];
        if (lesson == null) continue;
        if (_mode == ViewMode.teacher && _selectedTeacherId != null) {
          if (!lesson.teacherIds.contains(_selectedTeacherId)) continue;
        } else if (_mode == ViewMode.classView && _selectedClassId != null) {
          if (!lesson.classIds.contains(_selectedClassId)) continue;
        } else if (_mode == ViewMode.room && _selectedRoomId != null) {
          if (c.roomId != _selectedRoomId) continue;
        }

        final row = c.dayIndex.clamp(0, workingDays - 1);
        final col = periodColumnByPeriodIndex[c.periodIndex];
        if (col == null) continue;

        final subject = catalog.subjectLabel(lesson.subjectId);
        final teacherAbbr = catalog.joinTeacherLabels(lesson.teacherIds);
        final classAbbr = catalog.joinClassLabels(lesson.classIds);
        final secondary = switch (_mode) {
          ViewMode.teacher => classAbbr,
          ViewMode.classView => teacherAbbr,
          ViewMode.room => [classAbbr, teacherAbbr]
              .where((v) => v.trim().isNotEmpty)
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

      // Compute unscheduled lessons
      final cardCountByLesson = <String, int>{};
      for (final c in cards) {
        cardCountByLesson[c.lessonId] =
            (cardCountByLesson[c.lessonId] ?? 0) + 1;
      }
      final unscheduled = <_UnscheduledLesson>[];
      for (final l in lessons) {
        final scheduled = cardCountByLesson[l.id] ?? 0;
        final needed = l.periodsPerWeek;
        if (scheduled < needed) {
          final remaining = needed - scheduled;
          unscheduled.add(_UnscheduledLesson(
            lessonId: l.id,
            subjectLabel: catalog.subjectLabel(l.subjectId),
            teacherLabel: catalog.joinTeacherLabels(l.teacherIds),
            roomLabel: _firstRoom(cards, l.id, catalog),
            remaining: remaining,
            accent: _subjectAccent(catalog.subjectColor(l.subjectId)),
          ));
        }
      }

      return _CockpitVm(
        cells: cells,
        periods: periods,
        teachers: teachers.toList(),
        classes: classes.toList(),
        subjects: subjects.toList(),
        rooms:
            (plannerSnap?['classrooms'] as List<dynamic>?) ?? [],
        unscheduled: unscheduled,
        totalCards: cards.length,
        totalRequired: lessons.fold<int>(0, (s, l) => s + l.periodsPerWeek),
        workingDays: workingDays,
      );
    });
  }

  String? _firstRoom(
      List<CardRow> cards, String lessonId, TimetableDisplayCatalog catalog) {
    for (final c in cards) {
      if (c.lessonId == lessonId && c.roomId != null) {
        return catalog.roomLabel(c.roomId);
      }
    }
    return null;
  }

  static const _allDays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<String> _activeDays(int workingDays) {
    return _allDays.sublist(0, workingDays.clamp(1, 7));
  }

  int? _periodIndexFromColumn(List<PeriodSlot> periods, int col) {
    if (col < 0 || col >= periods.length) return null;
    return periods[col].periodIndex;
  }

  Future<String?> _moveLessonValidated(
      String lessonId, int row, int col, List<PeriodSlot> periods) async {
    final periodIndex = _periodIndexFromColumn(periods, col);
    if (periodIndex == null) return 'Cannot drop onto a break column.';

    // Detect conflicts first
    final conflicts = await _service.detectConflicts(
        widget.db, lessonId, row, periodIndex);

    if (conflicts.isNotEmpty && mounted) {
      // Show collision dialog
      final dayLabel = _allDays[row.clamp(0, 6)];
      final choice = await _showCollisionDialog(conflicts, dayLabel, periodIndex + 1);
      if (choice == null || choice == 'cancel') return null; // User cancelled

      if (choice == 'remove') {
        await _service.moveLessonForced(
            widget.db, lessonId, row, periodIndex);
        return null;
      } else if (choice == 'ignore') {
        await _service.moveLessonIgnoreConflicts(
            widget.db, lessonId, row, periodIndex);
        return null;
      }
    }

    // No conflicts — standard move
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

  Future<String?> _showCollisionDialog(
      List<String> conflicts, String dayLabel, int period) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade600, size: 24),
                  const SizedBox(width: 8),
                  Text('Collisions found',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in conflicts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('$c - $dayLabel $period',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.check_circle_outline,
                  color: Colors.green.shade600),
              title: const Text('Remove collisions and place the card'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx, 'cancel'),
            ),
            ListTile(
              leading: Icon(Icons.warning_outlined,
                  color: Colors.amber.shade700),
              title: const Text('Ignore conflicts and place the card'),
              onTap: () => Navigator.pop(ctx, 'ignore'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ExportSheet(
        onSharePdf: () {
          Navigator.pop(ctx);
          _pdfService
              .buildWorkbookPdf(widget.db, widget.dbId)
              .then((bytes) => _pdfService.sharePdf(bytes,
                  filename: 'SmartTime_Timetable.pdf'));
        },
        onShareExcel: () {
          Navigator.pop(ctx);
          _excelService.exportAndShare(widget.db, widget.dbId);
        },
        onPrintPdf: () {
          Navigator.pop(ctx);
          _pdfService.printCockpitMasterPdf(widget.db, widget.dbId);
        },
      ),
    );
  }

  // ── Clear schedule ───────────────────────────────────────────────────────

  void _showClearMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clear Schedule',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700)),
                  const SizedBox(height: 2),
                  Text('Move lessons to unscheduled',
                      style: TextStyle(
                          fontSize: 13, color: Colors.red.shade400)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Unlocked'),
              subtitle:
                  const Text('Preserves locked & fixed lessons'),
              onTap: () async {
                Navigator.pop(ctx);
                await _clearUnlocked();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Clear All + Unlock'),
              subtitle: const Text('Clears locks, preserves only fixed'),
              onTap: () async {
                Navigator.pop(ctx);
                await _clearAllAndUnlock();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _clearUnlocked() async {
    if (_lockedCardIds.isEmpty) {
      await widget.db.delete(widget.db.cards).go();
    } else {
      await (widget.db.delete(widget.db.cards)
            ..where((t) => t.id.isNotIn(_lockedCardIds)))
          .go();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlocked lessons cleared')),
      );
    }
  }

  Future<void> _clearAllAndUnlock() async {
    _lockedCardIds.clear();
    await widget.db.delete(widget.db.cards).go();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All lessons cleared & unlocked')),
      );
    }
  }

  // ── Regenerate ───────────────────────────────────────────────────────────

  void _showRegenerateDialog(int totalCards, int lockedCount) {
    final unlocked = totalCards - lockedCount;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6CF7), Color(0xFF7B8CF9)],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Regenerate Timetable',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Regenerating will rearrange your timetable while preserving locked lessons in their current positions.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$unlocked unlocked lesson units (out of $totalCards total) may be moved to different time slots for optimal distribution.',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lockedCount == 0
                        ? 'No lessons are currently locked.'
                        : '$lockedCount lesson(s) are currently locked.',
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Do you want to regenerate the timetable?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Clear unlocked cards
                      if (_lockedCardIds.isEmpty) {
                        await widget.db.delete(widget.db.cards).go();
                      } else {
                        await (widget.db.delete(widget.db.cards)
                              ..where((t) => t.id.isNotIn(_lockedCardIds)))
                            .go();
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Regenerating timetable…')),
                      );
                      try {
                        // Build solver payload from DB
                        final lessons = await widget.db.select(widget.db.lessons).get();
                        final snap = await widget.db.loadPlannerSnapshot(widget.dbId);
                        final days = (snap?['workingDays'] as int?) ?? 6;
                        final periods = (snap?['periodsPerDay'] as int?) ?? 7;
                        final rooms = <SolverRoom>[];
                        final classrooms = (snap?['classrooms'] as List?) ?? [];
                        for (final r in classrooms) {
                          if (r is Map) rooms.add(SolverRoom(id: r['id']?.toString() ?? ''));
                        }

                        final solverLessons = <SolverLesson>[];
                        for (final l in lessons) {
                          for (int k = 0; k < l.periodsPerWeek; k++) {
                            solverLessons.add(SolverLesson(
                              id: '${l.id}_$k',
                              teacherIds: l.teacherIds,
                              classIds: l.classIds,
                              subjectId: l.subjectId,
                            ));
                          }
                        }

                        final payload = SolverPayload(
                          days: days,
                          periodsPerDay: periods,
                          rooms: rooms,
                          lessons: solverLessons,
                        );

                        final result = await SolverEngine.solve(payload);
                        if (result.isOk && result.best != null) {
                          // Persist assignments as CardRows
                          final lessonById = {for (final l in lessons) l.id: l};
                          for (final a in result.best!.assignments) {
                            final originalId = a.lessonId.split('_').first;
                            final lesson = lessonById[originalId];
                            if (lesson == null) continue;
                            await widget.db.into(widget.db.cards).insert(
                              CardsCompanion.insert(
                                id: '${originalId}_${a.day}_${a.period}',
                                lessonId: originalId,
                                dayIndex: a.day,
                                periodIndex: a.period,
                                roomId: Value(a.roomId.isEmpty ? null : a.roomId),
                              ),
                            );
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Timetable regenerated ✅')),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Solver: ${result.status}')),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Regeneration failed: $e')),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B6CF7),
                    ),
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<_CockpitVm>(
          stream: _vmStream(),
          builder: (context, snap) {
            final vm = snap.data;
            return Column(
              children: [
                // ─── Header Row 1: Back + Name + View Tabs ───────────
                _HeaderRow(
                  mode: _mode,
                  onModeChanged: (m) => setState(() => _mode = m),
                ),
                // ─── Header Row 2: Toolbar Icons ─────────────────────
                _ToolbarRow(
                  onClear: _showClearMenu,
                  onExport: _showExportMenu,
                  onInsights: () => GenerationInsightsSheet.show(
                      context, widget.db, widget.dbId),
                  onRegenerate: vm != null
                      ? () => _showRegenerateDialog(
                          vm.totalCards, _lockedCardIds.length)
                      : null,
                ),
                // ─── Grid ────────────────────────────────────────────
                Expanded(
                  child: vm == null
                      ? const Center(child: CircularProgressIndicator())
                      : vm.cells.isEmpty &&
                              _selectedTeacherId == null &&
                              _selectedClassId == null &&
                              _selectedRoomId == null
                          ? _EmptyState()
                          : Column(
                              children: [
                                _buildFilterDropdown(vm),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: UniversalTimetableGrid(
                                    viewMode: _mode,
                                    rowLabels: _activeDays(vm.workingDays),
                                    periods: vm.periods,
                                    cells: vm.cells,
                                    onMoveCell: (id, r, c) =>
                                        _moveLessonValidated(
                                            id, r, c, vm.periods),
                                    onValidateMove: (lessonId, row, col) {
                                      // Check if the target cell already has a card
                                      final key = UniversalTimetableGrid.keyFor(row, col);
                                      final existing = vm.cells[key];
                                      if (existing == null) return true; // Empty cell — always OK
                                      // If occupied, only allow if same lesson (swap within same entity)
                                      return existing.id == lessonId;
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
                // ─── Persistent Bottom Bar ───────────────────────────
                if (vm != null)
                  _UnscheduledBottomBar(
                    unscheduled: vm.unscheduled,
                    expanded: _bottomExpanded,
                    onToggle: () =>
                        setState(() => _bottomExpanded = !_bottomExpanded),
                    onFilter: () {
                      // Prepare rooms as List<Map<String, dynamic>>
                      final roomMaps = vm.rooms
                          .whereType<Map>()
                          .map((r) => Map<String, dynamic>.from(r))
                          .toList();
                      FilterUnscheduledSheet.show(
                        context,
                        classes: vm.classes,
                        teachers: vm.teachers,
                        subjects: vm.subjects,
                        rooms: roomMaps,
                        selectedClassIds: {},
                        selectedTeacherIds: {},
                        selectedSubjectIds: {},
                        selectedRoomIds: {},
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(_CockpitVm vm) {
    Widget filterWidget = const SizedBox.shrink();
    if (_mode == ViewMode.teacher) {
      filterWidget = DropdownButton<String>(
        isExpanded: true,
        value: _selectedTeacherId,
        hint: const Text('Select a Teacher'),
        items: [
          const DropdownMenuItem(
              value: null, child: Text('Show All Teachers')),
          ...vm.teachers.map((t) => DropdownMenuItem(
              value: t.id, child: Text(t.name.split(' ').first))),
        ],
        onChanged: (v) => setState(() => _selectedTeacherId = v),
      );
    } else if (_mode == ViewMode.classView) {
      filterWidget = DropdownButton<String>(
        isExpanded: true,
        value: _selectedClassId,
        hint: const Text('Select a Class'),
        items: [
          const DropdownMenuItem(
              value: null, child: Text('Show All Classes')),
          ...vm.classes.map((c) =>
              DropdownMenuItem(value: c.id, child: Text(c.name))),
        ],
        onChanged: (v) => setState(() => _selectedClassId = v),
      );
    } else if (_mode == ViewMode.room) {
      filterWidget = DropdownButton<String>(
        isExpanded: true,
        value: _selectedRoomId,
        hint: const Text('Select a Room'),
        items: [
          const DropdownMenuItem(
              value: null, child: Text('Show All Rooms')),
          ...vm.rooms.map((r) {
            final rMap = r as Map<String, dynamic>;
            return DropdownMenuItem(
                value: rMap['id'] as String,
                child: Text(rMap['name'] as String));
          }),
        ],
        onChanged: (v) => setState(() => _selectedRoomId = v),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: filterWidget,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Model
// ─────────────────────────────────────────────────────────────────────────────

class _CockpitVm {
  final Map<String, TimetableCellData> cells;
  final List<PeriodSlot> periods;
  final List<TeacherRow> teachers;
  final List<ClassRow> classes;
  final List<SubjectRow> subjects;
  final List<dynamic> rooms;
  final List<_UnscheduledLesson> unscheduled;
  final int totalCards;
  final int totalRequired;
  final int workingDays;

  const _CockpitVm({
    required this.cells,
    required this.periods,
    required this.teachers,
    required this.classes,
    required this.subjects,
    required this.rooms,
    required this.unscheduled,
    required this.totalCards,
    required this.totalRequired,
    required this.workingDays,
  });
}

class _UnscheduledLesson {
  final String lessonId;
  final String subjectLabel;
  final String teacherLabel;
  final String? roomLabel;
  final int remaining;
  final Color? accent;

  const _UnscheduledLesson({
    required this.lessonId,
    required this.subjectLabel,
    required this.teacherLabel,
    this.roomLabel,
    required this.remaining,
    this.accent,
  });
}

Color? _subjectAccent(int? rawColor) {
  if (rawColor == null) return null;
  return Color(rawColor);
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Row — Back, Timetable Name, Section/Faculty/Room Tabs
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.mode, required this.onModeChanged});
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Timetable',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // View mode pill tabs
          _PillTab(
            icon: Icons.grid_view_rounded,
            label: 'Section',
            selected: mode == ViewMode.classView,
            onTap: () => onModeChanged(ViewMode.classView),
          ),
          const SizedBox(width: 4),
          _PillTab(
            icon: Icons.people_alt_outlined,
            label: 'Faculty',
            selected: mode == ViewMode.teacher,
            onTap: () => onModeChanged(ViewMode.teacher),
          ),
          const SizedBox(width: 4),
          _PillTab(
            icon: Icons.meeting_room_outlined,
            label: 'Room',
            selected: mode == ViewMode.room,
            onTap: () => onModeChanged(ViewMode.room),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5B6CF7).withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF5B6CF7)
                : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? const Color(0xFF5B6CF7)
                    : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF5B6CF7)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar Row — Undo, Redo, Clear, Settings, Share, Export, Regenerate
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarRow extends StatelessWidget {
  const _ToolbarRow({
    required this.onClear,
    required this.onExport,
    this.onInsights,
    this.onRegenerate,
  });
  final VoidCallback onClear;
  final VoidCallback onExport;
  final VoidCallback? onInsights;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Row(
        children: [
          _ToolbarIcon(Icons.undo, 'Undo', onTap: () {}),
          _ToolbarIcon(Icons.redo, 'Redo', onTap: () {}),
          _ToolbarIcon(Icons.auto_fix_high_outlined, 'Clear', onTap: onClear),
          _ToolbarIcon(Icons.settings_outlined, 'Insights', onTap: onInsights ?? () {}),
          _ToolbarIcon(Icons.share_outlined, 'Share', onTap: onExport),
          _ToolbarIcon(Icons.description_outlined, 'Export', onTap: onExport),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 6),
          // Regenerate button
          _RegenerateButton(onTap: onRegenerate),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon(this.icon, this.tooltip, {required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5B6CF7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Regenerate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.calendar_month_outlined, size: 52),
          SizedBox(height: 12),
          Text('No Schedule Generated Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'Run Pre-Flight and generate a schedule\nto view the cockpit.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent Bottom Bar — Unscheduled Lessons
// ─────────────────────────────────────────────────────────────────────────────

class _UnscheduledBottomBar extends StatelessWidget {
  const _UnscheduledBottomBar({
    required this.unscheduled,
    required this.expanded,
    required this.onToggle,
    this.onFilter,
  });
  final List<_UnscheduledLesson> unscheduled;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final totalRemaining =
        unscheduled.fold<int>(0, (s, u) => s + u.remaining);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header ─────────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Unscheduled\nLessons',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '($totalRemaining)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Add Lesson button
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Manage lessons from the Timetable Setup flow.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add\nLesson',
                        style: TextStyle(fontSize: 11, height: 1.2)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B6CF7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter button
                  OutlinedButton.icon(
                    onPressed: onFilter,
                    icon: Icon(Icons.filter_list,
                        size: 16, color: Colors.grey.shade700),
                    label: Text('Filter',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Expand/collapse chevron
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          // ─── Lesson Cards Tray ──────────────────────────────────
          if (expanded && unscheduled.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                itemCount: unscheduled.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) =>
                    _UnscheduledCard(lesson: unscheduled[i]),
              ),
            ),
          if (expanded && unscheduled.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'All lessons are scheduled! 🎉',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnscheduledCard extends StatelessWidget {
  const _UnscheduledCard({required this.lesson});
  final _UnscheduledLesson lesson;

  @override
  Widget build(BuildContext context) {
    final accent = lesson.accent ?? const Color(0xFFF59E0B);
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lesson.subjectLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              if (lesson.teacherLabel.isNotEmpty)
                Text(
                  lesson.teacherLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (lesson.roomLabel != null)
                Text(
                  lesson.roomLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          // Count badge
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${lesson.remaining}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({
    required this.onSharePdf,
    required this.onShareExcel,
    required this.onPrintPdf,
  });
  final VoidCallback onSharePdf;
  final VoidCallback onShareExcel;
  final VoidCallback onPrintPdf;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Export Timetable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          _ExportFormatRow(
            icon: Icons.picture_as_pdf,
            iconColor: const Color(0xFFDC2626),
            title: 'Share as PDF',
            subtitle:
                'Class, teacher & room pages with school branding',
            onTap: onSharePdf,
          ),
          _ExportFormatRow(
            icon: Icons.table_chart,
            iconColor: const Color(0xFF059669),
            title: 'Share as Excel',
            subtitle: 'Sheets per class, teacher & room',
            onTap: onShareExcel,
          ),
          _ExportFormatRow(
            icon: Icons.print,
            iconColor: const Color(0xFF4F46E5),
            title: 'Print PDF',
            subtitle: 'Send to printer or save as PDF',
            onTap: onPrintPdf,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ExportFormatRow extends StatelessWidget {
  const _ExportFormatRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
