import 'package:flutter/material.dart';
import 'timetable_repo.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});
  @override
  Widget build(BuildContext context) => const Text('Super Admin Console');
}

class InchargeScreen extends StatelessWidget {
  const InchargeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Text('Timetable In-Charge Console');
}

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});
  @override
  Widget build(BuildContext context) => const TimetableEntriesView(title: 'Teacher Timetable');
}

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});
  @override
  Widget build(BuildContext context) => const TimetableEntriesView(title: 'Student Timetable');
}

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});
  @override
  Widget build(BuildContext context) => const TimetableEntriesView(title: 'Parent Timetable');
}

class TimetableEntriesView extends StatelessWidget {
  final String title;
  const TimetableEntriesView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final repo = TimetableRepo();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getPublishedEntries('demo-school', 'latest'),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snap.hasError) {
          return Text('$title (data unavailable)');
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return Text('$title (no entries)');

        int maxDay = 1;
        int maxPeriod = 1;
        final grid = <String, String>{};

        for (final e in items) {
          final d = (e['day'] as num?)?.toInt() ?? 1;
          final p = (e['period'] as num?)?.toInt() ?? 1;
          if (d > maxDay) maxDay = d;
          if (p > maxPeriod) maxPeriod = p;
          grid['$d-$p'] = '${e['subjectId'] ?? ''}\n${e['classId'] ?? ''}'.trim();
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                defaultColumnWidth: const FixedColumnWidth(120),
                children: [
                  TableRow(
                    children: [
                      const _Cell('P/D', header: true),
                      for (int d = 1; d <= maxDay; d++) _Cell('Day $d', header: true),
                    ],
                  ),
                  for (int p = 1; p <= maxPeriod; p++)
                    TableRow(
                      children: [
                        _Cell('P$p', header: true),
                        for (int d = 1; d <= maxDay; d++)
                          _Cell(grid['$d-$p'] ?? '-', header: false),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool header;
  const _Cell(this.text, {required this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: header ? Colors.grey.shade200 : null,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: header ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }
}
