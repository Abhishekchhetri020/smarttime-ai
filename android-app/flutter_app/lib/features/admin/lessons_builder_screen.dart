import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'planner_state.dart';

class LessonsBuilderScreen extends StatefulWidget {
  const LessonsBuilderScreen({super.key});

  @override
  State<LessonsBuilderScreen> createState() => _LessonsBuilderScreenState();
}

class _LessonsBuilderScreenState extends State<LessonsBuilderScreen> {
  String? _subjectId;
  String? _teacherId;
  String? _classId;
  String? _classroomId;
  int _countPerWeek = 1;
  String _length = 'single';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons Builder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _subjectId,
              hint: const Text('Select subject'),
              items: planner.subjects
                  .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.abbreviation})')))
                  .toList(),
              onChanged: (v) => setState(() => _subjectId = v),
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _teacherId,
              hint: const Text('Select teacher'),
              items: planner.teachers
                  .map((t) => DropdownMenuItem(value: t.id, child: Text('${t.fullName} (${t.abbreviation})')))
                  .toList(),
              onChanged: (v) => setState(() => _teacherId = v),
              decoration: const InputDecoration(labelText: 'Teacher'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classId,
              hint: const Text('Select class'),
              items: planner.classes
                  .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.abbreviation})')))
                  .toList(),
              onChanged: (v) => setState(() => _classId = v),
              decoration: const InputDecoration(labelText: 'Class'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _countPerWeek,
              items: [for (int i = 1; i <= 10; i++) DropdownMenuItem(value: i, child: Text('$i'))],
              onChanged: (v) => setState(() => _countPerWeek = v ?? 1),
              decoration: const InputDecoration(labelText: 'Count / week'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _length,
              items: const [
                DropdownMenuItem(value: 'single', child: Text('Single period')),
                DropdownMenuItem(value: 'double', child: Text('Double period')),
              ],
              onChanged: (v) => setState(() => _length = v ?? 'single'),
              decoration: const InputDecoration(labelText: 'Length'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classroomId,
              hint: const Text('None (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...planner.classrooms.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name} (${r.type})'))),
              ],
              onChanged: (v) => setState(() => _classroomId = v),
              decoration: const InputDecoration(labelText: 'Required classroom (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_subjectId == null || _teacherId == null || _classId == null) return;
                planner.addLesson(
                  subjectId: _subjectId!,
                  teacherId: _teacherId!,
                  classId: _classId!,
                  countPerWeek: _countPerWeek,
                  length: _length,
                  requiredClassroomId: _classroomId,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Add Lesson'),
            ),
          ],
        ),
      ),
    );
  }
}
