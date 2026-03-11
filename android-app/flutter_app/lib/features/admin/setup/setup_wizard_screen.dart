import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/services/bulk_import_service.dart';
import '../planner_state.dart';
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
    final planner = context.read<PlannerState>();
    final importer = BulkImportService();

    return Column(
      children: [
        Expanded(
          child: Stepper(
            currentStep: _index,
            onStepTapped: (i) => setState(() => _index = i),
            onStepContinue: () {
              if (_index < 3) {
                setState(() => _index++);
              } else {
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
                    TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back')),
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
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final files = await importer.writeMasterCsvTemplates();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Templates saved: ${files.map((e) => e.path).join(' | ')}')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Template'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final db = planner.db;
                if (db == null) return;
                try {
                  final lessonsFile = await importer.pickLessonsMasterCsv();
                  if (lessonsFile == null || !context.mounted) return;
                  final pickConstraints = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Optional Constraints'),
                      content: const Text(
                          'Lessons loaded. Select Teachers_Constraints.csv or Skip?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Skip')),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Select File')),
                      ],
                    ),
                  );
                  final teachersFile = (pickConstraints ?? false)
                      ? await importer.pickTeachersConstraintsCsv()
                      : null;
                  final summary = await importer.importMasterCsvData(
                    db,
                    lessonsFile: lessonsFile,
                    teachersFile: teachersFile,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Imported ${summary.lessons} Lessons, ${summary.teachers} Teachers, and ${summary.rooms} Rooms successfully.'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Master CSVs'),
            ),
          ],
        ),
      ],
    );
  }
}
