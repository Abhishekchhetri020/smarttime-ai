import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SetupStepSchool extends StatefulWidget {
  const SetupStepSchool({super.key});

  @override
  State<SetupStepSchool> createState() => _SetupStepSchoolState();
}

class _SetupStepSchoolState extends State<SetupStepSchool> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<PlannerState>().schoolName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('School setup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'School name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => context.read<PlannerState>().setSchoolName(value),
        ),
      ],
    );
  }
}
