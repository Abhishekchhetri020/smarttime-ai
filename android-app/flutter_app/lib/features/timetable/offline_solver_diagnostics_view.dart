import 'package:flutter/material.dart';

import 'offline_solver_models.dart';

class OfflineSolverDiagnosticsView extends StatelessWidget {
  final OfflineSolverResult result;

  const OfflineSolverDiagnosticsView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final diagnostics = result.diagnostics;
    final violations = result.hardViolations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Offline solver status: ${result.status}',
            key: const Key('offline-status')),
        const SizedBox(height: 8),
        Text('Solver: ${diagnostics.solverVersion}'),
        Text(
          'Lessons ${diagnostics.totals.assignedEntries}/${diagnostics.totals.lessonsRequested} assigned, '
          '${diagnostics.totals.hardViolations} unscheduled',
          key: const Key('diagnostics-summary'),
        ),
        Text(
          'Search: ${diagnostics.search.nodesVisited} nodes, ${diagnostics.search.backtracks} backtracks, '
          '${diagnostics.search.branchesPrunedByForwardCheck} pruned',
        ),
        const SizedBox(height: 8),
        const Text('Unscheduled reason counts',
            style: TextStyle(fontWeight: FontWeight.w600)),
        if (diagnostics.unscheduledReasonCounts.isEmpty)
          const Text('None')
        else
          ...diagnostics.unscheduledReasonCounts.entries.map((e) => Text(
              '${_prettyReason(e.key)}: ${e.value}',
              key: Key('reason-count-${e.key}'))),
        const SizedBox(height: 10),
        const Text('Unscheduled lessons',
            style: TextStyle(fontWeight: FontWeight.w600)),
        if (violations.isEmpty)
          const Text('No unscheduled lessons')
        else
          ...violations.map(
            (v) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${v.lessonId} • ${v.classId} • ${v.subjectId}'),
              subtitle: Text(
                  '${_prettyReason(v.reason)} (attempted ${v.attemptedSlots} slots)'),
            ),
          ),
      ],
    );
  }

  static String _prettyReason(String reason) {
    return reason
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }
}
