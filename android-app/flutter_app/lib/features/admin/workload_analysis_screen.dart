import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'planner_state.dart';

class WorkloadAnalysisScreen extends StatefulWidget {
  const WorkloadAnalysisScreen({super.key});

  @override
  State<WorkloadAnalysisScreen> createState() => _WorkloadAnalysisScreenState();
}

class _WorkloadAnalysisScreenState extends State<WorkloadAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final totalSlots = planner.workingDays *
        (planner.bellTimes.isEmpty ? 8 : planner.bellTimes.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Workload Analysis'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Teachers'),
            Tab(icon: Icon(Icons.class_outlined, size: 18), text: 'Classes'),
            Tab(icon: Icon(Icons.meeting_room_outlined, size: 18), text: 'Rooms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TeacherWorkload(planner: planner, totalSlots: totalSlots),
          _ClassWorkload(planner: planner, totalSlots: totalSlots),
          _RoomWorkload(planner: planner, totalSlots: totalSlots),
        ],
      ),
    );
  }
}

// ── Summary Chip ──
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Utilization Bar ──
class _UtilizationBar extends StatelessWidget {
  const _UtilizationBar({
    required this.name,
    required this.abbr,
    required this.assignedPeriods,
    required this.totalSlots,
    this.colorValue,
  });

  final String name;
  final String abbr;
  final int assignedPeriods;
  final int totalSlots;
  final int? colorValue;

  @override
  Widget build(BuildContext context) {
    final pct = totalSlots > 0 ? (assignedPeriods / totalSlots * 100) : 0.0;
    final barColor = pct > 85
        ? const Color(0xFFDC2626)
        : pct > 70
            ? const Color(0xFFD97706)
            : const Color(0xFF059669);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorValue != null
                  ? Color(colorValue!).withOpacity(0.12)
                  : barColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              abbr.length > 3 ? abbr.substring(0, 3) : abbr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorValue != null ? Color(colorValue!) : barColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: barColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${pct.round()}%',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: barColor)),
              Text('$assignedPeriods / $totalSlots',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Teacher Workload ──
class _TeacherWorkload extends StatelessWidget {
  const _TeacherWorkload({required this.planner, required this.totalSlots});
  final PlannerState planner;
  final int totalSlots;

  @override
  Widget build(BuildContext context) {
    if (planner.teachers.isEmpty) {
      return const Center(child: Text('No teachers added yet.'));
    }

    // Compute assigned periods per teacher
    final teacherPeriods = <String, int>{};
    for (final l in planner.lessons) {
      final periods = l.countPerWeek;
      for (final tid in l.teacherIds) {
        teacherPeriods[tid] = (teacherPeriods[tid] ?? 0) + periods;
      }
    }

    final totalTeachers = planner.teachers.length;
    final totalAssigned =
        teacherPeriods.values.fold<int>(0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _SummaryChip(
              label: 'Teachers',
              value: '$totalTeachers',
              color: AppTheme.motherSage,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Avg Load',
              value: totalTeachers > 0
                  ? '${(totalAssigned / totalTeachers).round()}p'
                  : '0p',
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Total Periods',
              value: '$totalAssigned',
              color: const Color(0xFFE11D48),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...planner.teachers.map((t) {
          final assigned = teacherPeriods[t.id] ?? 0;
          return _UtilizationBar(
            name: t.fullName,
            abbr: t.abbr,
            assignedPeriods: assigned,
            totalSlots: totalSlots,
          );
        }),
      ],
    );
  }
}

// ── Class Workload ──
class _ClassWorkload extends StatelessWidget {
  const _ClassWorkload({required this.planner, required this.totalSlots});
  final PlannerState planner;
  final int totalSlots;

  @override
  Widget build(BuildContext context) {
    if (planner.classes.isEmpty) {
      return const Center(child: Text('No classes added yet.'));
    }

    // Compute assigned periods per class
    final classPeriods = <String, int>{};
    for (final l in planner.lessons) {
      final periods = l.countPerWeek;
      for (final cid in l.classIds) {
        classPeriods[cid] = (classPeriods[cid] ?? 0) + periods;
      }
    }

    final totalClasses = planner.classes.length;
    final totalAssigned =
        classPeriods.values.fold<int>(0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _SummaryChip(
              label: 'Classes',
              value: '$totalClasses',
              color: AppTheme.accentAmber,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Avg Load',
              value: totalClasses > 0
                  ? '${(totalAssigned / totalClasses).round()}p'
                  : '0p',
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Total Periods',
              value: '$totalAssigned',
              color: const Color(0xFFE11D48),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...planner.classes.map((c) {
          final assigned = classPeriods[c.id] ?? 0;
          return _UtilizationBar(
            name: c.name,
            abbr: c.abbr,
            assignedPeriods: assigned,
            totalSlots: totalSlots,
          );
        }),
      ],
    );
  }
}

// ── Room Workload ──
class _RoomWorkload extends StatelessWidget {
  const _RoomWorkload({required this.planner, required this.totalSlots});
  final PlannerState planner;
  final int totalSlots;

  @override
  Widget build(BuildContext context) {
    if (planner.classrooms.isEmpty) {
      return const Center(child: Text('No rooms added yet.'));
    }

    // Compute assigned periods per room
    final roomPeriods = <String, int>{};
    for (final l in planner.lessons) {
      if (l.requiredClassroomId != null) {
        roomPeriods[l.requiredClassroomId!] =
            (roomPeriods[l.requiredClassroomId!] ?? 0) + l.countPerWeek;
      }
    }

    final totalRooms = planner.classrooms.length;
    final totalAssigned =
        roomPeriods.values.fold<int>(0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _SummaryChip(
              label: 'Rooms',
              value: '$totalRooms',
              color: const Color(0xFF0891B2),
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'In Use',
              value: '${roomPeriods.keys.length}',
              color: const Color(0xFF059669),
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Total Periods',
              value: '$totalAssigned',
              color: const Color(0xFFE11D48),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...planner.classrooms.map((r) {
          final assigned = roomPeriods[r.id] ?? 0;
          return _UtilizationBar(
            name: r.name,
            abbr: r.abbr ?? r.name.substring(0, r.name.length > 2 ? 2 : r.name.length),
            assignedPeriods: assigned,
            totalSlots: totalSlots,
            colorValue: r.color != null ? int.tryParse(r.color!) : null,
          );
        }),
      ],
    );
  }
}
