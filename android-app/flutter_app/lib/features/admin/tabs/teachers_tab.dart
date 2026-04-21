import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database.dart';
import '../planner_state.dart';
import '../time_off_picker.dart';

class TeachersTab extends StatefulWidget {
  const TeachersTab({super.key});

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _abbr = TextEditingController();

  bool get _isTeacherFormValid =>
      _first.text.trim().isNotEmpty && _abbr.text.trim().isNotEmpty;

  int _maxGaps = 2;
  int _maxConsecutive = 3;
  final Map<String, TimeOffState> _timeOffDraft = {};

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return ListView(
      children: [
        TextField(
          controller: _first,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'First name',
            helperText: 'Required',
          ),
        ),
        TextField(
          controller: _last,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Last name'),
        ),
        TextField(
          controller: _abbr,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Abbreviation',
            helperText: 'Required',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _maxGaps,
                decoration: const InputDecoration(labelText: 'Max gaps/day'),
                items: [
                  for (int i = 0; i <= 6; i++)
                    DropdownMenuItem(value: i, child: Text('$i'))
                ],
                onChanged: (v) => setState(() => _maxGaps = v ?? 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _maxConsecutive,
                decoration: const InputDecoration(labelText: 'Max consecutive'),
                items: [
                  for (int i = 1; i <= 8; i++)
                    DropdownMenuItem(value: i, child: Text('$i'))
                ],
                onChanged: (v) => setState(() => _maxConsecutive = v ?? 3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TimeOffPicker(
          days: planner.workingDays,
          periodsPerDay: planner.bellTimes.length,
          initial: _timeOffDraft,
          onChanged: (v) {
            _timeOffDraft
              ..clear()
              ..addAll(v);
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: _isTeacherFormValid
                ? () async {
                    try {
                      await context.read<PlannerState>().addTeacher(
                            TeacherItem(
                              firstName: _first.text.trim(),
                              lastName: _last.text.trim(),
                              abbr: _abbr.text.trim(),
                              maxGapsPerDay: _maxGaps,
                              maxConsecutivePeriods: _maxConsecutive,
                              timeOff:
                                  Map<String, TimeOffState>.from(_timeOffDraft),
                            ),
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Teacher saved successfully')),
                      );
                      _first.clear();
                      _last.clear();
                      _abbr.clear();
                      _timeOffDraft.clear();
                      setState(() {});
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('SQLite error: $e')),
                      );
                    }
                  }
                : null,
            child: const Text('Add Teacher'),
          ),
        ),
        const Divider(),
        if (planner.db != null)
          StreamBuilder<List<TeacherRow>>(
            stream: (planner.db!.select(planner.db!.teachers)
                  ..orderBy([(t) => OrderingTerm.asc(t.name)]))
                .watch(),
            builder: (context, snap) {
              final rows = snap.data ?? const <TeacherRow>[];
              if (rows.isEmpty) return const SizedBox.shrink();
              return Column(
                children: rows
                    .map(
                      (t) => ListTile(
                        title: Text(t.name),
                        subtitle: Text(
                            '${t.abbreviation} • gaps:${t.maxGapsPerDay ?? '-'}'),
                      ),
                    )
                    .toList(),
              );
            },
          )
        else
          for (final t in planner.teachers)
            ListTile(
              title: Text('${t.firstName} ${t.lastName}'.trim()),
              subtitle: Text(
                  '${t.abbr} • gaps:${t.maxGapsPerDay ?? '-'} • consec:${t.maxConsecutivePeriods ?? '-'} • off:${t.timeOff.length} slots'),
            ),
      ],
    );
  }
}
