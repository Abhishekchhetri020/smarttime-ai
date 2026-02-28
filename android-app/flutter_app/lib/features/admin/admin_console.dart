import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';

class AdminConsole extends StatefulWidget {
  const AdminConsole({super.key, required this.role});
  final String role;

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  final _db = FirebaseFirestore.instance;
  final _teacher = TextEditingController();
  final _classGrade = TextEditingController(text: 'VII');
  final _classSection = TextEditingController(text: 'A');
  final _subject = TextEditingController(text: 'Mathematics');
  String _status = '';

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('schools').doc(AppConfig.schoolId).collection(name);

  Future<void> _addTeacher() async {
    if (_teacher.text.trim().isEmpty) return;
    final id = 't_${DateTime.now().millisecondsSinceEpoch}';
    await _col('teachers').doc(id).set({'name': _teacher.text.trim(), 'code': id});
    _teacher.clear();
  }

  Future<void> _addClass() async {
    if (_classGrade.text.trim().isEmpty || _classSection.text.trim().isEmpty) return;
    final id = 'c_${DateTime.now().millisecondsSinceEpoch}';
    await _col('classes').doc(id).set({
      'grade': _classGrade.text.trim(),
      'section': _classSection.text.trim(),
    });
  }

  Future<void> _addSubject() async {
    if (_subject.text.trim().isEmpty) return;
    final id = 's_${DateTime.now().millisecondsSinceEpoch}';
    await _col('subjects').doc(id).set({'name': _subject.text.trim()});
    _subject.clear();
  }

  Future<void> _generateTimetable() async {
    setState(() => _status = 'Generating...');

    final teachers = await _col('teachers').limit(1).get();
    final classes = await _col('classes').limit(1).get();
    final subjects = await _col('subjects').limit(1).get();

    if (teachers.docs.isEmpty || classes.docs.isEmpty || subjects.docs.isEmpty) {
      setState(() => _status = 'Add at least one teacher, class, and subject first.');
      return;
    }

    final t = teachers.docs.first;
    final c = classes.docs.first;
    final s = subjects.docs.first;

    final lessons = List.generate(8, (i) {
      final cls = '${c.data()['grade']}-${c.data()['section']}';
      return {
        'id': 'L${i + 1}',
        'classId': cls,
        'teacherId': t.id,
        'subjectId': s.id,
      };
    });

    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/schools/${AppConfig.schoolId}/solver/jobs'),
      headers: {
        'content-type': 'application/json',
        'x-role': 'incharge',
        'x-school-id': AppConfig.schoolId,
        'x-uid': 'mobile-admin',
      },
      body: jsonEncode({'days': 5, 'periodsPerDay': 8, 'lessons': lessons}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      setState(() => _status = 'Solver job queued successfully.');
    } else {
      setState(() => _status = 'Solver failed: ${res.body}');
    }
  }

  Future<void> _publishLatestDraft() async {
    setState(() => _status = 'Publishing latest draft...');
    final snap = await _col('timetables').orderBy('createdAt', descending: true).limit(1).get();
    if (snap.docs.isEmpty) {
      setState(() => _status = 'No timetable version found to publish.');
      return;
    }
    final versionId = snap.docs.first.id;

    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/schools/${AppConfig.schoolId}/timetables/$versionId/publish'),
      headers: {
        'content-type': 'application/json',
        'x-role': 'incharge',
        'x-school-id': AppConfig.schoolId,
        'x-uid': 'mobile-admin',
      },
      body: jsonEncode({}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      setState(() => _status = 'Published version: $versionId');
    } else {
      setState(() => _status = 'Publish failed: ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.role} Console', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          const Text('Add Teacher'),
          TextField(controller: _teacher, decoration: const InputDecoration(hintText: 'Teacher name')),
          const SizedBox(height: 6),
          ElevatedButton(onPressed: _addTeacher, child: const Text('Save Teacher')),

          const Divider(height: 24),
          const Text('Add Class'),
          Row(children: [
            Expanded(child: TextField(controller: _classGrade, decoration: const InputDecoration(hintText: 'Grade'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _classSection, decoration: const InputDecoration(hintText: 'Section'))),
          ]),
          const SizedBox(height: 6),
          ElevatedButton(onPressed: _addClass, child: const Text('Save Class')),

          const Divider(height: 24),
          const Text('Add Subject'),
          TextField(controller: _subject, decoration: const InputDecoration(hintText: 'Subject')),
          const SizedBox(height: 6),
          ElevatedButton(onPressed: _addSubject, child: const Text('Save Subject')),

          const Divider(height: 24),
          ElevatedButton(onPressed: _generateTimetable, child: const Text('Generate Timetable')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _publishLatestDraft, child: const Text('Publish Latest Timetable')),

          const SizedBox(height: 12),
          if (_status.isNotEmpty) Text(_status, style: const TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
