import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SetupStepDays extends StatelessWidget {
  const SetupStepDays({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Working days',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: planner.workingDays,
          items: List.generate(
            7,
            (i) =>
                DropdownMenuItem(value: i + 1, child: Text('${i + 1} day(s)')),
          ),
          onChanged: (v) {
            if (v != null) context.read<PlannerState>().setWorkingDays(v);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Days per week',
          ),
        ),
      ],
    );
  }
}
