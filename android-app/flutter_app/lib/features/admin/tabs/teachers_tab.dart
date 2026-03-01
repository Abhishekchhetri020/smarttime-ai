import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class TeachersTab extends StatefulWidget {
  const TeachersTab({super.key});

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _abbr = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Column(
      children: [
        TextField(controller: _first, decoration: const InputDecoration(labelText: 'First name')),
        TextField(controller: _last, decoration: const InputDecoration(labelText: 'Last name')),
        TextField(controller: _abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              if (_first.text.trim().isEmpty || _abbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addTeacher(
                    TeacherItem(
                      firstName: _first.text.trim(),
                      lastName: _last.text.trim(),
                      abbr: _abbr.text.trim(),
                    ),
                  );
              _first.clear();
              _last.clear();
              _abbr.clear();
            },
            child: const Text('Add Teacher'),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: planner.teachers.length,
            itemBuilder: (_, i) => ListTile(
              title: Text('${planner.teachers[i].firstName} ${planner.teachers[i].lastName}'.trim()),
              subtitle: Text(planner.teachers[i].abbr),
            ),
          ),
        ),
      ],
    );
  }
}
