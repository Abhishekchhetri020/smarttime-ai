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
        return ListView(
          shrinkWrap: true,
          children: items
              .map((e) => ListTile(
                    title: Text('Day ${e['day'] ?? '-'} Period ${e['period'] ?? '-'}'),
                    subtitle: Text('${e['subjectId'] ?? ''} ${e['classId'] ?? ''}'),
                  ))
              .toList(),
        );
      },
    );
  }
}
