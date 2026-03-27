import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SetupStepClassDivisions extends StatefulWidget {
  const SetupStepClassDivisions({super.key});

  @override
  State<SetupStepClassDivisions> createState() =>
      _SetupStepClassDivisionsState();
}

class _SetupStepClassDivisionsState extends State<SetupStepClassDivisions> {
  String? _classId;
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _className = TextEditingController();
  final _classAbbr = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _className.dispose();
    _classAbbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Class divisions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        if (planner.classes.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
                'No classes yet. Add at least one class to create divisions.'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _className,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Class name (e.g. Class X-A)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _classAbbr,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Class abbreviation (e.g. X-A)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              if (_className.text.trim().isEmpty ||
                  _classAbbr.text.trim().isEmpty) return;
              final c = ClassItem(
                  name: _className.text.trim(), abbr: _classAbbr.text.trim());
              context.read<PlannerState>().addClass(c);
              setState(() => _classId = c.id);
              _className.clear();
              _classAbbr.clear();
            },
            child: const Text('Add Class'),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          initialValue: _classId,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Select class'),
          items: planner.classes
              .map((c) => DropdownMenuItem(
                  value: c.id, child: Text('${c.name} (${c.abbr})')))
              .toList(),
          onChanged: (v) => setState(() => _classId = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Division name (e.g. Hindi Group)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _code,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Division code (e.g. HIN)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            if (_classId == null ||
                _name.text.trim().isEmpty ||
                _code.text.trim().isEmpty) return;
            context.read<PlannerState>().addDivision(
                  classId: _classId!,
                  name: _name.text.trim(),
                  code: _code.text.trim(),
                );
            _name.clear();
            _code.clear();
          },
          child: const Text('Add Division'),
        ),
      ],
    );
  }
}
