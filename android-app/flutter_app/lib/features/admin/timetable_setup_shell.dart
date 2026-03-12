import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  const _PreGenerationReviewCard({required this.completed, required this.total, required this.missing});

  final int completed;
  final int total;
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 8),
            if (missing.isEmpty)
              const Text('Ready for the next generation phase.')
            else ...[
              const Text('Still needed:'),
              const SizedBox(height: 4),
              ...missing.map((m) => Text('• $m')),
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
