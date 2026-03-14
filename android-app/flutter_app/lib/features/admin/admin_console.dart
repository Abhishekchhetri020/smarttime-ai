import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'planner_state.dart';
import '../timetable/offline_solver_bridge.dart';

class AdminConsole extends StatefulWidget {
  const AdminConsole({super.key, required this.role});
  final String role;

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  final _teacherFirst = TextEditingController();
  final _teacherLast = TextEditingController();
  final _teacherAbbr = TextEditingController();

  final _className = TextEditingController(text: 'VII A');
  final _classAbbr = TextEditingController(text: 'VIIA');

  final _subjectName = TextEditingController(text: 'Mathematics');
  final _subjectAbbr = TextEditingController(text: 'MATH');

  String _status = '';
  bool _busy = false;

  Future<void> _generateNow() async {
    if (_busy) return;
    final planner = context.read<PlannerState>(); // correct context usage
    if (!planner.hasMinimumData) {
      setState(() => _status = 'Add at least 1 teacher, class, and subject first.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Generating offline timetable...';
    });

    try {
      final payload = planner.toSolverPayload();
      final result = await OfflineSolverBridge.solve(payload: payload);
      setState(() => _status = 'Generated: ${result['status'] ?? 'ok'}');
    } catch (e) {
      setState(() => _status = 'Generate failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.role} Console', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),

          const Text('Add Teacher'),
          TextField(controller: _teacherFirst, decoration: const InputDecoration(hintText: 'First Name')),
          TextField(controller: _teacherLast, decoration: const InputDecoration(hintText: 'Last Name')),
          TextField(controller: _teacherAbbr, decoration: const InputDecoration(hintText: 'Abbreviation')),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              if (_teacherFirst.text.trim().isEmpty || _teacherAbbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addTeacher(
                    TeacherItem(
                      firstName: _teacherFirst.text.trim(),
                      lastName: _teacherLast.text.trim(),
                      abbr: _teacherAbbr.text.trim(),
                    ),
                  );
              _teacherFirst.clear();
              _teacherLast.clear();
              _teacherAbbr.clear();
              setState(() => _status = 'Teacher saved');
            },
            child: const Text('Save Teacher'),
          ),

          const Divider(height: 24),
          const Text('Add Class'),
          TextField(controller: _className, decoration: const InputDecoration(hintText: 'Class Name')),
          TextField(controller: _classAbbr, decoration: const InputDecoration(hintText: 'Class Abbreviation')),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              if (_className.text.trim().isEmpty || _classAbbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addClass(
                    ClassItem(name: _className.text.trim(), abbr: _classAbbr.text.trim()),
                  );
              setState(() => _status = 'Class saved');
            },
            child: const Text('Save Class'),
          ),

          const Divider(height: 24),
          const Text('Add Subject'),
          TextField(controller: _subjectName, decoration: const InputDecoration(hintText: 'Subject Name')),
          TextField(controller: _subjectAbbr, decoration: const InputDecoration(hintText: 'Subject Abbreviation')),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              if (_subjectName.text.trim().isEmpty || _subjectAbbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addSubject(
                    SubjectItem(
                      name: _subjectName.text.trim(),
                      abbr: _subjectAbbr.text.trim(),
                      color: 0xFF0B3D91,
                    ),
                  );
              setState(() => _status = 'Subject saved');
            },
            child: const Text('Save Subject'),
          ),

          const Divider(height: 24),
          Text('Planner Data: T=${planner.teachers.length}, C=${planner.classes.length}, S=${planner.subjects.length}'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _generateNow,
            child: const Text('Generate Now'),
          ),
          const SizedBox(height: 10),
          if (_status.isNotEmpty) Text(_status),
        ],
      ),
    );
  }
}
