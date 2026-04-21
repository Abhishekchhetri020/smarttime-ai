import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class ClassroomsTab extends StatefulWidget {
  const ClassroomsTab({super.key});

  @override
  State<ClassroomsTab> createState() => _ClassroomsTabState();
}

class _ClassroomsTabState extends State<ClassroomsTab> {
  final _name = TextEditingController();
  final _type = TextEditingController(text: 'standard');

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Column(
      children: [
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Room name / ID')),
        TextField(
            controller: _type,
            decoration: const InputDecoration(labelText: 'Room type')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              context.read<PlannerState>().addClassroom(
                    ClassroomItem(
                        name: _name.text.trim(),
                        roomType: _type.text.trim().isEmpty
                            ? 'standard'
                            : _type.text.trim()),
                  );
              _name.clear();
            },
            child: const Text('Add Classroom'),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: planner.classrooms.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(planner.classrooms[i].name),
              subtitle: Text(planner.classrooms[i].roomType),
            ),
          ),
        ),
      ],
    );
  }
}
