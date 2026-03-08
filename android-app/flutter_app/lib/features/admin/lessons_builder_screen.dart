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
  final Set<String> _teacherIds = {};
  final Set<String> _classIds = {};
  String? _classDivisionId;
  String? _classroomId;
  int _countPerWeek = 1;
  String _length = 'single';
  bool _isPinned = false;
  int? _fixedDay;
  int? _fixedPeriod;
  int _relationshipType = 0;
  final _relationshipKey = TextEditingController();

  @override
  void dispose() {
    _relationshipKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final selectedClass = planner.classes.firstWhere(
      (c) => c.id == (_classIds.isNotEmpty ? _classIds.first : null),
      orElse: () => planner.classes.isNotEmpty ? planner.classes.first : ClassItem(name: '-', abbr: '-'),
    );

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
            const Text('Teachers (co-teaching supported)'),
            Wrap(
              spacing: 6,
              children: planner.teachers
                  .map((t) => FilterChip(
                        label: Text(t.abbreviation),
                        selected: _teacherIds.contains(t.id),
                        onSelected: (v) => setState(() => v ? _teacherIds.add(t.id) : _teacherIds.remove(t.id)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text('Classes (joint lessons supported)'),
            Wrap(
              spacing: 6,
              children: planner.classes
                  .map((c) => FilterChip(
                        label: Text(c.abbreviation),
                        selected: _classIds.contains(c.id),
                        onSelected: (v) => setState(() => v ? _classIds.add(c.id) : _classIds.remove(c.id)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classDivisionId,
              hint: const Text('Optional division'),
              items: selectedClass.divisions
                  .map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.code})')))
                  .toList(),
              onChanged: (v) => setState(() => _classDivisionId = v),
              decoration: const InputDecoration(labelText: 'Class division target (optional)'),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _relationshipType,
              decoration: const InputDecoration(labelText: 'Relationship type'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('SIMULTANEOUS')),
                DropdownMenuItem(value: 1, child: Text('FOLLOWING')),
                DropdownMenuItem(value: 2, child: Text('SAME_DAY')),
              ],
              onChanged: (v) => setState(() => _relationshipType = v ?? 0),
            ),
            TextField(
              controller: _relationshipKey,
              decoration: const InputDecoration(labelText: 'relationshipGroupKey (optional)'),
            ),
            SwitchListTile(
              title: const Text('Pin to fixed slot'),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
            ),
            if (_isPinned)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _fixedDay,
                      items: [for (int d = 1; d <= planner.workingDays; d++) DropdownMenuItem(value: d, child: Text('Day $d'))],
                      onChanged: (v) => setState(() => _fixedDay = v),
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _fixedPeriod,
                      items: [for (int p = 1; p <= planner.bellTimes.length; p++) DropdownMenuItem(value: p, child: Text('Period $p'))],
                      onChanged: (v) => setState(() => _fixedPeriod = v),
                      decoration: const InputDecoration(labelText: 'Period'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_subjectId == null || _teacherIds.isEmpty || _classIds.isEmpty) return;
                planner.addLesson(
                  subjectId: _subjectId!,
                  teacherIds: _teacherIds.toList(),
                  classIds: _classIds.toList(),
                  classDivisionId: _classDivisionId,
                  countPerWeek: _countPerWeek,
                  length: _length,
                  requiredClassroomId: _classroomId,
                  isPinned: _isPinned,
                  fixedDay: _fixedDay,
                  fixedPeriod: _fixedPeriod,
                  relationshipType: _relationshipType,
                  relationshipGroupKey: _relationshipKey.text.trim().isEmpty ? null : _relationshipKey.text.trim(),
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
