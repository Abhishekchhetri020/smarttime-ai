import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Lock tracking — hydrated from DB `cards.isLocked` column
  final Set<String> _lockedCardIds = {};

  // Display options — persisted with SharedPreferences
  bool _showTeacherShortNames = false;
  bool _showClassShortNames = false;
  bool _showSubjectShortNames = false;
  bool _showRoomShortNames = false;

  // Bottom bar
  bool _bottomExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadLockedIdsFromDb();
    _loadDisplayPrefs();
  }

  Future<void> _loadLockedIdsFromDb() async {
    final cards = await widget.db.select(widget.db.cards).get();
    final locked = cards.where((c) => c.isLocked).map((c) => c.id).toSet();
    if (mounted) setState(() => _lockedCardIds.addAll(locked));
  }

  Future<void> _loadDisplayPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showTeacherShortNames = prefs.getBool('disp_teacher_short') ?? false;
      _showClassShortNames = prefs.getBool('disp_class_short') ?? false;
      _showSubjectShortNames = prefs.getBool('disp_subject_short') ?? false;
      _showRoomShortNames = prefs.getBool('disp_room_short') ?? false;
    });
  }

  Future<void> _saveDisplayPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disp_teacher_short', _showTeacherShortNames);
    await prefs.setBool('disp_class_short', _showClassShortNames);
    await prefs.setBool('disp_subject_short', _showSubjectShortNames);
    await prefs.setBool('disp_room_short', _showRoomShortNames);
  }

  // ── Data stream ──────────────────────────────────────────────────────────

  static const _allDays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  List<String> _activeDays(int workingDays) {
    return _allDays.sublist(0, workingDays.clamp(1, 7));
  }

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

      // Build base period slots (for a single day)
      final basePeriods = buildTimetableSlots(
        plannerSnapshot: plannerSnap,
        usedPeriodIndexes: cards.map((card) => card.periodIndex),
      );

      final workingDays = (plannerSnap?['workingDays'] as int?) ?? 6;
      final dayLabels = _activeDays(workingDays);

      // Build flattened columns: Day0-P0, Day0-P1, ..., Day0-Break, ..., Day1-P0, ...
      final allPeriods = <PeriodSlot>[];
      final dayGroups = <DayGroup>[];
      // Maps (dayIndex, basePeriodIndex) → column index in allPeriods
      final colMap = <String, int>{};

      for (var d = 0; d < workingDays; d++) {
        final startCol = allPeriods.length;
        for (var s = 0; s < basePeriods.length; s++) {
          final bp = basePeriods[s];
          final colIdx = allPeriods.length;
          allPeriods.add(PeriodSlot(
            id: '${bp.id}_d$d',
            label: bp.label,
            isBreak: bp.isBreak,
            periodIndex: bp.periodIndex,
            dayIndex: d,
          ));
          if (!bp.isBreak && bp.periodIndex != null) {
            colMap['$d:${bp.periodIndex}'] = colIdx;
          }
        }
        dayGroups.add(DayGroup(
          label: dayLabels[d],
          startCol: startCol,
          colCount: basePeriods.length,
        ));
      }

      // Build entity rows and cells
      final entityIds = <String>[];
      final entityLabels = <String>[];
      final cells = <String, TimetableCellData>{};

      switch (_mode) {
        case ViewMode.classView:
          // Sort classes by name for consistent ordering
          final sorted = classes.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          for (final cls in sorted) {
            entityIds.add(cls.id);
            entityLabels.add(catalog.classLabel(cls.id));
          }
          final entityRowByClassId = {
            for (var i = 0; i < entityIds.length; i++) entityIds[i]: i
          };

          for (final c in cards) {
            final lesson = lessonById[c.lessonId];
            if (lesson == null) continue;
            for (final classId in lesson.classIds) {
              final row = entityRowByClassId[classId];
              if (row == null) continue;
              final col = colMap['${c.dayIndex}:${c.periodIndex}'];
              if (col == null) continue;
              cells[UniversalTimetableGrid.keyFor(row, col)] =
                  TimetableCellData(
                id: lesson.id,
                cardId: c.id,
                primary: catalog.subjectLabel(lesson.subjectId),
                secondary: catalog.joinTeacherLabels(lesson.teacherIds),
                tertiary: catalog.roomLabel(c.roomId),
                accent: _subjectAccent(catalog.subjectColor(lesson.subjectId)),
              );
            }
          }

        case ViewMode.teacher:
          final sorted = teachers.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          for (final t in sorted) {
            entityIds.add(t.id);
            entityLabels.add(catalog.teacherLabel(t.id));
          }
          final entityRowByTeacherId = {
            for (var i = 0; i < entityIds.length; i++) entityIds[i]: i
          };

          for (final c in cards) {
            final lesson = lessonById[c.lessonId];
            if (lesson == null) continue;
            for (final teacherId in lesson.teacherIds) {
              final row = entityRowByTeacherId[teacherId];
              if (row == null) continue;
              final col = colMap['${c.dayIndex}:${c.periodIndex}'];
              if (col == null) continue;
              cells[UniversalTimetableGrid.keyFor(row, col)] =
                  TimetableCellData(
                id: lesson.id,
                cardId: c.id,
                primary: catalog.subjectLabel(lesson.subjectId),
                secondary: catalog.joinClassLabels(lesson.classIds),
                tertiary: catalog.roomLabel(c.roomId),
                accent: _subjectAccent(catalog.subjectColor(lesson.subjectId)),
              );
            }
          }

        case ViewMode.room:
          final roomsList = ((plannerSnap?['classrooms'] as List<dynamic>?) ??
                  [])
              .whereType<Map>()
              .map((r) => Map<String, dynamic>.from(r))
              .toList()
            ..sort((a, b) => (a['name'] as String? ?? '')
                .compareTo(b['name'] as String? ?? ''));
          for (final r in roomsList) {
            final id = r['id'] as String? ?? '';
            entityIds.add(id);
            entityLabels.add(catalog.roomLabel(id) ?? id);
          }
          final entityRowByRoomId = {
            for (var i = 0; i < entityIds.length; i++) entityIds[i]: i
          };

          for (final c in cards) {
            if (c.roomId == null || c.roomId!.trim().isEmpty) continue;
            final lesson = lessonById[c.lessonId];
            if (lesson == null) continue;
            final row = entityRowByRoomId[c.roomId];
            if (row == null) continue;
            final col = colMap['${c.dayIndex}:${c.periodIndex}'];
            if (col == null) continue;
            cells[UniversalTimetableGrid.keyFor(row, col)] = TimetableCellData(
              id: lesson.id,
              cardId: c.id,
              primary: catalog.subjectLabel(lesson.subjectId),
              secondary: [
                catalog.joinClassLabels(lesson.classIds),
                catalog.joinTeacherLabels(lesson.teacherIds)
              ].where((v) => v.trim().isNotEmpty).join(' / '),
              tertiary: null,
              accent: _subjectAccent(catalog.subjectColor(lesson.subjectId)),
            );
          }
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
        periods: allPeriods,
        dayGroups: dayGroups,
        basePeriods: basePeriods
            .map((s) => PeriodSlot(
                  id: s.id,
                  label: s.label,
                  isBreak: s.isBreak,
                  periodIndex: s.periodIndex,
                ))
            .toList(),
        entityIds: entityIds,
        entityLabels: entityLabels,
        teachers: teachers.toList(),
        classes: classes.toList(),
        subjects: subjects.toList(),
        rooms: (plannerSnap?['classrooms'] as List<dynamic>?) ?? [],
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

  int? _periodIndexFromColumn(List<PeriodSlot> periods, int col) {
    if (col < 0 || col >= periods.length) return null;
    return periods[col].periodIndex;
  }

  int? _dayIndexFromColumn(List<PeriodSlot> periods, int col) {
    if (col < 0 || col >= periods.length) return null;
    return periods[col].dayIndex;
  }

  Future<String?> _moveLessonValidated(
      String lessonId, int row, int col, List<PeriodSlot> periods) async {
    final periodIndex = _periodIndexFromColumn(periods, col);
    if (periodIndex == null) return 'Cannot drop onto a break column.';
    final dayIndex = _dayIndexFromColumn(periods, col);
    if (dayIndex == null) return 'Invalid column.';

    // Detect conflicts first
    final conflicts = await _service.detectConflicts(
        widget.db, lessonId, dayIndex, periodIndex);

    if (conflicts.isNotEmpty && mounted) {
      final dayLabel = _allDays[dayIndex.clamp(0, 6)];
      final choice =
          await _showCollisionDialog(conflicts, dayLabel, periodIndex + 1);
      if (choice == null || choice == 'cancel') return null;

      if (choice == 'remove') {
        await _service.moveLessonForced(
            widget.db, lessonId, dayIndex, periodIndex);
        return null;
      } else if (choice == 'ignore') {
        await _service.moveLessonIgnoreConflicts(
            widget.db, lessonId, dayIndex, periodIndex);
        return null;
      }
    }

    // No conflicts — standard move
    final result = await _service.moveLessonValidated(
        widget.db, lessonId, '$dayIndex:$periodIndex');
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
                          Icon(Icons.circle,
                              size: 6, color: Colors.red.shade400),
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
              leading:
                  Icon(Icons.warning_outlined, color: Colors.amber.shade700),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ExportPopup(
        onExport: (format, category) async {
          Navigator.pop(ctx);
          if (format == 'pdf') {
            final bytes =
                await _pdfService.buildWorkbookPdf(widget.db, widget.dbId);
            _pdfService.sharePdf(bytes,
                filename: 'SmartTime_${category.replaceAll(' ', '_')}.pdf');
          } else {
            _excelService.exportAndShare(widget.db, widget.dbId);
          }
        },
      ),
    );
  }

  // ── Clear schedule ───────────────────────────────────────────────────────

  void _showClearMenu(BuildContext anchorContext) {
    final RenderBox box = anchorContext.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final left = pos.dx;
    final top = pos.dy + box.size.height;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
              onTap: () => Navigator.pop(ctx), child: const SizedBox.expand()),
          Positioned(
            left: left.clamp(0, MediaQuery.of(ctx).size.width - 280),
            top: top,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 270,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clear Schedule header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text('Clear Schedule',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('Move lessons to unscheduled',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade300)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Clear Unlocked',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Preserves locked & fixed',
                          style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _clearUnlocked();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: const Text('Clear All + Unlock',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Clears locks, preserves only fixed',
                          style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _clearAllAndUnlock();
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  // ── Card Action Sheet ─────────────────────────────────────────────────────

  void _showCardActionSheet(String cardId, String lessonId) {
    final isLocked = _lockedCardIds.contains(cardId);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Lock / Unlock
            ListTile(
              leading: Icon(
                isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: isLocked ? Colors.orange : const Color(0xFF5B6CF7),
              ),
              title: Text(isLocked ? 'Unlock Card' : 'Lock Card'),
              subtitle: Text(
                isLocked
                    ? 'Allow this card to be moved or regenerated'
                    : 'Keep this card fixed during regeneration',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() {
                  if (isLocked) {
                    _lockedCardIds.remove(cardId);
                  } else {
                    _lockedCardIds.add(cardId);
                  }
                });
                // Persist to DB
                await (widget.db.update(widget.db.cards)
                      ..where((t) => t.id.equals(cardId)))
                    .write(CardsCompanion(isLocked: Value(!isLocked)));
              },
            ),
            // Pin (fix day/period in DB)
            ListTile(
              leading:
                  const Icon(Icons.push_pin_rounded, color: Color(0xFF10B981)),
              title: const Text('Pin to this slot'),
              subtitle:
                  const Text('Hard-fix this lesson to its current time slot'),
              onTap: () async {
                Navigator.pop(ctx);
                // Parse day/period from cardId: format lessonId_day_period
                final parts = cardId.split('_');
                if (parts.length >= 3) {
                  final day = int.tryParse(parts[parts.length - 2]);
                  final period = int.tryParse(parts[parts.length - 1]);
                  if (day != null && period != null) {
                    await (widget.db.update(widget.db.lessons)
                          ..where((t) => t.id.equals(lessonId)))
                        .write(LessonsCompanion(
                      isPinned: const Value(true),
                      fixedDay: Value(day),
                      fixedPeriod: Value(period),
                    ));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Lesson pinned to this slot')),
                      );
                    }
                  }
                }
              },
            ),
            // Delete card
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove from Timetable',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Move this lesson back to unscheduled'),
              onTap: () async {
                Navigator.pop(ctx);
                _lockedCardIds.remove(cardId);
                await (widget.db.delete(widget.db.cards)
                      ..where((t) => t.id.equals(cardId)))
                    .go();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Lesson moved to unscheduled')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Row Lock/Unlock Dialog ───────────────────────────────────────────────

  void _showRowLockDialog(int rowIndex, String rowLabel, _CockpitVm vm) {
    // Gather all cardIds in this row
    final rowCardIds = <String>[];
    for (var c = 0; c < vm.periods.length; c++) {
      final key = UniversalTimetableGrid.keyFor(rowIndex, c);
      final d = vm.cells[key];
      if (d != null) rowCardIds.add(d.cardId);
    }
    if (rowCardIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lessons in this row')),
      );
      return;
    }

    showDialog(
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
                color: Colors.amber.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$rowLabel — All Periods',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade800)),
                  const SizedBox(height: 2),
                  Text('Lock or unlock all lessons for $rowLabel',
                      style: TextStyle(
                          fontSize: 13, color: Colors.amber.shade600)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.lock_rounded, color: Colors.amber.shade700),
              title: const Text('Lock All Lessons'),
              subtitle:
                  const Text('Keep all lessons fixed during regeneration'),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _lockedCardIds.addAll(rowCardIds));
                for (final cid in rowCardIds) {
                  await (widget.db.update(widget.db.cards)
                        ..where((t) => t.id.equals(cid)))
                      .write(const CardsCompanion(isLocked: Value(true)));
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${rowCardIds.length} lessons locked')),
                  );
                }
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.lock_open_rounded, color: Colors.amber.shade700),
              title: const Text('Unlock All Lessons'),
              subtitle: const Text('Allow lessons to be moved or regenerated'),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _lockedCardIds.removeAll(rowCardIds));
                for (final cid in rowCardIds) {
                  await (widget.db.update(widget.db.cards)
                        ..where((t) => t.id.equals(cid)))
                      .write(const CardsCompanion(isLocked: Value(false)));
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${rowCardIds.length} lessons unlocked')),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Fixed (pinned) lessons cannot be modified.',
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500)),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ── Display Options Popup ───────────────────────────────────────────────

  void _showDisplayOptions(BuildContext anchorContext) {
    final RenderBox renderBox = anchorContext.findRenderObject() as RenderBox;
    final pos = renderBox.localToGlobal(Offset.zero);
    final left = pos.dx;
    final top = pos.dy + renderBox.size.height;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
              onTap: () => Navigator.pop(ctx), child: const SizedBox.expand()),
          Positioned(
            left: left.clamp(0, MediaQuery.of(ctx).size.width - 280),
            top: top,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 260,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StatefulBuilder(
                  builder: (sctx, setSheetState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Text('DISPLAY OPTIONS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5)),
                      ),
                      _displayCheckbox(
                          setSheetState,
                          ctx,
                          'Show Teacher Short Names',
                          _showTeacherShortNames,
                          (v) => _showTeacherShortNames = v),
                      _displayCheckbox(
                          setSheetState,
                          ctx,
                          'Show Class Short Names',
                          _showClassShortNames,
                          (v) => _showClassShortNames = v),
                      _displayCheckbox(
                          setSheetState,
                          ctx,
                          'Show Subject Short Names',
                          _showSubjectShortNames,
                          (v) => _showSubjectShortNames = v),
                      _displayCheckbox(
                          setSheetState,
                          ctx,
                          'Show Room Short Names',
                          _showRoomShortNames,
                          (v) => _showRoomShortNames = v),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayCheckbox(StateSetter setSheetState, BuildContext ctx,
      String label, bool value, void Function(bool) onChanged) {
    return CheckboxListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: const Color(0xFF5B6CF7),
      onChanged: (v) {
        setSheetState(() => onChanged(v ?? false));
        setState(() {});
        _saveDisplayPrefs();
      },
    );
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
                        const SnackBar(
                            content: Text('Regenerating timetable…')),
                      );
                      try {
                        // Build solver payload from DB
                        final lessons =
                            await widget.db.select(widget.db.lessons).get();
                        final snap =
                            await widget.db.loadPlannerSnapshot(widget.dbId);
                        final days = (snap?['workingDays'] as int?) ?? 6;
                        final periods = (snap?['periodsPerDay'] as int?) ?? 7;
                        final rooms = <SolverRoom>[];
                        final classrooms = (snap?['classrooms'] as List?) ?? [];
                        for (final r in classrooms) {
                          if (r is Map)
                            rooms
                                .add(SolverRoom(id: r['id']?.toString() ?? ''));
                        }

                        // Count how many cards are already locked per lesson
                        final lockedCards =
                            await widget.db.select(widget.db.cards).get();
                        final lockedCountPerLesson = <String, int>{};
                        for (final c in lockedCards) {
                          if (_lockedCardIds.contains(c.id)) {
                            lockedCountPerLesson[c.lessonId] =
                                (lockedCountPerLesson[c.lessonId] ?? 0) + 1;
                          }
                        }

                        final solverLessons = <SolverLesson>[];
                        for (final l in lessons) {
                          final alreadyLocked = lockedCountPerLesson[l.id] ?? 0;
                          final remaining = l.periodsPerWeek - alreadyLocked;
                          for (int k = 0; k < remaining; k++) {
                            solverLessons.add(SolverLesson(
                              id: '${l.id}_$k',
                              teacherIds: l.teacherIds,
                              classIds: l.classIds,
                              subjectId: l.subjectId,
                            ));
                          }
                        }

                        if (solverLessons.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'All lessons are locked — nothing to regenerate.')),
                            );
                          }
                          return;
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
                            await widget.db
                                .into(widget.db.cards)
                                .insertOnConflictUpdate(
                                  CardsCompanion.insert(
                                    id: '${originalId}_${a.day}_${a.period}',
                                    lessonId: originalId,
                                    dayIndex: a.day,
                                    periodIndex: a.period,
                                    roomId: Value(
                                        a.roomId.isEmpty ? null : a.roomId),
                                  ),
                                );
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Timetable regenerated ✅')),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Solver: ${result.status}')),
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
                  onClear: (ctx) => _showClearMenu(ctx),
                  onExport: _showExportMenu,
                  onDisplayOptions: (ctx) => _showDisplayOptions(ctx),
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
                      : vm.entityLabels.isEmpty
                          ? _EmptyState()
                          : UniversalTimetableGrid(
                              viewMode: _mode,
                              rowLabels: vm.entityLabels,
                              periods: vm.periods,
                              dayGroups: vm.dayGroups,
                              cornerTitle: switch (_mode) {
                                ViewMode.classView => 'Section',
                                ViewMode.teacher => 'Teachers',
                                ViewMode.room => 'Rooms',
                              },
                              cornerCount: vm.entityLabels.length,
                              cells: vm.cells,
                              onTapCell: _showCardActionSheet,
                              lockedIds: _lockedCardIds,
                              onTapRowLabel: (rowIndex, rowLabel) =>
                                  _showRowLockDialog(rowIndex, rowLabel, vm),
                              onMoveCell: (id, r, c) =>
                                  _moveLessonValidated(id, r, c, vm.periods),
                              onValidateMove: (lessonId, row, col) {
                                final key =
                                    UniversalTimetableGrid.keyFor(row, col);
                                final existing = vm.cells[key];
                                if (existing == null) return true;
                                return existing.id == lessonId;
                              },
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
}

// ─────────────────────────────────────────────────────────────────────────────
// View Model
// ─────────────────────────────────────────────────────────────────────────────

class _CockpitVm {
  final Map<String, TimetableCellData> cells;
  final List<PeriodSlot> periods;
  final List<DayGroup> dayGroups;
  final List<PeriodSlot> basePeriods;
  final List<String> entityIds;
  final List<String> entityLabels;
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
    required this.dayGroups,
    required this.basePeriods,
    required this.entityIds,
    required this.entityLabels,
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
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
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
            color: selected ? const Color(0xFF5B6CF7) : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color:
                    selected ? const Color(0xFF5B6CF7) : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? const Color(0xFF5B6CF7) : Colors.grey.shade600,
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
    this.onDisplayOptions,
    this.onInsights,
    this.onRegenerate,
  });
  final void Function(BuildContext) onClear;
  final VoidCallback onExport;
  final void Function(BuildContext)? onDisplayOptions;
  final VoidCallback? onInsights;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Row(
        children: [
          _ToolbarIcon(Icons.undo, 'Undo', onTap: () {}),
          _ToolbarIcon(Icons.redo, 'Redo', onTap: () {}),
          // Eraser → Clear
          Builder(
              builder: (ctx) => _ToolbarIcon(
                    Icons.auto_fix_high_outlined,
                    'Clear',
                    onTap: () => onClear(ctx),
                  )),
          // Gear → Display Options
          Builder(
              builder: (ctx) => _ToolbarIcon(
                    Icons.settings_outlined,
                    'Display',
                    onTap: () => onDisplayOptions?.call(ctx),
                  )),
          // Document → Export
          _ToolbarIcon(Icons.description_outlined, 'Export', onTap: onExport),
          const Spacer(),
          // Green check → Insights
          GestureDetector(
            onTap: onInsights,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF22C55E), size: 20),
            ),
          ),
          const SizedBox(width: 6),
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
    final totalRemaining = unscheduled.fold<int>(0, (s, u) => s + u.remaining);
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
        border:
            Border(top: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header ─────────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          content: Text(
                              'Manage lessons from the Timetable Setup flow.'),
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
                itemBuilder: (_, i) => _UnscheduledCard(lesson: unscheduled[i]),
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

class _ExportPopup extends StatefulWidget {
  const _ExportPopup({required this.onExport});
  final void Function(String format, String category) onExport;

  @override
  State<_ExportPopup> createState() => _ExportPopupState();
}

class _ExportPopupState extends State<_ExportPopup> {
  String _format = 'pdf';

  static const _categories = [
    'Class-wise (Combined)',
    'Class-wise (Individual)',
    'Faculty-wise (Combined)',
    'Faculty-wise (Individual)',
    'Room-wise (Combined)',
    'Room-wise (Individual)',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Format toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Format',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                SegmentedButton<String>(
                  selected: {_format},
                  onSelectionChanged: (s) => setState(() => _format = s.first),
                  segments: const [
                    ButtonSegment(value: 'pdf', label: Text('PDF')),
                    ButtonSegment(value: 'excel', label: Text('Excel')),
                  ],
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: const Color(0xFF5B6CF7),
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Category label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${_format.toUpperCase()} EXPORT',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5),
            ),
          ),
          // Category list
          for (final cat in _categories)
            ListTile(
              leading: Icon(Icons.description_outlined,
                  color: _format == 'pdf'
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669)),
              title: Text(cat, style: const TextStyle(fontSize: 14)),
              onTap: () => widget.onExport(_format, cat),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
