import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/bulk_import_service.dart';
import '../timetable/data/preflight_service.dart';
import 'generation_progress_screen.dart';
import 'planner_state.dart';
import 'setup/class_setup_screen.dart';
import 'setup/lesson_setup_screen.dart';
import 'setup/room_setup_screen.dart';
import 'setup/subject_setup_screen.dart';
import 'setup/system_settings_screen.dart';
import 'setup/teacher_setup_screen.dart';
import 'setup/timetable_details_screen.dart';
import 'setup/bell_schedule_screen.dart';
import 'card_relationships_screen.dart';
import 'time_off_picker.dart';
import 'workload_analysis_screen.dart';
import '../timetable/presentation/screens/cockpit_screen.dart';

class _SetupEntry {
  const _SetupEntry({
    required this.title,
    required this.description,
    required this.statusText,
    required this.warningCount,
    required this.builder,
    required this.icon,
    this.isOptional = false,
  });

  final String title;
  final String description;
  final String statusText;
  final int warningCount;
  final WidgetBuilder builder;
  final IconData icon;
  final bool isOptional;

  bool get isCompleted => warningCount == 0 && statusText != 'Not configured';
}

class _SetupSection {
  const _SetupSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<_SetupEntry> entries;
}

class TimetableSetupShell extends StatelessWidget {
  const TimetableSetupShell({super.key});

  // ── colours ──────────────────────────────────────────────────────────────
  static const _scaffoldBg  = Color(0xFFF1F5F9);
  static const _completedBg = Color(0xFFEEF2FF);
  static const _completedBorder = Color(0xFF4F46E5);
  static const _pendingBg   = Colors.white;
  static const _pendingBorder = Color(0xFFE2E8F0);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    final bellSummary = () {
      final days = planner.workingDays;
      final periods = planner.bellTimes.length;
      if (periods == 0) return 'Not configured';
      final dayLabel = days == 7
          ? 'Daily'
          : days == 5
              ? 'Weekdays'
              : '$days day${days > 1 ? 's' : ''}';
      return '$dayLabel • $periods period${periods != 1 ? 's' : ''}';
    }();

    final sections = <_SetupSection>[
      _SetupSection(
        title: 'Basic Information',
        entries: [
          _SetupEntry(
            icon: Icons.article_outlined,
            title: 'Timetable Details',
            description: 'Name, start date, and end date for this session.',
            statusText: planner.sessionName.isNotEmpty ? planner.sessionName : 'Not configured',
            warningCount: planner.sessionName.isNotEmpty ? 0 : 1,
            builder: (_) => const TimetableDetailsScreen(),
          ),
          _SetupEntry(
            icon: Icons.schedule_outlined,
            title: 'Bell Schedule',
            description: 'Configure periods and breaks for your timetable.',
            statusText: bellSummary,
            warningCount: planner.bellTimes.isNotEmpty ? 0 : 1,
            builder: (_) => const BellScheduleScreen(),
          ),
        ],
      ),
      _SetupSection(
        title: 'Institute Data',
        entries: [
          _SetupEntry(
            icon: Icons.people_alt_outlined,
            title: 'Faculty',
            description: 'Add teachers, instructors, and other teaching staff.',
            statusText: planner.teachers.isEmpty
                ? '0 faculty members configured'
                : '${planner.teachers.length} faculty member${planner.teachers.length != 1 ? 's' : ''}',
            warningCount: planner.teachers.isEmpty ? 1 : 0,
            builder: (_) => const TeacherSetupScreen(),
          ),
          _SetupEntry(
            icon: Icons.school_outlined,
            title: 'Grades & Divisions',
            description: 'Define grade levels (e.g., Grade 5) and their divisions (A, B, C).',
            statusText: planner.classes.isEmpty
                ? '0 grades configured'
                : '${planner.classes.length} grade${planner.classes.length != 1 ? 's' : ''} configured',
            warningCount: planner.classes.isEmpty ? 1 : 0,
            builder: (_) => const ClassSetupScreen(),
          ),
          _SetupEntry(
            icon: Icons.meeting_room_outlined,
            title: 'Rooms',
            description: 'Add classrooms, labs, and other teaching spaces.',
            statusText: planner.classrooms.isEmpty
                ? '0 rooms configured'
                : '${planner.classrooms.length} room${planner.classrooms.length != 1 ? 's' : ''} configured',
            warningCount: 0,
            isOptional: true,
            builder: (_) => const RoomSetupScreen(),
          ),
        ],
      ),
      _SetupSection(
        title: 'Lessons Configuration',
        entries: [
          _SetupEntry(
            icon: Icons.menu_book_outlined,
            title: 'Subjects & Activities',
            description: 'Define subjects like Math, Science, and activities like Assembly.',
            statusText: planner.subjects.isEmpty
                ? '0 subjects configured'
                : '${planner.subjects.length} subject${planner.subjects.length != 1 ? 's' : ''} configured',
            warningCount: planner.subjects.isEmpty ? 1 : 0,
            builder: (_) => const SubjectSetupScreen(),
          ),
          _SetupEntry(
            icon: Icons.list_alt_outlined,
            title: 'Lessons',
            description: 'Assign subjects to grades with faculty and period counts.',
            statusText: planner.lessons.isEmpty
                ? '0 lessons configured'
                : '${planner.lessons.length} lesson${planner.lessons.length != 1 ? 's' : ''} configured',
            warningCount: planner.lessons.isEmpty ? 1 : 0,
            builder: (_) => const LessonSetupScreen(),
          ),
        ],
      ),
      _SetupSection(
        title: 'Settings & Conditions',
        entries: [
          _SetupEntry(
            icon: Icons.settings_outlined,
            title: 'System Settings',
            description: 'Faculty constraints, optimization weights, and execution time.',
            statusText: 'Configured',
            warningCount: 0,
            isOptional: true,
            builder: (_) => const SystemSettingsScreen(),
          ),
          _SetupEntry(
            icon: Icons.rule_outlined,
            title: 'Conditions & Constraints',
            description: 'Subject sequencing rules, control which subjects should or shouldn\'t follow each other.',
            statusText: '${planner.cardRelationships.where((r) => r.isActive).length} active rule(s)',
            warningCount: 0,
            builder: (_) => const CardRelationshipsScreen(),
          ),
          _SetupEntry(
            icon: Icons.analytics_outlined,
            title: 'Workload Analysis',
            description: 'Period distribution across classes, teachers, and rooms.',
            statusText: 'View Analysis',
            warningCount: 0,
            isOptional: true,
            builder: (_) => const WorkloadAnalysisScreen(),
          ),
        ],
      ),
    ];

    final allEntries = sections.expand((s) => s.entries).toList();
    final completed = allEntries.where((e) => e.isCompleted).length;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: const Text('Timetable Setup'),
        backgroundColor: _scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // ── progress header ──────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProgressHeaderDelegate(
              completed: completed,
              total: allEntries.length,
              bg: _scaffoldBg,
            ),
          ),

          // ── sections ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == sections.length) {
                    return _PreGenerationReviewCard(
                      planner: planner,
                      completed: completed,
                      total: allEntries.length,
                      teacherCount: planner.teachers.length,
                      classCount: planner.classes.length,
                      lessonCount: planner.lessons.length,
                      missing: allEntries
                          .where((e) => e.warningCount > 0)
                          .map((e) => e.title)
                          .toList(),
                      onImport: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final importer = BulkImportService();
                          final workbookOption =
                              await importer.pickImportWorkbook();
                          if (workbookOption == null) {
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Import cancelled.')));
                            return;
                          }
                          final db = planner.db;
                          if (db == null) {
                            messenger.showSnackBar(const SnackBar(
                                content:
                                    Text('Database not ready. Try again.')));
                            return;
                          }
                          final summary =
                              await importer.importMasterWorkbookData(
                                db,
                                planner.dbId,
                                workbookFile: workbookOption,
                              );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Import complete • ${summary.lessons} lessons, '
                                '${summary.teachers} teachers, '
                                '${summary.rooms} rooms.',
                              ),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                              SnackBar(content: Text('Import failed: $e')));
                        }
                      },
                    );
                  }

                  final section = sections[index];
                  return _SectionBlock(section: section);
                },
                childCount: sections.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section block ───────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});
  final _SetupSection section;

  static const _completedBg     = TimetableSetupShell._completedBg;
  static const _completedBorder = TimetableSetupShell._completedBorder;
  static const _pendingBg       = TimetableSetupShell._pendingBg;
  static const _pendingBorder   = TimetableSetupShell._pendingBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Card group
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: section.entries.asMap().entries.map((mapEntry) {
                final i     = mapEntry.key;
                final entry = mapEntry.value;
                final isFirst  = i == 0;
                final isLast   = i == section.entries.length - 1;
                final done     = entry.isCompleted;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thin divider between cards (not before first)
                    if (!isFirst)
                      Container(
                        height: 1,
                        color: done ? _completedBorder.withOpacity(0.25) : _pendingBorder,
                      ),

                    Material(
                      color: done ? _completedBg : _pendingBg,
                      child: InkWell(
                        onTap: () {
                          final planner = context.read<PlannerState>();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChangeNotifierProvider<PlannerState>.value(
                                value: planner,
                                child: entry.builder(context),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: done ? _completedBorder : Colors.transparent,
                                width: 3,
                              ),
                              // top border only on first item
                              top: isFirst
                                  ? BorderSide(
                                      color: done ? _completedBorder.withOpacity(0.5) : _pendingBorder,
                                    )
                                  : BorderSide.none,
                              // bottom border only on last item
                              bottom: isLast
                                  ? BorderSide(
                                      color: done ? _completedBorder.withOpacity(0.5) : _pendingBorder,
                                    )
                                  : BorderSide.none,
                              right: BorderSide(
                                color: done ? _completedBorder.withOpacity(0.5) : _pendingBorder,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Leading icon
                              Icon(
                                entry.icon,
                                size: 22,
                                color: done
                                    ? _completedBorder
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 14),
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          entry.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (entry.isOptional) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Optional',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.description,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // Status badge
                                    Text(
                                      entry.statusText,
                                      style: TextStyle(
                                        color: done
                                            ? _completedBorder
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Trailing icon
                              Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.chevron_right,
                                size: done ? 22 : 20,
                                color: done
                                    ? _completedBorder
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pinned progress header ─────────────────────────────────────────────────

class _ProgressHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProgressHeaderDelegate({
    required this.completed,
    required this.total,
    required this.bg,
  });

  final int completed;
  final int total;
  final Color bg;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final value = total == 0 ? 0.0 : completed / total;
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Setup Progress',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                Text(
                  '$completed / $total complete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    TimetableSetupShell._completedBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 74;
  @override
  double get minExtent => 74;
  @override
  bool shouldRebuild(covariant _ProgressHeaderDelegate old) =>
      completed != old.completed || total != old.total;
}

// ── Pre-generation review card ─────────────────────────────────────────────

class _PreGenerationReviewCard extends StatelessWidget {
  const _PreGenerationReviewCard({
    required this.planner,
    required this.completed,
    required this.total,
    required this.teacherCount,
    required this.classCount,
    required this.lessonCount,
    required this.missing,
    required this.onImport,
  });

  final PlannerState planner;
  final int completed;
  final int total;
  final int teacherCount;
  final int classCount;
  final int lessonCount;
  final List<String> missing;
  final Future<void> Function() onImport;

  bool get canGenerate =>
      teacherCount > 0 && classCount > 0 && lessonCount > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checks = <({String label, bool ok})>[
      (label: 'Teachers configured', ok: teacherCount > 0),
      (label: 'Classes configured', ok: classCount > 0),
      (label: 'Lessons configured', ok: lessonCount > 0),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE0E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pre-generation Review',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$completed of $total setup sections are ready.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          ...checks.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    c.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: c.ok
                        ? TimetableSetupShell._completedBorder
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(c.label, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Still needed:',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...missing.map((m) => Text('• $m',
                style: TextStyle(
                    fontSize: 13, color: theme.colorScheme.error))),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          // ── Warnings & Errors ─────────────────────────────────
          _WarningsSection(planner: planner),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canGenerate
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider<PlannerState>.value(
                            value: planner,
                            child: const GenerationProgressScreen(),
                          ),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Timetable'),
            ),
          ),
          if (planner.hasGeneratedTimetable) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final db = planner.db;
                  if (db == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CockpitScreen(db: db, dbId: planner.dbId),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Open Timetable'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFF059669)),
                ),
              ),
            ),
          ],
          if (!canGenerate) ...[
            const SizedBox(height: 10),
            Text(
              'Add at least 1 teacher, 1 class, and 1 lesson to enable generation.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Warnings & Errors Section ───────────────────────────────────────────────

class _WarningsSection extends StatelessWidget {
  const _WarningsSection({required this.planner});
  final PlannerState planner;

  @override
  Widget build(BuildContext context) {
    if (planner.lessons.isEmpty && planner.teachers.isEmpty) {
      return const SizedBox.shrink();
    }

    final report = PreflightService().audit(planner);
    if (report.issues.isEmpty) return const SizedBox.shrink();

    final issueCount = report.issues.length;

    // Compute teacher/room-specific overflows for detailed display
    final periodsPerWeek = planner.workingDays * planner.bellTimes.length;
    final teacherLoad = <String, int>{};
    for (final lesson in planner.lessons) {
      for (final tid in lesson.teacherIds) {
        teacherLoad[tid] = (teacherLoad[tid] ?? 0) + lesson.countPerWeek;
      }
    }
    final overloadedTeachers = planner.teachers
        .where((t) => (teacherLoad[t.id] ?? 0) > periodsPerWeek)
        .toList();

    final rooms = planner.classrooms.isEmpty ? 1 : planner.classrooms.length;
    final totalRoomSlots = rooms * periodsPerWeek;
    final totalLessons =
        planner.lessons.fold<int>(0, (sum, l) => sum + l.countPerWeek);
    final roomOverflow = totalLessons > totalRoomSlots;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Warnings & Errors',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      '$issueCount issue${issueCount != 1 ? 's' : ''} detected that may prevent successful generation',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangeNotifierProvider<PlannerState>.value(
                    value: planner,
                    child: const WorkloadAnalysisScreen(),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View detailed analysis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: Colors.red.shade700),
                ],
              ),
            ),
          ),
          if (overloadedTeachers.isNotEmpty || roomOverflow) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workload Overflows',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (overloadedTeachers.isNotEmpty)
                    _OverflowRow(
                      icon: Icons.people_alt_outlined,
                      label: '${overloadedTeachers.length} teacher${overloadedTeachers.length != 1 ? 's' : ''} with too many lessons assigned',
                      detail: 'Teachers: ${overloadedTeachers.map((t) => t.fullName.isNotEmpty ? t.fullName : t.abbr).join(', ')}',
                    ),
                  if (overloadedTeachers.isNotEmpty && roomOverflow)
                    const SizedBox(height: 8),
                  if (roomOverflow)
                    _OverflowRow(
                      icon: Icons.meeting_room_outlined,
                      label: 'Total lessons exceed available room slots',
                      detail: 'Rooms: $totalLessons lessons vs $totalRoomSlots slots',
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverflowRow extends StatelessWidget {
  const _OverflowRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFB45309)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78350F),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
