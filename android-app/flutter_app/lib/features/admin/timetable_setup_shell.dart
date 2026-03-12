import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generation_progress_screen.dart';
import 'planner_state.dart';
import 'setup/class_setup_screen.dart';
import 'setup/lesson_setup_screen.dart';
import 'setup/room_setup_screen.dart';
import 'setup/subject_setup_screen.dart';
import 'setup/teacher_setup_screen.dart';
import 'widgets/setup_section_card.dart';

class TimetableSetupShell extends StatelessWidget {
  const TimetableSetupShell({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final entries = <_SetupEntry>[
      _SetupEntry(
        title: 'Teachers',
        description: 'Add staff profiles, subjects, and availability basics.',
        statusText: '${planner.teachers.length} configured',
        warningCount: planner.teachers.isEmpty ? 1 : 0,
        builder: (_) => const TeacherSetupScreen(),
      ),
      _SetupEntry(
        title: 'Classes',
        description: 'Configure grade levels, divisions, and class strength.',
        statusText: '${planner.classes.length} configured',
        warningCount: planner.classes.isEmpty ? 1 : 0,
        builder: (_) => const ClassSetupScreen(),
      ),
      _SetupEntry(
        title: 'Rooms',
        description: 'Define classrooms, labs, and room capacities.',
        statusText: '${planner.classrooms.length} configured',
        warningCount: 0,
        builder: (_) => const RoomSetupScreen(),
      ),
      _SetupEntry(
        title: 'Subjects',
        description: 'Map curriculum subjects and weekly load targets.',
        statusText: '${planner.subjects.length} configured',
        warningCount: planner.subjects.isEmpty ? 1 : 0,
        builder: (_) => const SubjectSetupScreen(),
      ),
      _SetupEntry(
        title: 'Lessons',
        description: 'Set lesson counts and placement requirements.',
        statusText: '${planner.lessons.length} configured',
        warningCount: planner.lessons.isEmpty ? 1 : 0,
        builder: (_) => const LessonSetupScreen(),
      ),
      _SetupEntry(
        title: 'Constraints',
        description: 'Capture hard rules and preferred scheduling patterns.',
        statusText: 'Coming in next phase',
        warningCount: 0,
        builder: (_) => const _PlaceholderSectionScreen(title: 'Constraints'),
      ),
    ];

    final completed = entries.where((e) => e.warningCount == 0 && !e.statusText.startsWith('Coming')).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable Setup')),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProgressHeaderDelegate(completed: completed, total: entries.length),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList.builder(
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  return _PreGenerationReviewCard(
                    completed: completed,
                    total: entries.length,
                    teacherCount: planner.teachers.length,
                    classCount: planner.classes.length,
                    lessonCount: planner.lessons.length,
                    missing: entries.where((e) => e.warningCount > 0).map((e) => e.title).toList(),
                  );
                }
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SetupSectionCard(
                    title: entry.title,
                    description: entry.description,
                    statusText: entry.statusText,
                    warningCount: entry.warningCount,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: entry.builder)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProgressHeaderDelegate({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final value = total == 0 ? 0.0 : completed / total;
    return Material(
      elevation: overlapsContent ? 1 : 0,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Setup Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: value),
            const SizedBox(height: 6),
            Text('$completed of $total sections ready', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 96;
  @override
  double get minExtent => 96;
  @override
  bool shouldRebuild(covariant _ProgressHeaderDelegate oldDelegate) => completed != oldDelegate.completed || total != oldDelegate.total;
}

class _PreGenerationReviewCard extends StatelessWidget {
  const _PreGenerationReviewCard({
    required this.completed,
    required this.total,
    required this.teacherCount,
    required this.classCount,
    required this.lessonCount,
    required this.missing,
  });

  final int completed;
  final int total;
  final int teacherCount;
  final int classCount;
  final int lessonCount;
  final List<String> missing;

  bool get canGenerate => teacherCount > 0 && classCount > 0 && lessonCount > 0;

  @override
  Widget build(BuildContext context) {
    final checks = <({String label, bool ok})>[
      (label: 'Teachers configured', ok: teacherCount > 0),
      (label: 'Classes configured', ok: classCount > 0),
      (label: 'Lessons configured', ok: lessonCount > 0),
    ];

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pre-generation Review', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$completed of $total setup sections are ready.'),
            const SizedBox(height: 12),
            ...checks.map(
              (check) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      check.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: check.ok ? Colors.green : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(check.label),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (missing.isNotEmpty) ...[
              const Text('Still needed:'),
              const SizedBox(height: 4),
              ...missing.map((m) => Text('• $m')),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canGenerate
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const GenerationProgressScreen(),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Timetable'),
              ),
            ),
            if (!canGenerate) ...[
              const SizedBox(height: 8),
              Text(
                'Add at least 1 teacher, 1 class, and 1 lesson to enable generation.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderSectionScreen extends StatelessWidget {
  const _PlaceholderSectionScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen coming soon')),
    );
  }
}

class _SetupEntry {
  const _SetupEntry({required this.title, required this.description, required this.statusText, required this.warningCount, required this.builder});
  final String title;
  final String description;
  final String statusText;
  final int warningCount;
  final WidgetBuilder builder;
}
