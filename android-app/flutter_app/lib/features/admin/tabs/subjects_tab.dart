import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database.dart';
import '../planner_state.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  final _name = TextEditingController();
  final _abbr = TextEditingController();
  final _groupKey = TextEditingController();

  bool _isElectiveGroup = false;
  bool _isPinned = false;
  int? _fixedDay;
  int? _fixedPeriod;
  final Set<String> _jointClassIds = {};

  @override
  void dispose() {
    _name.dispose();
    _abbr.dispose();
    _groupKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return ListView(
      children: [
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Subject name')),
        TextField(
            controller: _abbr,
            decoration: const InputDecoration(labelText: 'Abbreviation')),
        const SizedBox(height: 6),
        SwitchListTile(
          title: const Text('Group / Elective'),
          subtitle: const Text(
              'Enable for simultaneous subject groups (Hindi/Urdu/Sanskrit)'),
          value: _isElectiveGroup,
          onChanged: (v) => setState(() => _isElectiveGroup = v),
        ),
        if (_isElectiveGroup)
          TextField(
            controller: _groupKey,
            decoration: const InputDecoration(
                labelText: 'relationshipGroupKey (e.g. LANG_GRP_10A)'),
          ),
        const SizedBox(height: 6),
        SwitchListTile(
          title: const Text('Lock to Slot'),
          value: _isPinned,
          onChanged: (v) => setState(() => _isPinned = v),
        ),
        if (_isPinned)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _fixedDay,
                  decoration: const InputDecoration(labelText: 'Fixed day'),
                  items: [
                    for (int d = 1; d <= planner.workingDays; d++)
                      DropdownMenuItem(value: d, child: Text('Day $d'))
                  ],
                  onChanged: (v) => setState(() => _fixedDay = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _fixedPeriod,
                  decoration: const InputDecoration(labelText: 'Fixed period'),
                  items: [
                    for (int p = 1; p <= planner.bellTimes.length; p++)
                      DropdownMenuItem(value: p, child: Text('Period $p'))
                  ],
                  onChanged: (v) => setState(() => _fixedPeriod = v),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Joint Class Selector',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        Wrap(
          spacing: 6,
          children: planner.classes
              .map((c) => FilterChip(
                    label: Text(c.abbr),
                    selected: _jointClassIds.contains(c.id),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _jointClassIds.add(c.id);
                        } else {
                          _jointClassIds.remove(c.id);
                        }
                      });
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () async {
              if (_name.text.trim().isEmpty || _abbr.text.trim().isEmpty)
                return;
              final sid = _abbr.text.trim();
              try {
                await context.read<PlannerState>().addSubject(
                      SubjectItem(
                        id: sid,
                        name: _name.text.trim(),
                        abbr: _abbr.text.trim(),
                        color: 0xFF0B3D91,
                        relationshipGroupKey:
                            _isElectiveGroup ? _groupKey.text.trim() : null,
                      ),
                    );

                // create an optional pinned/joint seed lesson template if user selected classes
                if (_jointClassIds.isNotEmpty) {
                  final plannerRead = context.read<PlannerState>();
                  final defaultTeacher = plannerRead.teachers.isNotEmpty
                      ? plannerRead.teachers.first.id
                      : null;
                  if (defaultTeacher != null) {
                    plannerRead.addLesson(
                      subjectId: sid,
                      teacherIds: [defaultTeacher],
                      classIds: _jointClassIds.toList(),
                      countPerWeek: 1,
                      length: 'single',
                      isPinned: _isPinned,
                      fixedDay: _fixedDay,
                      fixedPeriod: _fixedPeriod,
                      relationshipType: 0,
                      relationshipGroupKey:
                          _isElectiveGroup ? _groupKey.text.trim() : null,
                    );
                  }
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject saved successfully')),
                );

                _name.clear();
                _abbr.clear();
                _groupKey.clear();
                setState(() {
                  _isElectiveGroup = false;
                  _isPinned = false;
                  _fixedDay = null;
                  _fixedPeriod = null;
                  _jointClassIds.clear();
                });
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('SQLite error: $e')),
                );
              }
            },
            child: const Text('Add Subject'),
          ),
        ),
        const Divider(),
        if (planner.db != null)
          StreamBuilder<List<SubjectRow>>(
            stream: (planner.db!.select(planner.db!.subjects)
                  ..orderBy([(t) => OrderingTerm.asc(t.name)]))
                .watch(),
            builder: (context, snap) {
              final rows = snap.data ?? const <SubjectRow>[];
              if (rows.isEmpty) return const SizedBox.shrink();
              return Column(
                children: rows
                    .map(
                      (s) => ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                            '${s.abbr}${(s.groupId ?? '').isNotEmpty ? ' • group:${s.groupId}' : ''}'),
                      ),
                    )
                    .toList(),
              );
            },
          )
        else
          for (final s in planner.subjects)
            ListTile(
              title: Text(s.name),
              subtitle: Text(
                  '${s.abbr}${s.relationshipGroupKey != null && s.relationshipGroupKey!.isNotEmpty ? ' • group:${s.relationshipGroupKey}' : ''}'),
            ),
      ],
    );
  }
}
