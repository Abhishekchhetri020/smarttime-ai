import 'package:flutter/material.dart';

import 'setup_step_bell_times.dart';
import 'setup_step_days.dart';
import 'setup_step_school.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _index = 0;

  static const _steps = [
    SetupStepSchool(),
    SetupStepDays(),
    SetupStepBellTimes(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stepper(
          currentStep: _index,
          onStepTapped: (i) => setState(() => _index = i),
          onStepContinue: () {
            if (_index < _steps.length - 1) setState(() => _index++);
          },
          onStepCancel: () {
            if (_index > 0) setState(() => _index--);
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_index == _steps.length - 1 ? 'Done' : 'Next')),
                const SizedBox(width: 8),
                if (_index > 0)
                  TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
              ],
            );
          },
          steps: const [
            Step(title: Text('School'), content: SetupStepSchool(), isActive: true),
            Step(title: Text('Days'), content: SetupStepDays(), isActive: true),
            Step(title: Text('Bell Times'), content: SetupStepBellTimes(), isActive: true),
          ],
        ),
      ],
    );
  }
}
