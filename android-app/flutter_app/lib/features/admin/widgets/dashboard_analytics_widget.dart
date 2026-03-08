import 'package:flutter/material.dart';

import '../../../core/database.dart';

class DashboardAnalyticsWidget extends StatelessWidget {
  const DashboardAnalyticsWidget({
    super.key,
    required this.db,
  });

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnalyticsSnapshot>(
      stream: db.watchAnalytics(),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            const AnalyticsSnapshot(
              totalAssignedLessons: 0,
              hardConflictCount: 0,
              averageTeacherGaps: 0,
            );

        Widget card(String title, String value, Color color) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );

        return Row(
          children: [
            card('Total Assigned Lessons', '${data.totalAssignedLessons}', Colors.blue.shade50),
            card('Hard Conflict Count', '${data.hardConflictCount}', Colors.red.shade50),
            card('Avg Teacher Gaps', data.averageTeacherGaps.toStringAsFixed(1), Colors.amber.shade50),
          ],
        );
      },
    );
  }
}
