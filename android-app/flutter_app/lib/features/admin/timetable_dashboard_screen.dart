import 'package:flutter/material.dart';

import 'timetable_setup_shell.dart';

class TimetableDashboardScreen extends StatelessWidget {
  const TimetableDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartTime AI')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _HeroCard(
                onCreate: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TimetableSetupShell(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Recent Timetables',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.schedule)),
                    title: Text('Timetable Draft ${index + 1}'),
                    subtitle: const Text('Placeholder - no saved runs yet'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build your next timetable',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start with setup sections and review everything before generation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New Timetable'),
            ),
          ],
        ),
      ),
    );
  }
}
