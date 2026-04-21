import 'package:flutter/material.dart';

class TimeOffMatrix extends StatelessWidget {
  const TimeOffMatrix({
    super.key,
    required this.days,
    required this.periodsPerDay,
    required this.unavailableSlots,
    required this.onChanged,
  });

  final List<String> days;
  final int periodsPerDay;
  final Set<String> unavailableSlots;
  final ValueChanged<Set<String>> onChanged;

  String _key(int dayIndex, int periodIndex) => '$dayIndex-$periodIndex';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tap slots to mark unavailable'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Day')),
              for (int p = 1; p <= periodsPerDay; p++)
                DataColumn(label: Text('P$p')),
            ],
            rows: [
              for (int d = 0; d < days.length; d++)
                DataRow(
                  cells: [
                    DataCell(Text(days[d])),
                    for (int p = 1; p <= periodsPerDay; p++)
                      DataCell(
                        GestureDetector(
                          onTap: () {
                            final next = Set<String>.from(unavailableSlots);
                            final slot = _key(d, p - 1);
                            if (next.contains(slot)) {
                              next.remove(slot);
                            } else {
                              next.add(slot);
                            }
                            onChanged(next);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: unavailableSlots.contains(_key(d, p - 1))
                                  ? colorScheme.errorContainer
                                  : colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              unavailableSlots.contains(_key(d, p - 1))
                                  ? Icons.block
                                  : Icons.check,
                              size: 18,
                              color: unavailableSlots.contains(_key(d, p - 1))
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('Green = available, Red = unavailable',
            style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
