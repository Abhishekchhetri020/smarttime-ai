import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';
import 'lesson_editor_sheet.dart';

class LessonSetupScreen extends StatefulWidget {
  const LessonSetupScreen({super.key});

  @override
  State<LessonSetupScreen> createState() => _LessonSetupScreenState();
}

class _LessonSetupScreenState extends State<LessonSetupScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final lessons = planner.lessons.where((lesson) {
      final subjectMatch = planner.subjects.where((s) => s.id == lesson.subjectId);
      final subject = subjectMatch.isEmpty ? lesson.subjectId : subjectMatch.first.name;
      final q = _query.toLowerCase();
      return q.isEmpty || subject.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLessonEditorSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search lessons',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: lessons.isEmpty
                ? const Center(child: Text('No lessons yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final subjectMatch = planner.subjects.where((s) => s.id == lesson.subjectId);
                      final subject = subjectMatch.isEmpty ? lesson.subjectId : subjectMatch.first.name;
                      final clazz = planner.classes.where((c) => lesson.classIds.contains(c.id)).map((e) => e.name).join(', ');
                      final teacher = planner.teachers.where((t) => lesson.teacherIds.contains(t.id)).map((e) => e.fullName).join(', ');
                      return Card(
                        child: ListTile(
                          title: Text(subject),
                          subtitle: Text('$clazz • $teacher • ${lesson.countPerWeek}/week • ${lesson.length}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
