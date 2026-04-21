import 'package:flutter/material.dart';

import '../../../core/database.dart';
import '../../../core/theme/app_theme.dart';

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

        return Row(
          children: [
            _AnalyticsCard(
              icon: Icons.event_available_rounded,
              title: 'Assigned',
              value: '${data.totalAssignedLessons}',
              color: AppTheme.motherSage,
            ),
            const SizedBox(width: 8),
            _AnalyticsCard(
              icon: Icons.warning_amber_rounded,
              title: 'Conflicts',
              value: '${data.hardConflictCount}',
              color: data.hardConflictCount > 0
                  ? AppTheme.errorRed
                  : AppTheme.successGreen,
            ),
            const SizedBox(width: 8),
            _AnalyticsCard(
              icon: Icons.timelapse_rounded,
              title: 'Avg Gaps',
              value: data.averageTeacherGaps.toStringAsFixed(1),
              color: data.averageTeacherGaps > 2.0
                  ? AppTheme.accentAmber
                  : AppTheme.motherSage,
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                final isDecimal = value.contains('.');
                return Text(
                  isDecimal
                      ? animated.toStringAsFixed(1)
                      : animated.toInt().toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.espresso.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
