import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';
import '../time_off_picker.dart';

class SetupStepTeacherAvailability extends StatefulWidget {
  const SetupStepTeacherAvailability({super.key});

  @override
  State<SetupStepTeacherAvailability> createState() =>
      _SetupStepTeacherAvailabilityState();
}

class _SetupStepTeacherAvailabilityState
    extends State<SetupStepTeacherAvailability> {
  String? _teacherId;
  Map<String, TimeOffState> _draft = {};

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Teacher availability',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _teacherId,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Teacher'),
          items: planner.teachers
              .map((t) => DropdownMenuItem(
                  value: t.id, child: Text('${t.fullName} (${t.abbr})')))
              .toList(),
          onChanged: (v) {
            setState(() {
              _teacherId = v;
              final t = planner.teachers
                  .where((e) => e.id == v)
                  .cast<TeacherItem?>()
                  .firstWhere(
                    (x) => x != null,
                    orElse: () => null,
                  );
              _draft = Map<String, TimeOffState>.from(t?.timeOff ?? {});
            });
          },
        ),
        const SizedBox(height: 8),
        TimeOffPicker(
          days: planner.workingDays,
          periodsPerDay: planner.bellTimes.length,
          initial: _draft,
          onChanged: (v) => _draft = Map<String, TimeOffState>.from(v),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _teacherId == null
              ? null
              : () {
                  planner.updateTeacherConstraints(
                    _teacherId!,
                    timeOff: _draft,
                  );
                },
          child: const Text('Save Teacher Availability'),
        ),
      ],
    );
  }
}
