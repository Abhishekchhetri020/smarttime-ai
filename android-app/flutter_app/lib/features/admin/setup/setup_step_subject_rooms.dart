import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SetupStepSubjectRooms extends StatefulWidget {
  const SetupStepSubjectRooms({super.key});

  @override
  State<SetupStepSubjectRooms> createState() => _SetupStepSubjectRoomsState();
}

class _SetupStepSubjectRoomsState extends State<SetupStepSubjectRooms> {
  String? _subjectId;
  int? _roomType;
  final _group = TextEditingController();
  bool _groupToggle = false;

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject & room requirements',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _subjectId,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Subject'),
          items: planner.subjects
              .map((s) => DropdownMenuItem(
                  value: s.id, child: Text('${s.name} (${s.abbr})')))
              .toList(),
          onChanged: (v) => setState(() => _subjectId = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _roomType,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Required room type'),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Standard Classroom')),
            DropdownMenuItem(value: 1, child: Text('Lab')),
            DropdownMenuItem(value: 2, child: Text('Hall')),
          ],
          onChanged: (v) => setState(() => _roomType = v),
        ),
        SwitchListTile(
          title: const Text('Group / Elective'),
          value: _groupToggle,
          onChanged: (v) => setState(() => _groupToggle = v),
        ),
        if (_groupToggle)
          TextField(
            controller: _group,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'relationshipGroupKey'),
          ),
      ],
    );
  }
}
