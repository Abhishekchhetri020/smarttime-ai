import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  final _name = TextEditingController();
  final _abbr = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Column(
      children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Subject name')),
        TextField(controller: _abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              if (_name.text.trim().isEmpty || _abbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addSubject(
                    SubjectItem(name: _name.text.trim(), abbr: _abbr.text.trim(), color: 0xFF0B3D91),
                  );
              _name.clear();
              _abbr.clear();
            },
            child: const Text('Add Subject'),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: planner.subjects.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(planner.subjects[i].name),
              subtitle: Text(planner.subjects[i].abbr),
            ),
          ),
        ),
      ],
    );
  }
}
