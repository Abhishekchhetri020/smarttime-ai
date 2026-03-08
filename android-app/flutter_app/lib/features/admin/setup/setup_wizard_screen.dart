import 'package:flutter/material.dart';

import 'setup_step_class_divisions.dart';
import 'setup_step_school.dart';
import 'setup_step_subject_rooms.dart';
import 'setup_step_teacher_availability.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _index,
      onStepTapped: (i) => setState(() => _index = i),
      onStepContinue: () {
        if (_index < 3) {
          setState(() => _index++);
        } else {
          // Last step — close wizard and return to the dashboard.
          Navigator.of(context).pop();
        }
      },
      onStepCancel: () {
        if (_index > 0) setState(() => _index--);
      },
      controlsBuilder: (context, details) {
        return Row(
          children: [
            ElevatedButton(
              key: const Key('wizard_continue_btn'),
              onPressed: details.onStepContinue,
              child: Text(_index == 3 ? 'Done' : 'Next'),
            ),
            const SizedBox(width: 8),
            if (_index > 0)
              TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
          ],
        );
      },
      steps: const [
        Step(
          title: Text('School Details'),
          content: SetupStepSchool(),
          isActive: true,
        ),
        Step(
          title: Text('Class Divisions'),
          content: SetupStepClassDivisions(),
          isActive: true,
        ),
        Step(
          title: Text('Subject & Room Requirements'),
          content: SetupStepSubjectRooms(),
          isActive: true,
        ),
        Step(
          title: Text('Teacher Availability'),
          content: SetupStepTeacherAvailability(),
          isActive: true,
        ),
      ],
    );
  }
}
