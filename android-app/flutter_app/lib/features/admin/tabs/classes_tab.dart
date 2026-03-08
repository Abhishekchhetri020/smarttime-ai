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
  String? _selectedClassId;
  final _divisionName = TextEditingController();
  final _divisionCode = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _abbr.dispose();
    _divisionName.dispose();
    _divisionCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return ListView(
      children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Class name')),
        TextField(controller: _abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              if (_name.text.trim().isEmpty || _abbr.text.trim().isEmpty) return;
              final c = ClassItem(name: _name.text.trim(), abbr: _abbr.text.trim());
              context.read<PlannerState>().addClass(c);
              setState(() => _selectedClassId = c.id);
              _name.clear();
              _abbr.clear();
            },
            child: const Text('Add Class'),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Division Creator', style: Theme.of(context).textTheme.titleSmall),
        ),
        DropdownButtonFormField<String>(
          initialValue: _selectedClassId,
          decoration: const InputDecoration(labelText: 'Target class'),
          items: planner.classes
              .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.abbr})')))
              .toList(),
          onChanged: (v) => setState(() => _selectedClassId = v),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _divisionName,
                decoration: const InputDecoration(labelText: 'Division name (Boys/Girls/Hindi)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _divisionCode,
                decoration: const InputDecoration(labelText: 'Code (B/G/HIN)'),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              if (_selectedClassId == null || _divisionName.text.trim().isEmpty || _divisionCode.text.trim().isEmpty) {
                return;
              }
              context.read<PlannerState>().addDivision(
                    classId: _selectedClassId!,
                    name: _divisionName.text.trim(),
                    code: _divisionCode.text.trim(),
                  );
              _divisionName.clear();
              _divisionCode.clear();
            },
            child: const Text('Add Division'),
          ),
        ),
        const Divider(),
        for (final c in planner.classes)
          ListTile(
            title: Text(c.name),
            subtitle: Text('${c.abbr} • divisions: ${c.divisions.map((d) => d.code).join(', ')}'),
          ),
      ],
    );
  }
}
