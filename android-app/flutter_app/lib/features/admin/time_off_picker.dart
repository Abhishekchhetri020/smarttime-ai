import 'package:flutter/material.dart';

enum TimeOffState { available, unavailable, conditional }

class TimeOffPicker extends StatefulWidget {
  const TimeOffPicker({
    super.key,
    required this.days,
    required this.periodsPerDay,
    required this.initial,
    required this.onChanged,
  });

  final int days;
  final int periodsPerDay;
  final Map<String, TimeOffState> initial; // key: day-period (1-based)
  final ValueChanged<Map<String, TimeOffState>> onChanged;

  @override
  State<TimeOffPicker> createState() => _TimeOffPickerState();
}

class _TimeOffPickerState extends State<TimeOffPicker> {
  late Map<String, TimeOffState> _grid;

  @override
  void initState() {
    super.initState();
    _grid = Map<String, TimeOffState>.from(widget.initial);
    for (var d = 1; d <= widget.days; d++) {
      for (var p = 1; p <= widget.periodsPerDay; p++) {
        _grid.putIfAbsent('$d-$p', () => TimeOffState.available);
      }
    }
  }

  void _cycle(int day, int period) {
    final key = '$day-$period';
    final cur = _grid[key] ?? TimeOffState.available;
    final next = switch (cur) {
      TimeOffState.available => TimeOffState.unavailable,
      TimeOffState.unavailable => TimeOffState.conditional,
      TimeOffState.conditional => TimeOffState.available,
    };
    setState(() => _grid[key] = next);
    widget.onChanged(_grid);
  }

  Color _bg(TimeOffState s) => switch (s) {
        TimeOffState.available => const Color(0xFF16A34A),
        TimeOffState.unavailable => const Color(0xFFDC2626),
        TimeOffState.conditional => const Color(0xFF4F46E5),
      };

  IconData _icon(TimeOffState s) => switch (s) {
        TimeOffState.available => Icons.check,
        TimeOffState.unavailable => Icons.close,
        TimeOffState.conditional => Icons.question_mark,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 12,
          children: [
            _Legend(
                label: 'Available',
                color: Color(0xFF16A34A),
                icon: Icons.check),
            _Legend(
                label: 'Unavailable',
                color: Color(0xFFDC2626),
                icon: Icons.close),
            _Legend(
                label: 'Conditional',
                color: Color(0xFF4F46E5),
                icon: Icons.question_mark),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('P\\D')),
              for (int d = 1; d <= widget.days; d++)
                DataColumn(label: Text('D$d')),
            ],
            rows: [
              for (int p = 1; p <= widget.periodsPerDay; p++)
                DataRow(cells: [
                  DataCell(Text('P$p')),
                  for (int d = 1; d <= widget.days; d++)
                    DataCell(
                      GestureDetector(
                        onTap: () => _cycle(d, p),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _bg(_grid['$d-$p']!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(_icon(_grid['$d-$p']!),
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Legend({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 18,
        height: 18,
        color: color,
        child: Icon(icon, size: 12, color: Colors.white),
      ),
      const SizedBox(width: 4),
      Text(label),
    ]);
  }
}
