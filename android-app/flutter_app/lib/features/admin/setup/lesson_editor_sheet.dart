import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

Future<void> showLessonEditorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const LessonEditorSheet(),
  );
}

class LessonEditorSheet extends StatefulWidget {
  const LessonEditorSheet({super.key});

  @override
  State<LessonEditorSheet> createState() => _LessonEditorSheetState();
}

class _LessonEditorSheetState extends State<LessonEditorSheet> {
  ClassItem? selectedClass;
  SubjectItem? selectedSubject;
  TeacherItem? selectedTeacher;
  ClassroomItem? selectedRoom;
  int weeklyPeriods = 5;
  String length = 'single';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Lesson', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _PickerField(
              label: 'Class',
              value: selectedClass?.name,
              onTap: () async {
                final result = await _showSearchPicker<ClassItem>(
                  context,
                  title: 'Select Class',
                  items: planner.classes,
                  label: (item) => item.name,
                );
                if (result != null) setState(() => selectedClass = result);
              },
            ),
            const SizedBox(height: 12),
            _PickerField(
              label: 'Subject',
              value: selectedSubject?.name,
              onTap: () async {
                final result = await _showSearchPicker<SubjectItem>(
                  context,
                  title: 'Select Subject',
                  items: planner.subjects,
                  label: (item) => item.name,
                );
                if (result != null) setState(() => selectedSubject = result);
              },
            ),
            const SizedBox(height: 12),
            _PickerField(
              label: 'Teacher',
              value: selectedTeacher?.fullName,
              onTap: () async {
                final result = await _showSearchPicker<TeacherItem>(
                  context,
                  title: 'Select Teacher',
                  items: planner.teachers,
                  label: (item) => item.fullName,
                );
                if (result != null) setState(() => selectedTeacher = result);
              },
            ),
            const SizedBox(height: 12),
            _PickerField(
              label: 'Preferred Room',
              value: selectedRoom?.name,
              onTap: () async {
                final result = await _showSearchPicker<ClassroomItem>(
                  context,
                  title: 'Select Room',
                  items: planner.classrooms,
                  label: (item) => item.name,
                );
                if (result != null) setState(() => selectedRoom = result);
              },
            ),
            const SizedBox(height: 20),
            Text('Weekly Periods', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(onPressed: weeklyPeriods > 1 ? () => setState(() => weeklyPeriods--) : null, icon: const Icon(Icons.remove_circle_outline)),
                Text('$weeklyPeriods', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(onPressed: weeklyPeriods < 12 ? () => setState(() => weeklyPeriods++) : null, icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Lesson Length', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'single', label: Text('Single')),
                ButtonSegment(value: 'double', label: Text('Double')),
              ],
              selected: {length},
              onSelectionChanged: (value) => setState(() => length = value.first),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedClass == null || selectedSubject == null || selectedTeacher == null
                    ? null
                    : () {
                        context.read<PlannerState>().addLesson(
                              classId: selectedClass!.id,
                              subjectId: selectedSubject!.id,
                              teacherId: selectedTeacher!.id,
                              countPerWeek: weeklyPeriods,
                              length: length,
                              requiredClassroomId: selectedRoom?.id,
                            );
                        Navigator.pop(context);
                      },
                child: const Text('Save Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.expand_more)),
        child: Text(value ?? 'Select $label'),
      ),
    );
  }
}

Future<T?> _showSearchPicker<T>(BuildContext context, {required String title, required List<T> items, required String Function(T) label}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      String query = '';
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = items.where((item) => label(item).toLowerCase().contains(query.toLowerCase())).toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            builder: (context, controller) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SearchBar(
                    hintText: 'Search',
                    leading: const Icon(Icons.search),
                    onChanged: (value) => setModalState(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(label(item)),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
