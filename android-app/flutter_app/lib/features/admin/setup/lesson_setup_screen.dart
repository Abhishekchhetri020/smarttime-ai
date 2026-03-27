import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';
import 'lesson_editor_sheet.dart';

// ── Tab Enum ─────────────────────────────────────────────────────────────────

enum _ViewTab { classes, faculty, subjects, rooms }

const _tabLabels = {
  _ViewTab.classes: 'Classes',
  _ViewTab.faculty: 'Faculty',
  _ViewTab.subjects: 'Subjects',
  _ViewTab.rooms: 'Rooms',
};
const _tabIcons = {
  _ViewTab.classes: Icons.school,
  _ViewTab.faculty: Icons.people,
  _ViewTab.subjects: Icons.menu_book,
  _ViewTab.rooms: Icons.meeting_room,
};

enum _SortMode { name, lessons, periods }

// ── Main Screen ──────────────────────────────────────────────────────────────

class LessonSetupScreen extends StatefulWidget {
  const LessonSetupScreen({super.key});

  @override
  State<LessonSetupScreen> createState() => _LessonSetupScreenState();
}

class _LessonSetupScreenState extends State<LessonSetupScreen> {
  _ViewTab _activeTab = _ViewTab.classes;
  _SortMode _sortMode = _SortMode.name;
  bool _sortAsc = true;

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.auto_stories,
                          color: Colors.deepPurple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lessons',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(
                              'Add lessons for each class with subject/activity, faculty, room, and frequency and lesson length per week (or timetable cycle).',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Tab Bar ────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _ViewTab.values.map((tab) {
                        final isActive = tab == _activeTab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            avatar: Icon(_tabIcons[tab],
                                size: 16,
                                color:
                                    isActive ? Colors.deepPurple : Colors.grey),
                            label: Text(_tabLabels[tab]!),
                            selected: isActive,
                            onSelected: (_) => setState(() => _activeTab = tab),
                            selectedColor: Colors.deepPurple.shade50,
                            labelStyle: TextStyle(
                              color: isActive
                                  ? Colors.deepPurple
                                  : Colors.grey.shade700,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: isActive
                                      ? Colors.deepPurple
                                      : Colors.grey.shade300),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Different ways to view and organize the same lesson data',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // ── Sort Row ───────────────────────────────────────
                  Row(
                    children: [
                      Text('Sort:  ',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                      ..._SortMode.values.map((m) {
                        final isActive = m == _sortMode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (_sortMode == m) {
                                  _sortAsc = !_sortAsc;
                                } else {
                                  _sortMode = m;
                                  _sortAsc = true;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isActive
                                        ? Colors.deepPurple
                                        : Colors.transparent),
                                color:
                                    isActive ? Colors.deepPurple.shade50 : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m.name[0].toUpperCase() +
                                        m.name.substring(1),
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.deepPurple
                                          : Colors.grey.shade700,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isActive)
                                    Icon(
                                      _sortAsc
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      size: 18,
                                      color: Colors.deepPurple,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Content ────────────────────────────────────────
                  _buildContent(planner),
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.download,
                  label: 'Export\nCSV',
                  badge: planner.lessons.isEmpty
                      ? null
                      : '${planner.lessons.length}',
                  onPressed: () => _showExportDialog(context),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.upload_file,
                  label: 'Bulk\nImport',
                  onPressed: () => _showBulkImportDialog(context),
                ),
                const Spacer(),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => showLessonWizardDialog(context),
                    icon: const Icon(Icons.add_circle, size: 16),
                    label: const Text('Add\nNew\nLesson',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PlannerState planner) {
    if (planner.lessons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFBFBFD),
        ),
        child: Column(
          children: [
            Text('No lessons added yet.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Add lessons by clicking the "Add New Lesson" button below.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final groups = _buildGroups(planner);
    return Column(
      children: groups
          .map((g) => _LessonGroupCard(
                groupName: g.name,
                lessons: g.lessons,
                stats: g.stats,
                planner: planner,
              ))
          .toList(),
    );
  }

  List<_LessonGroup> _buildGroups(PlannerState planner) {
    final Map<String, List<LessonSpec>> grouped = {};

    for (final lesson in planner.lessons) {
      String key;
      switch (_activeTab) {
        case _ViewTab.classes:
          if (lesson.classIds.isEmpty) {
            key = 'No Class';
          } else {
            final classMatch =
                planner.classes.where((c) => lesson.classIds.contains(c.id));
            key = classMatch.isEmpty
                ? lesson.classIds.first
                : classMatch.map((c) => c.name).join(', ');
          }
        case _ViewTab.faculty:
          if (lesson.teacherIds.isEmpty) {
            key = 'No Teacher';
          } else {
            final teacherMatch =
                planner.teachers.where((t) => lesson.teacherIds.contains(t.id));
            key = teacherMatch.isEmpty
                ? lesson.teacherIds.first
                : teacherMatch.map((t) => t.fullName).join(', ');
          }
        case _ViewTab.subjects:
          final subjectMatch =
              planner.subjects.where((s) => s.id == lesson.subjectId);
          key =
              subjectMatch.isEmpty ? lesson.subjectId : subjectMatch.first.name;
        case _ViewTab.rooms:
          if (lesson.requiredClassroomId == null) {
            key = 'No Room';
          } else {
            final roomMatch = planner.classrooms
                .where((r) => r.id == lesson.requiredClassroomId);
            key = roomMatch.isEmpty
                ? lesson.requiredClassroomId!
                : roomMatch.first.name;
          }
      }
      grouped.putIfAbsent(key, () => []).add(lesson);
    }

    var groups = grouped.entries.map((e) {
      final lessons = e.value;
      int totalLessons = lessons.length;
      int totalPeriods = 0;
      Set<String> uniqueClasses = {};
      Set<String> uniqueSubjects = {};
      for (final l in lessons) {
        totalPeriods += l.countPerWeek * _lengthToInt(l.length);
        uniqueClasses.addAll(l.classIds);
        uniqueSubjects.add(l.subjectId);
      }
      return _LessonGroup(
        name: e.key,
        lessons: lessons,
        stats:
            '$totalLessons Lessons  $totalPeriods Total Periods  ${uniqueClasses.length} Classes  ${uniqueSubjects.length} Subjects',
      );
    }).toList();

    groups.sort((a, b) {
      int cmp;
      switch (_sortMode) {
        case _SortMode.name:
          cmp = a.name.compareTo(b.name);
        case _SortMode.lessons:
          cmp = b.lessons.length.compareTo(a.lessons.length);
        case _SortMode.periods:
          cmp = b.lessons
              .fold<int>(0, (s, l) => s + l.countPerWeek)
              .compareTo(a.lessons.fold<int>(0, (s, l) => s + l.countPerWeek));
      }
      return _sortAsc ? cmp : -cmp;
    });

    return groups;
  }

  void _showExportDialog(BuildContext ctx) {
    final planner = ctx.read<PlannerState>();
    showDialog(
      context: ctx,
      builder: (_) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: const _ExportLessonsDialog(),
      ),
    );
  }

  void _showBulkImportDialog(BuildContext ctx) {
    final planner = ctx.read<PlannerState>();
    showDialog(
      context: ctx,
      builder: (_) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: const _BulkImportLessonsDialog(),
      ),
    );
  }
}

int _lengthToInt(String length) {
  switch (length) {
    case 'single':
      return 1;
    case 'double':
      return 2;
    case 'triple':
      return 3;
    default:
      final n = int.tryParse(length);
      return n ?? 1;
  }
}

String _lengthToLabel(String length) {
  switch (length) {
    case 'single':
      return '1P';
    case 'double':
      return '2P';
    case 'triple':
      return '3P';
    default:
      final n = int.tryParse(length);
      return n != null ? '${n}P' : '1P';
  }
}

class _LessonGroup {
  final String name;
  final List<LessonSpec> lessons;
  final String stats;
  _LessonGroup(
      {required this.name, required this.lessons, required this.stats});
}

// ── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon,
      required this.label,
      this.badge,
      required this.onPressed});
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade700),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.deepPurple, shape: BoxShape.circle),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

// ── Lesson Group Card ────────────────────────────────────────────────────────

class _LessonGroupCard extends StatefulWidget {
  const _LessonGroupCard(
      {required this.groupName,
      required this.lessons,
      required this.stats,
      required this.planner});
  final String groupName;
  final List<LessonSpec> lessons;
  final String stats;
  final PlannerState planner;

  @override
  State<_LessonGroupCard> createState() => _LessonGroupCardState();
}

class _LessonGroupCardState extends State<_LessonGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: Colors.deepPurple.shade200, width: 3)),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(widget.groupName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15))),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: widget.stats
                        .split('  ')
                        .map((s) => Text(s.trim(),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)))
                        .toList(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showLessonWizardDialog(context),
                      child:
                          const Text('+ Add', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.lessons.map((lesson) =>
                _LessonDetailTile(lesson: lesson, planner: widget.planner)),
        ],
      ),
    );
  }
}

// ── Lesson Detail Tile ───────────────────────────────────────────────────────

class _LessonDetailTile extends StatelessWidget {
  const _LessonDetailTile({required this.lesson, required this.planner});
  final LessonSpec lesson;
  final PlannerState planner;

  @override
  Widget build(BuildContext context) {
    final subjectMatch =
        planner.subjects.where((s) => s.id == lesson.subjectId);
    final subjectName =
        subjectMatch.isEmpty ? lesson.subjectId : subjectMatch.first.name;

    final classNames = planner.classes
        .where((c) => lesson.classIds.contains(c.id))
        .map((c) => c.name)
        .join(', ');
    final sectionLabel = classNames.isEmpty ? 'None' : classNames;

    String? roomLabel;
    if (lesson.requiredClassroomId != null) {
      final roomMatch =
          planner.classrooms.where((r) => r.id == lesson.requiredClassroomId);
      roomLabel = roomMatch.isEmpty ? null : '🏠 (${roomMatch.first.name})';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade100),
          left: BorderSide(color: Colors.deepPurple.shade200, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(sectionLabel,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.menu_book,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(subjectName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                        'Lessons: ${lesson.countPerWeek}×${_lengthToLabel(lesson.length)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                        'Periods: ${lesson.countPerWeek * _lengthToInt(lesson.length)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                if (roomLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(roomLabel,
                        style: TextStyle(
                            fontSize: 11, color: Colors.deepPurple.shade400)),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: Colors.grey.shade600),
                onPressed: () =>
                    showLessonWizardDialog(context, lesson: lesson),
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: Colors.grey.shade600),
                onPressed: () => _duplicateLesson(context, lesson),
                visualDensity: VisualDensity.compact,
                tooltip: 'Duplicate',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: Colors.red.shade400),
                onPressed: () => _deleteLesson(context, lesson),
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _duplicateLesson(BuildContext context, LessonSpec lesson) {
    context.read<PlannerState>().addLesson(
          subjectId: lesson.subjectId,
          teacherIds: List.from(lesson.teacherIds),
          classIds: List.from(lesson.classIds),
          classDivisionId: lesson.classDivisionId,
          countPerWeek: lesson.countPerWeek,
          length: lesson.length,
          requiredClassroomId: lesson.requiredClassroomId,
        );
  }

  void _deleteLesson(BuildContext context, LessonSpec lesson) {
    context.read<PlannerState>().removeLesson(lesson.id);
  }
}

// ── Export Dialog ─────────────────────────────────────────────────────────────

class _ExportLessonsDialog extends StatelessWidget {
  const _ExportLessonsDialog();

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerState>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Export Lessons to CSV',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Download your lesson data in CSV format',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                      '${planner.lessons.length} lessons → ${planner.lessons.length} CSV rows',
                      style:
                          TextStyle(color: Colors.blue.shade800, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CSV Columns',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text(
                        'Teacher Names\nClass Names\nSubject Names\nRoom Names\nNo. of Lessons\nLength',
                        style:
                            TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Multiple items joined with " & " • Compatible with bulk import',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                  onPressed: () => _doExport(context, planner),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _doExport(BuildContext context, PlannerState planner) async {
    try {
      final rows = <List<String>>[
        [
          'Teacher Names',
          'Class Names',
          'Subject Names',
          'Room Names',
          'No. of Lessons',
          'Length'
        ],
      ];
      for (final l in planner.lessons) {
        final teachers = planner.teachers
            .where((t) => l.teacherIds.contains(t.id))
            .map((t) => t.fullName)
            .join(' & ');
        final classes = planner.classes
            .where((c) => l.classIds.contains(c.id))
            .map((c) => c.name)
            .join(' & ');
        final subject = planner.subjects
            .where((s) => s.id == l.subjectId)
            .map((s) => s.name)
            .join();
        String room = '';
        if (l.requiredClassroomId != null) {
          room = planner.classrooms
              .where((r) => r.id == l.requiredClassroomId)
              .map((r) => r.name)
              .join();
        }
        rows.add([
          teachers,
          classes,
          subject.isEmpty ? l.subjectId : subject,
          room,
          '${l.countPerWeek}',
          l.length
        ]);
      }
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/lessons_export.csv';
      await File(path).writeAsString(csv);
      if (context.mounted) {
        Navigator.pop(context);
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles([XFile(path)],
            subject: 'Lessons Export',
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

// ── Bulk Import Dialog ───────────────────────────────────────────────────────

class _BulkImportLessonsDialog extends StatefulWidget {
  const _BulkImportLessonsDialog();
  @override
  State<_BulkImportLessonsDialog> createState() =>
      _BulkImportLessonsDialogState();
}

class _BulkImportLessonsDialogState extends State<_BulkImportLessonsDialog> {
  bool _importing = false;
  String? _pickedFileName;
  List<List<dynamic>>? _csvData;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      final csvString = utf8.decode(file.bytes!);
      final data = const CsvToListConverter().convert(csvString);
      setState(() {
        _pickedFileName = file.name;
        _csvData = data;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to parse CSV: $e')));
    }
  }

  Future<void> _processImport() async {
    if (_csvData == null || _csvData!.isEmpty) return;
    setState(() => _importing = true);
    try {
      final planner = context.read<PlannerState>();
      final rows = _csvData!;
      final headers =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

      int teacherIdx = headers.indexOf('teacher names');
      int classIdx = headers.indexOf('class names');
      int subjectIdx = headers.indexOf('subject names');
      int roomIdx = headers.indexOf('room names');
      int countIdx = headers.indexOf('no. of lessons');
      int lengthIdx = headers.indexOf('length');

      int imported = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String subjectName = _safeGet(row, subjectIdx);
        if (subjectName.isEmpty) continue;

        // Find or use subject
        final subjectMatch = planner.subjects
            .where((s) => s.name.toLowerCase() == subjectName.toLowerCase());
        final subjectId =
            subjectMatch.isEmpty ? subjectName : subjectMatch.first.id;

        // Teachers
        String teacherNames = _safeGet(row, teacherIdx);
        List<String> tIds = [];
        for (final tn in teacherNames.split('&').map((e) => e.trim())) {
          if (tn.isEmpty) continue;
          final match = planner.teachers
              .where((t) => t.fullName.toLowerCase() == tn.toLowerCase());
          if (match.isNotEmpty) tIds.add(match.first.id);
        }

        // Classes
        String classNames = _safeGet(row, classIdx);
        List<String> cIds = [];
        for (final cn in classNames.split('&').map((e) => e.trim())) {
          if (cn.isEmpty) continue;
          final match = planner.classes
              .where((c) => c.name.toLowerCase() == cn.toLowerCase());
          if (match.isNotEmpty) cIds.add(match.first.id);
        }

        // Room
        String roomName = _safeGet(row, roomIdx);
        String? roomId;
        if (roomName.isNotEmpty) {
          final match = planner.classrooms
              .where((r) => r.name.toLowerCase() == roomName.toLowerCase());
          if (match.isNotEmpty) roomId = match.first.id;
        }

        int count = int.tryParse(_safeGet(row, countIdx)) ?? 1;
        String length = _safeGet(row, lengthIdx);
        if (length.isEmpty) length = 'single';

        planner.addLesson(
          subjectId: subjectId,
          teacherIds: tIds,
          classIds: cIds,
          countPerWeek: count,
          length: length,
          requiredClassroomId: roomId,
        );
        imported++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $imported lessons')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import error: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _safeGet(List<dynamic> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx].toString().trim();
  }

  Future<void> _downloadSample() async {
    try {
      final csv = const ListToCsvConverter().convert([
        [
          'Teacher Names',
          'Class Names',
          'Subject Names',
          'Room Names',
          'No. of Lessons',
          'Length'
        ],
        ['Mr. Smith', '10 A', 'Mathematics', 'Room 101', '5', 'single'],
        [
          'Mrs. Johnson & Mr. Lee',
          '10 A & 10 B',
          'Science',
          'Lab A',
          '3',
          'double'
        ],
      ]);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/lessons_import_template.csv';
      await File(path).writeAsString(csv);
      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles([XFile(path)],
            subject: 'Lessons Import Template',
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Template error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('Bulk Import Lessons',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  'Import lesson data with teachers, classes, subjects, and scheduling details',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              // CSV Format
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text('CSV Format & Export Instructions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _csvBullet('Excel:',
                        ' File → Save As → Choose "CSV (Comma delimited)" format'),
                    _csvBullet('Google Sheets:',
                        ' File → Download → Comma-separated values (.csv)'),
                    _csvBullet('Use & to separate',
                        ' multiple teachers, classes, or subjects'),
                    _csvBullet('Required columns:',
                        ' Teacher Names, Class Names, Subject Names, Room Names, No. of Lessons, Length'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Step 1
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.download_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      const Text('Step 1: Download Sample',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text('Download a sample CSV to see the expected format.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download Sample'),
                          onPressed: _downloadSample),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Step 2
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.upload_file_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      const Text('Step 2: Upload Your CSV',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text('Select your CSV file with lesson data.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(_pickedFileName ?? 'Select CSV File'),
                        onPressed: _importing ? null : _pickFile,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                  child: Text(
                      _csvData == null
                          ? 'Select a CSV file to continue'
                          : 'Ready to import',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _importing || _csvData == null
                          ? null
                          : _processImport,
                      child: _importing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Import lessons'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _csvBullet(String bold, String rest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 6, right: 8, left: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.blue.shade700, shape: BoxShape.circle)),
          Expanded(
              child: Text.rich(TextSpan(children: [
            TextSpan(
                text: bold,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    fontSize: 12)),
            TextSpan(
                text: rest,
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
          ]))),
        ],
      ),
    );
  }
}
