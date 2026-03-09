import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../timetable/engine_bridge.dart';
import '../timetable/presentation/screens/solver_debug_screen.dart';
import '../timetable/presentation/screens/cockpit_screen.dart';
import '../../core/database.dart';
import '../../core/services/export_service.dart';
import '../timetable/data/conflict_service.dart';
import 'planner_state.dart';
import 'setup/setup_wizard_screen.dart';
import 'widgets/dashboard_analytics_widget.dart';
import 'tabs/classes_tab.dart';
import 'tabs/classrooms_tab.dart';
import 'tabs/subjects_tab.dart';
import 'tabs/teachers_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.role});

  final String role;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _status = '';
  bool _busy = false;
  List<PreflightWarning> _warnings = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportSchedule() async {
    final planner = context.read<PlannerState>();
    final db = planner.db;
    if (db == null) {
      setState(() => _status = 'Database unavailable.');
      return;
    }
    try {
      await ExportService().shareSmarttimeFile(db);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Exported and opened share sheet (.smarttime)')),
        );
      }
      setState(() => _status = 'Export complete');
    } catch (e) {
      setState(() => _status = 'Export failed: $e');
    }
  }

  Future<void> _importSchedule() async {
    final planner = context.read<PlannerState>();
    final db = planner.db;
    if (db == null) {
      setState(() => _status = 'Database unavailable.');
      return;
    }
    try {
      await ExportService().importSmarttimeFromPicker(db);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import complete (.smarttime)')),
        );
      }
      setState(() => _status = 'Import complete');
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    }
  }

  Future<void> _generateNow() async {
    if (_busy) return;
    final planner = context.read<PlannerState>();
    final db = planner.db;
    if (db == null) {
      setState(() => _status = 'Database unavailable. Complete setup first.');
      return;
    }
    if (!planner.hasMinimumData) {
      setState(() => _status =
          'Add at least 1 teacher, class, and subject before generating.');
      return;
    }

    final warnings = ConflictService().preflight(planner);

    setState(() {
      _warnings = warnings;
      _busy = true;
      _status = warnings.isEmpty
          ? 'Generating...'
          : 'Generating... (${warnings.length} warning(s))';
    });

    try {
      final teacherRows = await db.select(db.teachers).get();
      final classRows = await db.select(db.classes).get();
      final lessonRows = await db.select(db.lessons).get();
      final cardRows = await db.select(db.cards).get();

      final roomIds = <String>{
        ...cardRows.map((c) => c.roomId).whereType<String>(),
      };

      final payload = EnginePayload(
        teachers: teacherRows
            .map((t) => {'id': t.id, 'name': t.name, 'abbr': t.abbreviation})
            .toList(growable: false),
        classes: classRows
            .map((c) => {'id': c.id, 'name': c.name, 'abbr': c.abbr})
            .toList(growable: false),
        rooms: roomIds.map((r) => {'id': r}).toList(growable: false),
        lessons: lessonRows
            .map((l) => {
                  'id': l.id,
                  'subjectId': l.subjectId,
                  'teacherIds': l.teacherIds,
                  'classIds': l.classIds,
                  'periodsPerWeek': l.periodsPerWeek,
                  'fixedDay': l.fixedDay,
                  'fixedPeriod': l.fixedPeriod,
                })
            .toList(growable: false),
      );

      final nativeResponse = await EngineBridge.triggerSolver(payload);
      debugPrint('EngineBridge response: $nativeResponse');

      final cardsRaw = (nativeResponse['cards'] as List?) ?? const [];
      if (cardsRaw.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Engine returned empty cards list')),
          );
        }
      }
      final cardCompanions = <CardsCompanion>[];
      var idx = 0;
      for (final item in cardsRaw) {
        if (item is! Map) continue;
        final lessonId = item['lessonId']?.toString();
        final dayIndex = item['dayIndex'] as int?;
        final periodIndex = item['periodIndex'] as int?;
        if (lessonId == null || dayIndex == null || periodIndex == null)
          continue;
        final roomId = item['roomId']?.toString();
        cardCompanions.add(
          CardsCompanion.insert(
            id: 'card_${lessonId}_${dayIndex}_${periodIndex}_$idx',
            lessonId: lessonId,
            dayIndex: dayIndex,
            periodIndex: periodIndex,
            roomId: Value(roomId),
          ),
        );
        idx++;
      }

      debugPrint('SAVING ${cardCompanions.length} CARDS...');
      await db.transaction(() async {
        await db.delete(db.cards).go();
        if (cardCompanions.isNotEmpty) {
          await db.batch((b) => b.insertAll(db.cards, cardCompanions));
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule Saved Successfully')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CockpitScreen(db: db)),
      );

      final cards = cardCompanions.length;
      setState(() => _status =
          '${nativeResponse['message'] ?? nativeResponse['status'] ?? 'ok'} • cards:$cards');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Engine/SQLite error: $e')),
        );
      }
      setState(() => _status = 'Generate failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Setup Wizard',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          planner.schoolName.isEmpty
                              ? 'Complete setup before generation.'
                              : 'School: ${planner.schoolName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Setup Wizard')),
                          body: const Padding(
                            padding: EdgeInsets.all(12),
                            child: SingleChildScrollView(
                                child: SetupWizardScreen()),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Open Setup'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (planner.db != null) DashboardAnalyticsWidget(db: planner.db!),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Subjects'),
                Tab(text: 'Classes'),
                Tab(text: 'Teachers'),
                Tab(text: 'Classrooms'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  SubjectsTab(),
                  ClassesTab(),
                  TeachersTab(),
                  ClassroomsTab(),
                ],
              ),
            ),
            if (_warnings.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pre-Flight Warnings',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    for (final w in _warnings)
                      Text('• ${w.message}',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _generateNow,
                  child: const Text('Generate Now'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _exportSchedule,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Export Schedule'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _importSchedule,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import .smarttime'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SolverDebugScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Grid Debug'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final db = planner.db;
                    if (db == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CockpitScreen(db: db),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('Open Cockpit'),
                ),
                SizedBox(
                  width: 280,
                  child: Text(
                    _status,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
