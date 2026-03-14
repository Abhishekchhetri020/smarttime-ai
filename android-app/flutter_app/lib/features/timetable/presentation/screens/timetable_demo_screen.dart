import 'package:flutter/material.dart';

import '../widgets/universal_timetable_grid.dart';

class TimetableDemoScreen extends StatefulWidget {
  const TimetableDemoScreen({super.key});

  @override
  State<TimetableDemoScreen> createState() => _TimetableDemoScreenState();
}

class _TimetableDemoScreenState extends State<TimetableDemoScreen> {
  ViewMode _mode = ViewMode.teacher;

  static const _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const _periods = <PeriodSlot>[
    PeriodSlot(id: 'p1', label: 'P1'),
    PeriodSlot(id: 'p2', label: 'P2'),
    PeriodSlot(id: 'p3', label: 'P3'),
    PeriodSlot(id: 'br1', label: 'Break', isBreak: true),
    PeriodSlot(id: 'p4', label: 'P4'),
    PeriodSlot(id: 'p5', label: 'P5'),
    PeriodSlot(id: 'p6', label: 'P6'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Cockpit Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text('View: ', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                SegmentedButton<ViewMode>(
                  segments: const [
                    ButtonSegment(value: ViewMode.teacher, label: Text('Teacher')),
                    ButtonSegment(value: ViewMode.classView, label: Text('Class')),
                    ButtonSegment(value: ViewMode.room, label: Text('Room')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (v) => setState(() => _mode = v.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: UniversalTimetableGrid(
                viewMode: _mode,
                rowLabels: _days,
                periods: _periods,
                cells: _mockCellsFor(_mode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, TimetableCellData> _mockCellsFor(ViewMode mode) {
    switch (mode) {
      case ViewMode.teacher:
        return {
          UniversalTimetableGrid.keyFor(0, 0): const TimetableCellData(
            id: 't_m00',
            primary: 'Math',
            secondary: 'X A + X B', // joint class demo
            tertiary: 'Math Lab',
            accent: Color(0xFF3257B8),
          ),
          UniversalTimetableGrid.keyFor(0, 1): const TimetableCellData(
            id: 't_m01',
            primary: 'English',
            secondary: 'IX C',
            tertiary: 'R-204',
            accent: Color(0xFF0E8A70),
          ),
          UniversalTimetableGrid.keyFor(2, 4): const TimetableCellData(
            id: 't_m24',
            primary: 'Physics',
            secondary: 'XI A',
            tertiary: 'Sci Lab',
            accent: Color(0xFF9A4D1C),
          ),
          UniversalTimetableGrid.keyFor(4, 6): const TimetableCellData(
            id: 't_m46',
            primary: 'SST',
            secondary: 'VIII B',
            tertiary: 'R-108',
            accent: Color(0xFF8C3AB8),
          ),
        };
      case ViewMode.classView:
        return {
          UniversalTimetableGrid.keyFor(0, 0): const TimetableCellData(
            id: 'c_m00',
            primary: 'Math',
            secondary: 'Mr. B. Prakash', // longer teacher label demo
            tertiary: 'Math Lab',
            accent: Color(0xFF3257B8),
          ),
          UniversalTimetableGrid.keyFor(0, 2): const TimetableCellData(
            id: 'c_m02',
            primary: 'Hindi',
            secondary: 'Ms. Sumitra',
            tertiary: 'R-204',
            accent: Color(0xFF7A5A17),
          ),
          UniversalTimetableGrid.keyFor(1, 4): const TimetableCellData(
            id: 'c_m14',
            primary: 'Chemistry',
            secondary: 'Mr. Gaurav',
            tertiary: 'Chem Lab',
            accent: Color(0xFFB45520),
          ),
          UniversalTimetableGrid.keyFor(5, 6): const TimetableCellData(
            id: 'c_m56',
            primary: 'Sports',
            secondary: 'Coach Aman',
            tertiary: 'Ground',
            accent: Color(0xFF1C8E49),
          ),
        };
      case ViewMode.room:
        return {
          UniversalTimetableGrid.keyFor(0, 0): const TimetableCellData(
            id: 'r_m00',
            primary: 'Math',
            secondary: 'X A / Mr. Prakash',
            tertiary: 'Occupancy: Full',
            accent: Color(0xFF3257B8),
          ),
          UniversalTimetableGrid.keyFor(2, 1): const TimetableCellData(
            id: 'r_m21',
            primary: 'Bio',
            secondary: 'IX B / Ms. Saloni',
            tertiary: 'Occupancy: 34',
            accent: Color(0xFF1A8D6B),
          ),
          UniversalTimetableGrid.keyFor(3, 5): const TimetableCellData(
            id: 'r_m35',
            primary: 'Music',
            secondary: 'III A / Mr. Santu',
            tertiary: 'Occupancy: 22',
            accent: Color(0xFF7B3DAF),
          ),
        };
    }
  }
}
