import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SetupStepBellTimes extends StatefulWidget {
  const SetupStepBellTimes({super.key});

  @override
  State<SetupStepBellTimes> createState() => _SetupStepBellTimesState();
}

class _SetupStepBellTimesState extends State<SetupStepBellTimes> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
        const Text('Bell times',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in planner.bellTimes)
              Chip(
                label: Text(slot),
                onDeleted: planner.bellTimes.length <= 1
                    ? null
                    : () {
                        final next = List<String>.from(planner.bellTimes)
                          ..remove(slot);
                        context.read<PlannerState>().setBellTimes(next);
                      },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 09:00-09:45',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final value = _controller.text.trim();
                if (value.isEmpty) return;
                final next = List<String>.from(planner.bellTimes)..add(value);
                context.read<PlannerState>().setBellTimes(next);
                _controller.clear();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
