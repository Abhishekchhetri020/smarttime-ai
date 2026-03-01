import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../timetable/offline_solver_bridge.dart';
import 'planner_state.dart';
import 'setup/setup_wizard_screen.dart';
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

  Future<void> _generateNow() async {
    if (_busy) return;
    final planner = context.read<PlannerState>();
    if (!planner.hasMinimumData) {
      setState(() => _status =
          'Add at least 1 teacher, class, and subject before generating.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Generating offline timetable...';
    });

    try {
      final result = await OfflineSolverBridge.solve(
        payload: planner.toSolverPayload(),
      );
      setState(() => _status = 'Generated: ${result['status'] ?? 'ok'}');
    } catch (e) {
      setState(() => _status = 'Generate failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SetupWizardScreen(),
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
            Row(
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _generateNow,
                  child: const Text('Generate Now'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
