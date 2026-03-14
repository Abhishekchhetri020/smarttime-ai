import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/bulk_import_service.dart';
import '../../core/theme/app_theme.dart';
import 'planner_state.dart';
import 'timetable_setup_shell.dart';

class TimetableDashboardScreen extends StatelessWidget {
  const TimetableDashboardScreen({super.key});

  Future<void> _importFromExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final importer = BulkImportService();
      final lessonsFile = await importer.pickLessonsMasterCsv();
      if (lessonsFile == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Import cancelled.')));
        return;
      }
      final constraintsFile = await importer.pickTeachersConstraintsCsv();
      final planner = context.read<PlannerState>();
      final db = planner.db;
      if (db == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Database not ready. Try again.')));
        return;
      }
      final summary = await importer.importMasterCsvData(
        db,
        lessonsFile: lessonsFile,
        teachersFile: constraintsFile,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import complete • ${summary.lessons} lessons, ${summary.teachers} teachers, ${summary.rooms} rooms.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar with gradient ──
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                planner.schoolName.isNotEmpty ? planner.schoolName : 'SmartTime AI',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.motherSage,
                      AppTheme.sageDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Timetable Generator',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'AI-Powered Scheduling',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Live Stats Row ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _LiveStatsRow(planner: planner),
            ),
          ),

          // ── Hero Action Card ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _HeroActionCard(
                canGenerate: planner.hasMinimumData,
                onCreate: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TimetableSetupShell(),
                    ),
                  );
                },
                onImport: () => _importFromExcel(context),
              ),
            ),
          ),

          // ── Quick Actions Grid ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _QuickActionsGrid(
                    onCreate: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TimetableSetupShell(),
                        ),
                      );
                    },
                    onImport: () => _importFromExcel(context),
                  ),
                ],
              ),
            ),
          ),

          // ── Status Card ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _StatusCard(planner: planner),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Stats Row ──
class _LiveStatsRow extends StatelessWidget {
  const _LiveStatsRow({required this.planner});
  final PlannerState planner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.person_outline_rounded,
          label: 'Teachers',
          value: '${planner.teachers.length}',
          color: AppTheme.motherSage,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.class_outlined,
          label: 'Classes',
          value: '${planner.classes.length}',
          color: AppTheme.accentAmber,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.menu_book_outlined,
          label: 'Subjects',
          value: '${planner.subjects.length}',
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.auto_stories_outlined,
          label: 'Lessons',
          value: '${planner.lessons.length}',
          color: const Color(0xFFE11D48),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.espresso.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Action Card ──
class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.canGenerate,
    required this.onCreate,
    required this.onImport,
  });

  final bool canGenerate;
  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.motherSage.withValues(alpha: 0.08),
            AppTheme.accentAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.motherSage.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.motherSage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.motherSage,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Your Timetable',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canGenerate
                          ? 'Your data is ready. Start generating!'
                          : 'Setup teachers, classes, and lessons to begin.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Timetable'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Import Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ──
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onCreate,
    required this.onImport,
  });

  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.tune_rounded,
          label: 'Setup\nWizard',
          color: AppTheme.motherSage,
          onTap: onCreate,
        ),
        const SizedBox(width: 10),
        _ActionTile(
          icon: Icons.file_download_outlined,
          label: 'Import\nTemplate',
          color: const Color(0xFF6366F1),
          onTap: onImport,
        ),
        const SizedBox(width: 10),
        _ActionTile(
          icon: Icons.grid_on_rounded,
          label: 'Export\nExcel',
          color: const Color(0xFF059669),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generate a timetable first to export.')),
            );
          },
        ),
        const SizedBox(width: 10),
        _ActionTile(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Export\nPDF',
          color: const Color(0xFFE11D48),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generate a timetable first to export.')),
            );
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.espresso.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status Card ──
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.planner});
  final PlannerState planner;

  @override
  Widget build(BuildContext context) {
    final hasData = planner.hasMinimumData;

    return Container(
      decoration: BoxDecoration(
        color: hasData
            ? AppTheme.successGreen.withValues(alpha: 0.06)
            : AppTheme.accentAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? AppTheme.successGreen.withValues(alpha: 0.2)
              : AppTheme.accentAmber.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            hasData ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
            color: hasData ? AppTheme.successGreen : AppTheme.accentAmber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? 'Ready to Generate' : 'Setup Required',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: hasData ? AppTheme.successGreen : AppTheme.espresso,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData
                      ? 'All minimum data configured. Tap "New Timetable" to begin.'
                      : 'Add at least 1 teacher, 1 class, and 1 lesson to start.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
