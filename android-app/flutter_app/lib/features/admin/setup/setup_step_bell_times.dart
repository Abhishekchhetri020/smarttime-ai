import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';
import '../schedule_entry.dart';

class SetupStepBellTimes extends StatefulWidget {
  const SetupStepBellTimes({super.key});

  @override
  State<SetupStepBellTimes> createState() => _SetupStepBellTimesState();
}

class _SetupStepBellTimesState extends State<SetupStepBellTimes> {
  Future<void> _addEntry(BuildContext context) async {
    final planner = context.read<PlannerState>();
    final created = await showDialog<ScheduleEntry>(
      context: context,
      builder: (_) => const _ScheduleEntryDialog(),
    );
    if (created == null) return;
    final next = List<ScheduleEntry>.from(planner.scheduleEntries)..add(created);
    planner.setScheduleEntries(next);
  }

  Future<void> _editEntry(
    BuildContext context,
    int index,
    ScheduleEntry existing,
  ) async {
    final planner = context.read<PlannerState>();
    final updated = await showDialog<ScheduleEntry>(
      context: context,
      builder: (_) => _ScheduleEntryDialog(initial: existing),
    );
    if (updated == null) return;
    final next = List<ScheduleEntry>.from(planner.scheduleEntries);
    next[index] = updated;
    planner.setScheduleEntries(next);
  }

  void _deleteEntry(BuildContext context, int index) {
    final planner = context.read<PlannerState>();
    final next = List<ScheduleEntry>.from(planner.scheduleEntries)
      ..removeAt(index);
    if (next.where((e) => e.type == ScheduleEntryType.period).isEmpty) return;
    planner.setScheduleEntries(next);
  }

  void _moveEntry(BuildContext context, int oldIndex, int newIndex) {
    final planner = context.read<PlannerState>();
    final next = List<ScheduleEntry>.from(planner.scheduleEntries);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    planner.setScheduleEntries(next);
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final entries = planner.scheduleEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bell schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text(
          'Define ordered periods and breaks. Period entries drive periods/day.',
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          onReorder: (oldIndex, newIndex) =>
              _moveEntry(context, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final item = entries[index];
            final canDelete =
                !(item.type == ScheduleEntryType.period &&
                    entries.where((e) => e.type == ScheduleEntryType.period).length <=
                        1);
            return Card(
              key: ValueKey('schedule-entry-$index-${item.label}-${item.timeRange}'),
              child: ListTile(
                title: Text(item.label),
                subtitle: Text('${item.type.label} • ${item.timeRange}'),
                leading: Icon(item.type == ScheduleEntryType.period
                    ? Icons.class_
                    : Icons.free_breakfast),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editEntry(context, index, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: canDelete
                          ? () => _deleteEntry(context, index)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _addEntry(context),
          icon: const Icon(Icons.add),
          label: const Text('Add period/break'),
        ),
      ],
    );
  }
}

class _ScheduleEntryDialog extends StatefulWidget {
  const _ScheduleEntryDialog({this.initial});

  final ScheduleEntry? initial;

  @override
  State<_ScheduleEntryDialog> createState() => _ScheduleEntryDialogState();
}

class _ScheduleEntryDialogState extends State<_ScheduleEntryDialog> {
  late final TextEditingController _labelController;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late ScheduleEntryType _type;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _start = initial?.start ?? const TimeOfDay(hour: 8, minute: 0);
    _end = initial?.end ?? const TimeOfDay(hour: 8, minute: 45);
    _type = initial?.type ?? ScheduleEntryType.period;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _start = selected;
      } else {
        _end = selected;
      }
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _submit() {
    final label = _labelController.text.trim();
    final startMins = _start.hour * 60 + _start.minute;
    final endMins = _end.hour * 60 + _end.minute;
    if (label.isEmpty || endMins <= startMins) return;
    Navigator.of(context).pop(
      ScheduleEntry(label: label, start: _start, end: _end, type: _type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add entry' : 'Edit entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ScheduleEntryType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(
                value: ScheduleEntryType.period,
                child: Text('Period'),
              ),
              DropdownMenuItem(
                value: ScheduleEntryType.breakTime,
                child: Text('Break'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(start: true),
                  child: Text('Start ${_fmt(_start)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(start: false),
                  child: Text('End ${_fmt(_end)}'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
