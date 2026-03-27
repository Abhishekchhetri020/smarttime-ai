import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

// ── Data model ─────────────────────────────────────────────────────────────

enum _SlotType { period, breakSlot }

class _ScheduleSlot {
  _SlotType type;
  String name;
  TimeOfDay start;
  TimeOfDay end;

  _ScheduleSlot({
    required this.type,
    required this.name,
    required this.start,
    required this.end,
  });

  /// Parse from "PeriodName|HH:mm-HH:mm" or legacy "HH:mm-HH:mm"
  static _ScheduleSlot fromString(String s, int periodIndex) {
    final parts = s.split('|');
    String name;
    String timeRange;
    _SlotType type = _SlotType.period;

    if (parts.length >= 2) {
      name = parts[0];
      timeRange = parts[1];
      if (parts.length >= 3 && parts[2] == 'break') {
        type = _SlotType.breakSlot;
      }
    } else {
      name = 'Period ${periodIndex + 1}';
      timeRange = s;
    }
    final tp = _parseTimeRange(timeRange);
    return _ScheduleSlot(type: type, name: name, start: tp.$1, end: tp.$2);
  }

  static (TimeOfDay, TimeOfDay) _parseTimeRange(String range) {
    try {
      final halves = range.split('-');
      final s = halves[0].split(':');
      final e = halves[1].split(':');
      return (
        TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1])),
        TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1])),
      );
    } catch (_) {
      return (
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 8, minute: 45),
      );
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Encode as "Name|HH:mm-HH:mm" or "Name|HH:mm-HH:mm|break"
  String encode() {
    final range = '${_fmt(start)}-${_fmt(end)}';
    if (type == _SlotType.breakSlot) return '$name|$range|break';
    return '$name|$range';
  }
}

// ── Days ───────────────────────────────────────────────────────────────────

const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Maps a set of selected day indices into workingDays count (Mon-based)
/// We keep it simple: the number of selected days IS the workingDays value.
Set<int> _defaultDaysForCount(int count) {
  // Default: Mon(1)…count
  if (count <= 0) return {};
  return List.generate(count, (i) => i + 1 > 6 ? i + 1 - 7 : i + 1)
      .toSet()
      .take(count)
      .toSet();
}

// ── Screen ─────────────────────────────────────────────────────────────────

class BellScheduleScreen extends StatefulWidget {
  const BellScheduleScreen({super.key});

  @override
  State<BellScheduleScreen> createState() => _BellScheduleScreenState();
}

class _BellScheduleScreenState extends State<BellScheduleScreen> {
  final List<_ScheduleSlot> _slots = [];
  Set<int> _selectedDays = {};
  bool _uniformSchedule = true; // always uniform for now
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final planner = context.read<PlannerState>();
    _selectedDays = _defaultDaysForCount(planner.workingDays);

    if (planner.bellTimes.isNotEmpty) {
      int pIdx = 0;
      for (final raw in planner.bellTimes) {
        final slot = _ScheduleSlot.fromString(raw, pIdx);
        if (slot.type == _SlotType.period) pIdx++;
        _slots.add(slot);
      }
    } else {
      _slots.add(_ScheduleSlot(
        type: _SlotType.period,
        name: 'Period 1',
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 9, minute: 45),
      ));
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _addPeriod() {
    setState(() {
      final lastPeriod = _slots.lastWhere(
        (s) => s.type == _SlotType.period,
        orElse: () => _ScheduleSlot(
          type: _SlotType.period,
          name: '',
          start: const TimeOfDay(hour: 8, minute: 0),
          end: const TimeOfDay(hour: 8, minute: 45),
        ),
      );
      final totalMins = lastPeriod.end.hour * 60 + lastPeriod.end.minute + 45;
      final periodNum =
          _slots.where((s) => s.type == _SlotType.period).length + 1;
      _slots.add(_ScheduleSlot(
        type: _SlotType.period,
        name: 'Period $periodNum',
        start: lastPeriod.end,
        end: TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60),
      ));
      _saved = false;
    });
  }

  void _addBreakAfter(int slotIndex) {
    setState(() {
      final prev = _slots[slotIndex];
      final totalMins = prev.end.hour * 60 + prev.end.minute + 15;
      _slots.insert(
        slotIndex + 1,
        _ScheduleSlot(
          type: _SlotType.breakSlot,
          name: 'Break',
          start: prev.end,
          end: TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60),
        ),
      );
      _saved = false;
    });
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final current = isStart ? _slots[index].start : _slots[index].end;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => child!,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _slots[index].start = picked;
        } else {
          _slots[index].end = picked;
        }
        _saved = false;
      });
    }
  }

  void _save() {
    final planner = context.read<PlannerState>();
    planner.setWorkingDays(_selectedDays.length.clamp(1, 7));
    // Encode ALL slots (periods + breaks) into bellTimes
    planner.setBellTimes(_slots.map((s) => s.encode()).toList());
    setState(() => _saved = true);
  }

  void _onNext() {
    _save();
    Navigator.of(context).pop();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodCount = _slots.where((s) => s.type == _SlotType.period).length;
    final dayCount = _selectedDays.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.watch<PlannerState>().sessionName.isNotEmpty
              ? context.watch<PlannerState>().sessionName
              : 'Bell Schedule',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Period Style card ──────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Default Schedule',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Configure periods and breaks for your timetable',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const Divider(height: 24),
                        const Text('Period Configuration Style',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _RadioOption(
                          value: true,
                          groupValue: _uniformSchedule,
                          label: 'Uniform Schedule',
                          subtitle:
                              'Same periods every working day. Simple and straightforward.',
                          onChanged: (v) =>
                              setState(() => _uniformSchedule = v),
                        ),
                        const SizedBox(height: 8),
                        _RadioOption(
                          value: false,
                          groupValue: _uniformSchedule,
                          label: 'Custom Day Schedule',
                          subtitle:
                              'Different periods for different days. E.g., shorter Fridays.',
                          onChanged: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Custom Day Schedule coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Working Days ───────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Working Days',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Row(
                              children: [
                                _DayQuickBtn(
                                    label: 'Weekdays',
                                    onTap: () => setState(() {
                                          _selectedDays = {1, 2, 3, 4, 5};
                                          _saved = false;
                                        })),
                                const SizedBox(width: 8),
                                _DayQuickBtn(
                                    label: 'Clear',
                                    onTap: () => setState(() {
                                          _selectedDays = {};
                                          _saved = false;
                                        })),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Day chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final selected = _selectedDays.contains(i);
                            return _DayChip(
                              label: _dayLabels[i],
                              selected: selected,
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedDays.remove(i);
                                } else {
                                  _selectedDays.add(i);
                                }
                                _saved = false;
                              }),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$dayCount day${dayCount != 1 ? 's' : ''} selected',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Periods & Breaks header ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Periods & Breaks',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      FilledButton.icon(
                        onPressed: _addPeriod,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Period',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Slot cards + break buttons ─────────────────────────
                  ..._buildSlotList(context),

                  const SizedBox(height: 8),

                  // ── Summary line ───────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 6),
                      Text(
                        '$dayCount working day${dayCount != 1 ? 's' : ''} • '
                        '$periodCount period${periodCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom nav bar ─────────────────────────────────────────────
          _BottomNavBar(
            saved: _saved,
            onBack: () => Navigator.of(context).pop(),
            onNext: _onNext,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlotList(BuildContext context) {
    final widgets = <Widget>[];
    int periodDisplayIndex = 0;

    for (int i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      final isPeriod = slot.type == _SlotType.period;
      if (isPeriod) periodDisplayIndex++;

      widgets.add(_SlotCard(
        slot: slot,
        displayIndex: isPeriod ? periodDisplayIndex : null,
        canDelete: _slots.length > 1,
        onNameChanged: (v) => setState(() {
          slot.name = v;
          _saved = false;
        }),
        onPickStart: () => _pickTime(i, true),
        onPickEnd: () => _pickTime(i, false),
        onDelete: () => setState(() {
          _slots.removeAt(i);
          _saved = false;
        }),
        context: context,
      ));

      // Only show "+ Add break" after a period (not after a break)
      if (isPeriod) {
        widgets.add(_AddBreakButton(
          onTap: () => _addBreakAfter(i),
          periodLabel: slot.name,
        ));
      }
    }

    return widgets;
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE0E9)),
      ),
      child: child,
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });
  final bool value;
  final bool groupValue;
  final String label;
  final String subtitle;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFDDE0E9),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: value,
              groupValue: groupValue,
              onChanged: (_) => onChanged(value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? primary : const Color(0xFFDDE0E9),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayQuickBtn extends StatelessWidget {
  const _DayQuickBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.displayIndex,
    required this.canDelete,
    required this.onNameChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onDelete,
    required this.context,
  });

  final _ScheduleSlot slot;
  final int? displayIndex; // null for break slots
  final bool canDelete;
  final void Function(String) onNameChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onDelete;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final isPeriod = slot.type == _SlotType.period;
    final accentColor =
        isPeriod ? Theme.of(ctx).colorScheme.primary : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE0E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: slot.name,
                        onChanged: onNameChanged,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDelete,
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Time row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                // Start time
                Expanded(
                  child: _TimeButton(
                    label: 'Start',
                    time: slot.start.format(ctx),
                    onTap: onPickStart,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                // End time
                Expanded(
                  child: _TimeButton(
                    label: 'End',
                    time: slot.end.format(ctx),
                    onTap: onPickEnd,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
    required this.accentColor,
  });
  final String label;
  final String time;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(10),
          color: accentColor.withOpacity(0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: accentColor),
                const SizedBox(width: 4),
                Text(time,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: accentColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBreakButton extends StatelessWidget {
  const _AddBreakButton({required this.onTap, required this.periodLabel});
  final VoidCallback onTap;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 14),
          label: Text(
            '+ Add break after $periodLabel',
            style: const TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.4)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav bar ─────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.saved,
    required this.onBack,
    required this.onNext,
  });
  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF0F6), width: 1.5)),
      ),
      child: Row(
        children: [
          // Back
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFDDE0E9)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          // Status
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    saved ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: saved ? const Color(0xFF4CAF50) : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    saved ? 'Saved' : 'Unsaved',
                    style: TextStyle(
                      fontSize: 13,
                      color: saved ? const Color(0xFF4CAF50) : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Next
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
