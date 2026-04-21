import 'package:flutter/material.dart';

import '../../data/conflict_service.dart';

class PreflightWarningsPanel extends StatelessWidget {
  const PreflightWarningsPanel({
    super.key,
    required this.warnings,
    required this.onJump,
  });

  final List<PreflightWarning> warnings;
  final ValueChanged<PreflightWarning> onJump;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    final critical =
        warnings.where((w) => w.severity == WarningSeverity.critical).toList();
    final suggestion = warnings
        .where((w) => w.severity == WarningSeverity.suggestion)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (critical.isNotEmpty) ...[
          const Text('Critical',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...critical.map((w) =>
              _WarningTile(warning: w, onJump: onJump, bg: Colors.red.shade50)),
          const SizedBox(height: 8),
        ],
        if (suggestion.isNotEmpty) ...[
          const Text('Suggestion',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...suggestion.map((w) => _WarningTile(
              warning: w, onJump: onJump, bg: Colors.amber.shade50)),
        ],
      ],
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile({
    required this.warning,
    required this.onJump,
    required this.bg,
  });

  final PreflightWarning warning;
  final ValueChanged<PreflightWarning> onJump;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(warning.message, style: const TextStyle(fontSize: 12))),
          TextButton(
            onPressed: () => onJump(warning),
            child: const Text('Jump to Conflict'),
          ),
        ],
      ),
    );
  }
}
