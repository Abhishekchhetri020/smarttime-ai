import 'package:flutter/material.dart';

import '../../../../core/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../timetable_display.dart';

/// Full-screen bottom sheet showing detailed insights after generation.
///
/// Matches the reference app's "Timetable Generation Insights" panel with:
/// - Completion percentage bar
/// - Scheduled / Unscheduled lesson counts
/// - Lesson distribution by day
/// - Class / Teacher / Room period usage bars
/// - Lesson unit distribution analysis
class GenerationInsightsSheet extends StatelessWidget {
  const GenerationInsightsSheet({
    super.key,
    required this.db,
    required this.dbId,
  });

  final AppDatabase db;
  final int dbId;

  Future<_InsightsData> _compute() async {
    final cards = await db.select(db.cards).get();
    final lessons = await db.select(db.lessons).get();
    final subjects = await db.select(db.subjects).get();
    final teachers = await db.select(db.teachers).get();
    final classes = await db.select(db.classes).get();
    final plannerSnap = await db.loadPlannerSnapshot(dbId);

    final catalog = TimetableDisplayCatalog.fromDatabase(
      subjects: subjects,
      teachers: teachers,
      classes: classes,
      plannerSnapshot: plannerSnap,
    );

    // Days from planner
    final workingDays = (plannerSnap?['workingDays'] as int?) ?? 6;
    final dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final activeDays = dayNames.sublist(0, workingDays.clamp(1, 7));

    // Periods per day from schedule entries
    final entries = ((plannerSnap?['scheduleEntries'] as List?) ?? const [])
        .whereType<Map>()
        .where((e) => (e['type']?.toString() ?? '').toLowerCase() != 'break')
        .length;
    final periodsPerDay = entries > 0 ? entries : 6;

    // Total required vs scheduled
    final totalRequired = lessons.fold<int>(0, (s, l) => s + l.periodsPerWeek);
    final totalScheduled = cards.length;
    final totalUnscheduled = (totalRequired - totalScheduled).clamp(0, totalRequired);
    final completion = totalRequired > 0 ? totalScheduled / totalRequired : 0.0;

    // Lesson distribution by day
    final dayDist = List<int>.filled(workingDays, 0);
    for (final c in cards) {
      final d = c.dayIndex;
      if (d >= 0 && d < workingDays) dayDist[d]++;
    }

    // Class period usage
    final classUsage = <_UsageRow>[];
    for (final cls in classes) {
      final clsLessons = lessons.where((l) => l.classIds.contains(cls.id));
      final clsRequired = clsLessons.fold<int>(0, (s, l) => s + l.periodsPerWeek);
      final clsCards = cards.where((c) {
        final l = lessons.firstWhere((l) => l.id == c.lessonId, orElse: () => lessons.first);
        return l.classIds.contains(cls.id);
      }).length;
      classUsage.add(_UsageRow(
        label: cls.abbr.isNotEmpty ? cls.abbr : cls.name,
        used: clsCards,
        total: clsRequired,
      ));
    }

    // Teacher period usage
    final teacherUsage = <_UsageRow>[];
    for (final t in teachers) {
      final tLessons = lessons.where((l) => l.teacherIds.contains(t.id));
      final tRequired = tLessons.fold<int>(0, (s, l) => s + l.periodsPerWeek);
      final tCards = cards.where((c) {
        final l = lessons.firstWhere((l) => l.id == c.lessonId, orElse: () => lessons.first);
        return l.teacherIds.contains(t.id);
      }).length;
      teacherUsage.add(_UsageRow(
        label: t.abbreviation.isNotEmpty ? t.abbreviation : t.name,
        used: tCards,
        total: tRequired,
      ));
    }

    // Room period usage
    final roomUsage = <_UsageRow>[];
    final roomMap = <String, int>{};
    for (final c in cards) {
      if (c.roomId != null && c.roomId!.isNotEmpty) {
        roomMap[c.roomId!] = (roomMap[c.roomId!] ?? 0) + 1;
      }
    }
    for (final entry in roomMap.entries) {
      roomUsage.add(_UsageRow(
        label: catalog.roomLabel(entry.key) ?? entry.key,
        used: entry.value,
        total: periodsPerDay * workingDays,
      ));
    }

    // Distribution analysis
    final lessonById = {for (final l in lessons) l.id: l};
    final cardsByLesson = <String, List<CardRow>>{};
    for (final c in cards) {
      cardsByLesson.putIfAbsent(c.lessonId, () => []).add(c);
    }

    int perfectCount = 0;
    int poorCount = 0;
    final poorLessons = <_PoorDistribution>[];

    for (final l in lessons) {
      final lCards = cardsByLesson[l.id] ?? [];
      if (lCards.isEmpty) continue;

      // Day distribution
      final dayBuckets = List<int>.filled(workingDays, 0);
      for (final c in lCards) {
        if (c.dayIndex >= 0 && c.dayIndex < workingDays) {
          dayBuckets[c.dayIndex]++;
        }
      }

      final usedDays = dayBuckets.where((d) => d > 0).length;
      final idealSpread = l.periodsPerWeek <= workingDays
          ? l.periodsPerWeek
          : workingDays;
      final isPerfect = usedDays >= idealSpread;

      if (isPerfect) {
        perfectCount++;
      } else {
        poorCount++;
        // Build ideal distribution
        final idealPerDay = List<int>.filled(workingDays, 0);
        var remaining = l.periodsPerWeek;
        for (var d = 0; d < workingDays && remaining > 0; d++) {
          idealPerDay[d] = remaining > 0 ? 1 : 0;
          remaining--;
        }

        poorLessons.add(_PoorDistribution(
          subjectLabel: catalog.subjectLabel(l.subjectId),
          teacherLabel: catalog.joinTeacherLabels(l.teacherIds),
          unitLength: 1,
          totalUnits: l.periodsPerWeek,
          totalPeriods: l.periodsPerWeek,
          availableDays: workingDays,
          actualDist: dayBuckets,
          idealDist: idealPerDay,
          dayNames: activeDays,
        ));
      }
    }
    // Sort poorLessons worst first
    poorLessons.sort((a, b) {
      final aSpread = a.actualDist.where((d) => d > 0).length;
      final bSpread = b.actualDist.where((d) => d > 0).length;
      return aSpread.compareTo(bSpread);
    });

    return _InsightsData(
      completion: completion,
      totalScheduled: totalScheduled,
      totalUnscheduled: totalUnscheduled,
      totalRequired: totalRequired,
      dayDistribution: dayDist,
      dayNames: activeDays,
      classUsage: classUsage,
      teacherUsage: teacherUsage,
      roomUsage: roomUsage,
      perfectCount: perfectCount,
      poorCount: poorCount,
      totalAnalyzed: perfectCount + poorCount,
      poorLessons: poorLessons,
    );
  }

  static void show(BuildContext context, AppDatabase db, int dbId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GenerationInsightsSheet(db: db, dbId: dbId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InsightsData>(
      future: _compute(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        return Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.indigo, AppTheme.indigoDark],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Timetable Generation Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: Colors.white70, size: 22),
                  ),
                ],
              ),
            ),
            // Scrollable body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CompletionCard(d),
                  const SizedBox(height: 12),
                  _CountCard(
                    icon: Icons.check_circle_outline,
                    iconColor: AppTheme.successGreen,
                    title: 'Scheduled Lessons',
                    count: d.totalScheduled,
                    subtitle:
                        '${d.totalScheduled} total periods (includes multi-period lessons)',
                  ),
                  const SizedBox(height: 12),
                  _CountCard(
                    icon: Icons.cancel_outlined,
                    iconColor: AppTheme.errorRed,
                    title: 'Unscheduled Lessons',
                    count: d.totalUnscheduled,
                    subtitle:
                        '${d.totalUnscheduled} total periods (includes multi-period lessons)',
                    countColor: AppTheme.errorRed,
                  ),
                  const SizedBox(height: 16),
                  _DayDistributionCard(d),
                  const SizedBox(height: 16),
                  _UsageSection(
                    icon: Icons.grid_view_rounded,
                    title: 'Class Period Usage',
                    rows: d.classUsage,
                  ),
                  const SizedBox(height: 16),
                  _UsageSection(
                    icon: Icons.people_alt_outlined,
                    title: 'Teacher Period Usage',
                    rows: d.teacherUsage,
                  ),
                  const SizedBox(height: 16),
                  _UsageSection(
                    icon: Icons.access_time_outlined,
                    title: 'Room Period Usage',
                    rows: d.roomUsage,
                  ),
                  const SizedBox(height: 16),
                  _DistributionAnalysisCard(d),
                  if (d.poorLessons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PoorDistributionList(d.poorLessons),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _InsightsData {
  final double completion;
  final int totalScheduled;
  final int totalUnscheduled;
  final int totalRequired;
  final List<int> dayDistribution;
  final List<String> dayNames;
  final List<_UsageRow> classUsage;
  final List<_UsageRow> teacherUsage;
  final List<_UsageRow> roomUsage;
  final int perfectCount;
  final int poorCount;
  final int totalAnalyzed;
  final List<_PoorDistribution> poorLessons;

  const _InsightsData({
    required this.completion,
    required this.totalScheduled,
    required this.totalUnscheduled,
    required this.totalRequired,
    required this.dayDistribution,
    required this.dayNames,
    required this.classUsage,
    required this.teacherUsage,
    required this.roomUsage,
    required this.perfectCount,
    required this.poorCount,
    required this.totalAnalyzed,
    required this.poorLessons,
  });
}

class _UsageRow {
  final String label;
  final int used;
  final int total;
  const _UsageRow({required this.label, required this.used, required this.total});
}

class _PoorDistribution {
  final String subjectLabel;
  final String teacherLabel;
  final int unitLength;
  final int totalUnits;
  final int totalPeriods;
  final int availableDays;
  final List<int> actualDist;
  final List<int> idealDist;
  final List<String> dayNames;

  const _PoorDistribution({
    required this.subjectLabel,
    required this.teacherLabel,
    required this.unitLength,
    required this.totalUnits,
    required this.totalPeriods,
    required this.availableDays,
    required this.actualDist,
    required this.idealDist,
    required this.dayNames,
  });
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  const _CompletionCard(this.d);
  final _InsightsData d;

  @override
  Widget build(BuildContext context) {
    final pct = (d.completion * 100).toStringAsFixed(1);
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rtl, size: 20, color: AppTheme.indigo),
              const SizedBox(width: 8),
              const Text('Timetable Completion',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('$pct%',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.indigo)),
              const SizedBox(width: 12),
              Text('${d.totalScheduled} / ${d.totalRequired} periods',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: d.completion.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.indigo),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.subtitle,
    this.countColor,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final String subtitle;
  final Color? countColor;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$count',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: countColor ?? AppTheme.indigo)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _DayDistributionCard extends StatelessWidget {
  const _DayDistributionCard(this.d);
  final _InsightsData d;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: AppTheme.indigo),
              const SizedBox(width: 8),
              const Text('Lesson Distribution by Day',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < d.dayDistribution.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(d.dayNames[i],
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text('${d.dayDistribution[i]} periods',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.indigo)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({
    required this.icon,
    required this.title,
    required this.rows,
  });
  final IconData icon;
  final String title;
  final List<_UsageRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.indigo),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in rows) ...[
            Row(
              children: [
                Expanded(
                    child: Text(r.label,
                        style: const TextStyle(fontSize: 13))),
                Text(
                  '${r.used} / ${r.total} periods (${r.total > 0 ? ((r.used / r.total) * 100).toStringAsFixed(1) : 0}%)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: r.total > 0
                    ? (r.used / r.total).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  r.total > 0 && r.used / r.total >= 1.0
                      ? AppTheme.errorRed
                      : AppTheme.indigo,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DistributionAnalysisCard extends StatelessWidget {
  const _DistributionAnalysisCard(this.d);
  final _InsightsData d;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: AppTheme.indigo),
              const SizedBox(width: 8),
              const Text('Lesson Unit Distribution\nAnalysis',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _StatPill(
            label: 'Perfectly Distributed',
            count: d.perfectCount,
            color: AppTheme.successGreen,
            bgColor: AppTheme.successGreen.withOpacity(0.15),
          ),
          const SizedBox(height: 8),
          _StatPill(
            label: 'Poor Distribution',
            count: d.poorCount,
            color: AppTheme.errorRed,
            bgColor: AppTheme.errorRed.withOpacity(0.15),
          ),
          const SizedBox(height: 8),
          _StatPill(
            label: 'Total Analyzed',
            count: d.totalAnalyzed,
            color: AppTheme.indigo,
            bgColor: AppTheme.indigoLight,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const Spacer(),
          Text('$count',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _PoorDistributionList extends StatelessWidget {
  const _PoorDistributionList(this.items);
  final List<_PoorDistribution> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 20, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Lessons with Poor Distribution',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Text('(Worst first)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          _PoorDistCard(item: items[i], rank: i + 1),
          if (i < items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PoorDistCard extends StatelessWidget {
  const _PoorDistCard({required this.item, required this.rank});
  final _PoorDistribution item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view, size: 16, color: AppTheme.errorRed),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('#$rank',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorRed)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Subjects: ', style: TextStyle(fontSize: 12)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.indigoLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.subjectLabel,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14),
              const SizedBox(width: 4),
              const Text('Teachers: ', style: TextStyle(fontSize: 12)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.teacherLabel,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat('Unit Length', '${item.unitLength}\nperiod'),
              const SizedBox(width: 16),
              _MiniStat('Total Units', '${item.totalUnits}'),
            ],
          ),
          Row(
            children: [
              _MiniStat('Total Periods', '${item.totalPeriods}'),
              const SizedBox(width: 16),
              _MiniStat('Available Days', '${item.availableDays}'),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Actual Distribution (Units per Day):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _DayGrid(
            days: item.dayNames,
            values: item.actualDist,
            highlight: true,
          ),
          const SizedBox(height: 8),
          const Text('Periods per Day:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _DayGrid(
            days: item.dayNames,
            values: item.actualDist,
            highlight: false,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Current issue: Uneven distribution of lesson units across available days',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.indigo)),
        ],
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.days,
    required this.values,
    required this.highlight,
  });
  final List<String> days;
  final List<int> values;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length && i < values.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: highlight && values[i] > 0
                    ? AppTheme.errorRed.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(days[i].substring(0, 3),
                      style:
                          const TextStyle(fontSize: 9, color: Colors.black54)),
                  Text('${values[i]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: highlight && values[i] > 0
                            ? AppTheme.errorRed
                            : Colors.grey.shade700,
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
