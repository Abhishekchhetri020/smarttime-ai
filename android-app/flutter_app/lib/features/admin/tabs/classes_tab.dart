import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class ClassesTab extends StatefulWidget {
  const ClassesTab({super.key});

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
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
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Class name')),
        TextField(controller: _abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              if (_name.text.trim().isEmpty || _abbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addClass(
                    ClassItem(name: _name.text.trim(), abbr: _abbr.text.trim()),
                  );
              _name.clear();
              _abbr.clear();
            },
            child: const Text('Add Class'),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: planner.classes.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(planner.classes[i].name),
              subtitle: Text(planner.classes[i].abbr),
            ),
          ),
        ),
      ],
    );
  }
}
