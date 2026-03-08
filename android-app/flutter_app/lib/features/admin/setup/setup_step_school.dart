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
    final planner = context.watch<PlannerState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('School details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        TextField(
          key: const Key('school_name_field'),
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'School name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => context.read<PlannerState>().setSchoolName(value),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: const Key('days_count_dropdown'),
          initialValue: planner.workingDays,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Days per week',
          ),
          items: [for (int d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text('$d'))],
          onChanged: (v) {
            if (v != null) context.read<PlannerState>().setWorkingDays(v);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: const Key('periods_dropdown'),
          initialValue: planner.bellTimes.length,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Periods per day',
          ),
          items: [for (int p = 4; p <= 12; p++) DropdownMenuItem(value: p, child: Text('$p'))],
          onChanged: (v) {
            if (v == null) return;
            final current = List<String>.from(planner.bellTimes);
            if (v > current.length) {
              for (int i = current.length + 1; i <= v; i++) {
                current.add('P$i');
              }
            } else {
              current.removeRange(v, current.length);
            }
            context.read<PlannerState>().setBellTimes(current);
          },
        ),
      ],
    );
  }
}
