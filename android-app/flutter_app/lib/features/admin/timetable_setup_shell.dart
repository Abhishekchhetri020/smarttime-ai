import 'package:flutter/material.dart';

import 'widgets/setup_section_card.dart';

class TimetableSetupShell extends StatelessWidget {
  const TimetableSetupShell({super.key});

  static const List<_SetupEntry> _entries = <_SetupEntry>[
    _SetupEntry(
      title: 'Teachers',
      description: 'Add staff profiles, subjects, and availability basics.',
      statusText: 'Not started',
      warningCount: 0,
      icon: Icons.person_outline,
    ),
    _SetupEntry(
      title: 'Classes',
      description: 'Configure grade levels, divisions, and class strength.',
      statusText: 'Not started',
      warningCount: 0,
      icon: Icons.groups_outlined,
    ),
    _SetupEntry(
      title: 'Rooms',
      description: 'Define classrooms, labs, and room capacities.',
      statusText: 'Not started',
      warningCount: 0,
      icon: Icons.meeting_room_outlined,
    ),
    _SetupEntry(
      title: 'Subjects',
      description: 'Map curriculum subjects and weekly load targets.',
      statusText: 'Not started',
      warningCount: 0,
      icon: Icons.book_outlined,
    ),
    _SetupEntry(
      title: 'Lessons',
      description: 'Set lesson counts and placement requirements.',
      statusText: 'Not started',
      warningCount: 0,
      icon: Icons.view_week_outlined,
    ),
    _SetupEntry(
      title: 'Constraints',
      description: 'Capture hard rules and preferred scheduling patterns.',
      statusText: 'Not started',
      warningCount: 0,
      icon: Icons.rule_folder_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable Setup')),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProgressHeaderDelegate(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList.builder(
              itemCount: _entries.length + 1,
              itemBuilder: (context, index) {
                if (index == _entries.length) {
                  return _PreGenerationReviewCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _PlaceholderSectionScreen(
                            title: 'Pre-generation Review',
                          ),
                        ),
                      );
                    },
                  );
                }

                final _SetupEntry entry = _entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SetupSectionCard(
                    title: entry.title,
                    description: entry.description,
                    statusText: entry.statusText,
                    warningCount: entry.warningCount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _PlaceholderSectionScreen(
                            title: entry.title,
                            icon: entry.icon,
                          ),
                        ),
                      );
                    },
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
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: overlapsContent ? 1 : 0,
      color: scheme.surface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Setup Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(value: 0.0),
            const SizedBox(height: 6),
            Text(
              '0 of 6 sections completed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _PreGenerationReviewCard extends StatelessWidget {
  const _PreGenerationReviewCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Pre-generation Review'),
        subtitle: const Text(
          'Validate setup completeness and inspect warnings before generating.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _PlaceholderSectionScreen extends StatelessWidget {
  const _PlaceholderSectionScreen({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.construction_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              '$title screen coming soon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupEntry {
  const _SetupEntry({
    required this.title,
    required this.description,
    required this.statusText,
    required this.warningCount,
    required this.icon,
  });

  final String title;
  final String description;
  final String statusText;
  final int warningCount;
  final IconData icon;
}
