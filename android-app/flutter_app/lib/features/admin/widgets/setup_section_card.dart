import 'package:flutter/material.dart';

class SetupSectionCard extends StatelessWidget {
  const SetupSectionCard({
    super.key,
    required this.title,
    required this.description,
    required this.statusText,
    required this.warningCount,
    required this.onTap,
  });

  final String title;
  final String description;
  final String statusText;
  final int warningCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(statusText),
                    avatar: const Icon(Icons.info_outline, size: 18),
                  ),
                  if (warningCount > 0)
                    Chip(
                      backgroundColor: scheme.errorContainer,
                      labelStyle: TextStyle(color: scheme.onErrorContainer),
                      label: Text(
                        '$warningCount warning${warningCount == 1 ? '' : 's'}',
                      ),
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: scheme.onErrorContainer,
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
}
