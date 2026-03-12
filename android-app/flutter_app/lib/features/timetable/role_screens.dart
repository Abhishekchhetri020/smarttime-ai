import 'package:flutter/material.dart';
import '../admin/admin_dashboard_screen.dart';
import 'timetable_display.dart';
import 'timetable_repo.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AdminDashboardScreen(role: 'Super Admin');
}

class InchargeScreen extends StatelessWidget {
  const InchargeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AdminDashboardScreen(role: 'Timetable In-Charge');
}

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TimetableEntriesView(title: 'Teacher Timetable');
}

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TimetableEntriesView(title: 'Student Timetable');
}

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TimetableEntriesView(title: 'Parent Timetable');
}

class TimetableEntriesView extends StatelessWidget {
  final String title;
  const TimetableEntriesView({super.key, required this.title});
  static const _catalog = TimetableDisplayCatalog();

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
          grid['$d-$p'] = [
            _catalog.subjectLabel(e['subjectId']?.toString() ?? ''),
            _catalog.classLabel(e['classId']?.toString() ?? ''),
          ].where((value) => value.isNotEmpty).join('\n');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 14, height: 14, color: Colors.orange.shade50),
                const SizedBox(width: 6),
                const Text('Empty slot', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 80),
                for (int d = 1; d <= maxDay; d++)
                  Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade200,
                    child: Text('Day $d',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        for (int p = 1; p <= maxPeriod; p++)
                          Container(
                            width: 80,
                            height: 64,
                            alignment: Alignment.center,
                            color: Colors.grey.shade100,
                            child: Text('P$p',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [
                          for (int p = 1; p <= maxPeriod; p++)
                            Row(
                              children: [
                                for (int d = 1; d <= maxDay; d++)
                                  _Cell(
                                    grid['$d-$p'] ?? '-',
                                    header: false,
                                    empty: (grid['$d-$p'] == null),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool header;
  final bool empty;
  const _Cell(this.text, {required this.header, this.empty = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 64,
      decoration: BoxDecoration(
        color: header
            ? Colors.grey.shade200
            : empty
                ? Colors.orange.shade50
                : null,
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: header ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }
}
