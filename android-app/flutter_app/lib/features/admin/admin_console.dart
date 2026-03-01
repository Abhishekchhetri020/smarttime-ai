import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../timetable/offline_solver_channel.dart';
import '../timetable/offline_solver_diagnostics_view.dart';
import '../timetable/offline_solver_state.dart';

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
  final _roomName = TextEditingController(text: 'Room-101');
  final _roomType = TextEditingController(text: 'regular');
  final _maxPerDay = TextEditingController(text: '7');

  String _status = '';
  bool _busy = false;
  final _offlineSolver = OfflineSolverChannel();
  OfflineSolverViewState _offlineState = const OfflineSolverViewState.idle();

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('schools').doc(AppConfig.schoolId).collection(name);

  Future<void> _withBusy(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addTeacher() async {
    await _withBusy(() async {
      if (_teacher.text.trim().isEmpty) return;
      final id = 't_${DateTime.now().millisecondsSinceEpoch}';
      await _col('teachers')
          .doc(id)
          .set({'name': _teacher.text.trim(), 'code': id});
      _teacher.clear();
      setState(() => _status = 'Teacher saved');
    });
  }

  Future<void> _addClass() async {
    await _withBusy(() async {
      if (_classGrade.text.trim().isEmpty || _classSection.text.trim().isEmpty)
        return;
      final id = 'c_${DateTime.now().millisecondsSinceEpoch}';
      await _col('classes').doc(id).set({
        'grade': _classGrade.text.trim(),
        'section': _classSection.text.trim(),
      });
      setState(() => _status = 'Class saved');
    });
  }

  Future<void> _addSubject() async {
    await _withBusy(() async {
      if (_subject.text.trim().isEmpty) return;
      final id = 's_${DateTime.now().millisecondsSinceEpoch}';
      await _col('subjects').doc(id).set({'name': _subject.text.trim()});
      _subject.clear();
      setState(() => _status = 'Subject saved');
    });
  }

  Future<void> _addRoom() async {
    await _withBusy(() async {
      if (_roomName.text.trim().isEmpty) return;
      final id = 'r_${DateTime.now().millisecondsSinceEpoch}';
      await _col('rooms').doc(id).set({
        'name': _roomName.text.trim(),
        'type':
            _roomType.text.trim().isEmpty ? 'regular' : _roomType.text.trim(),
      });
      setState(() => _status = 'Room saved');
    });
  }

  Future<void> _saveDefaultsConstraint() async {
    await _withBusy(() async {
      final maxPd = int.tryParse(_maxPerDay.text.trim()) ?? 7;
      await _col('constraints').doc('defaults').set({
        'teacherMaxPeriodsPerDay': {'DEFAULT': maxPd},
        'classMaxPeriodsPerDay': {'DEFAULT': maxPd},
        'subjectDailyLimit': {'DEFAULT': 2},
        'teacherMaxConsecutivePeriods': {'DEFAULT': 3},
        'classMaxConsecutivePeriods': {'DEFAULT': 4},
        'teacherNoLastPeriodMaxPerWeek': {'DEFAULT': 2},
      }, SetOptions(merge: true));
      setState(() => _status = 'Default constraints saved');
    });
  }

  Future<Map<String, dynamic>> _buildSolverPayload() async {
    final teachers = await _col('teachers').limit(5).get();
    final classes = await _col('classes').limit(5).get();
    final subjects = await _col('subjects').limit(8).get();
    final rooms = await _col('rooms').limit(10).get();
    final cdoc = await _col('constraints').doc('defaults').get();

    if (teachers.docs.isEmpty ||
        classes.docs.isEmpty ||
        subjects.docs.isEmpty) {
      throw Exception('Add at least one teacher, class, and subject first.');
    }

    final t = teachers.docs.first;
    final roomList = rooms.docs
        .map((r) => {
              'id': r.id,
              'roomType': (r.data()['type'] ?? 'regular').toString(),
            })
        .toList();

    final lessons = <Map<String, dynamic>>[];
    int id = 1;
    for (final c in classes.docs) {
      final cls = '${c.data()['grade']}-${c.data()['section']}';
      for (final s in subjects.docs.take(3)) {
        lessons.add({
          'id': 'L${id++}',
          'classId': cls,
          'teacherId': t.id,
          'subjectId': s.id,
          'preferredRoomId': roomList.isNotEmpty ? roomList.first['id'] : null,
        });
      }
    }

    final constraints = cdoc.exists ? (cdoc.data() ?? {}) : <String, dynamic>{};

    return {
      'days': 5,
      'periodsPerDay': 8,
      'seed': 13,
      'rooms': roomList,
      'lessons': lessons,
      'constraints': constraints,
    };
  }

  Future<void> _checkBackend() async {
    await _withBusy(() async {
      setState(() => _status = 'Checking backend...');
      final res = await http.get(Uri.parse('${AppConfig.apiBase}/health'));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _status = 'Backend reachable ✅ (${AppConfig.apiBase})');
      } else {
        setState(() =>
            _status = 'Backend check failed (${res.statusCode}): ${res.body}');
      }
    });
  }

  Future<void> _generateTimetable() async {
    await _withBusy(() async {
      setState(() => _status = 'Generating...');

      Map<String, dynamic> payload;
      try {
        payload = await _buildSolverPayload();
      } catch (e) {
        setState(() => _status = e.toString());
        return;
      }

      final res = await http.post(
        Uri.parse(
            '${AppConfig.apiBase}/schools/${AppConfig.schoolId}/solver/jobs'),
        headers: {
          'content-type': 'application/json',
          'x-role': 'incharge',
          'x-school-id': AppConfig.schoolId,
          'x-uid': 'mobile-admin',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        setState(() => _status = 'Solver job queued: ${data['jobId'] ?? 'ok'}');
      } else if (res.statusCode == 404) {
        setState(() => _status =
            'Backend endpoint not found (404). Check AppConfig.apiBase and backend deployment.');
      } else {
        setState(
            () => _status = 'Solver failed (${res.statusCode}): ${res.body}');
      }
    });
  }

  Future<void> _runOfflineSolver() async {
    await _withBusy(() async {
      setState(() {
        _status = 'Running offline solver...';
        _offlineState =
            _offlineState.copyWith(isLoading: true, clearMessage: true);
      });

      try {
        final payload = await _buildSolverPayload();
        final result = await _offlineSolver.solve(payload);
        setState(() {
          _offlineState = _offlineState.copyWith(
              isLoading: false,
              result: result,
              message: 'Offline solve complete');
          _status = 'Offline solver complete (${result.status})';
        });
      } catch (e) {
        setState(() {
          _offlineState = _offlineState.copyWith(
              isLoading: false, clearResult: true, message: e.toString());
          _status = 'Offline solver failed';
        });
      }
    });
  }

  Future<void> _publishLatestDraft() async {
    await _withBusy(() async {
      setState(() => _status = 'Publishing latest draft...');
      final snap = await _col('timetables')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        setState(() => _status = 'No timetable version found to publish.');
        return;
      }
      final versionId = snap.docs.first.id;

      final res = await http.post(
        Uri.parse(
            '${AppConfig.apiBase}/schools/${AppConfig.schoolId}/timetables/$versionId/publish'),
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
        setState(
            () => _status = 'Publish failed (${res.statusCode}): ${res.body}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.role} Console',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Add Teacher'),
          TextField(
              controller: _teacher,
              decoration: const InputDecoration(hintText: 'Teacher name')),
          const SizedBox(height: 6),
          ElevatedButton(
              onPressed: _busy ? null : _addTeacher,
              child: const Text('Save Teacher')),
          const Divider(height: 24),
          const Text('Add Class'),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _classGrade,
                    decoration: const InputDecoration(hintText: 'Grade'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _classSection,
                    decoration: const InputDecoration(hintText: 'Section'))),
          ]),
          const SizedBox(height: 6),
          ElevatedButton(
              onPressed: _busy ? null : _addClass,
              child: const Text('Save Class')),
          const Divider(height: 24),
          const Text('Add Subject'),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(hintText: 'Subject')),
          const SizedBox(height: 6),
          ElevatedButton(
              onPressed: _busy ? null : _addSubject,
              child: const Text('Save Subject')),
          const Divider(height: 24),
          const Text('Add Room'),
          TextField(
              controller: _roomName,
              decoration: const InputDecoration(hintText: 'Room name')),
          const SizedBox(height: 6),
          TextField(
              controller: _roomType,
              decoration:
                  const InputDecoration(hintText: 'Room type (regular/lab)')),
          const SizedBox(height: 6),
          ElevatedButton(
              onPressed: _busy ? null : _addRoom,
              child: const Text('Save Room')),
          const Divider(height: 24),
          const Text('Default Constraint: Max periods/day'),
          TextField(
              controller: _maxPerDay,
              decoration: const InputDecoration(hintText: 'e.g. 7')),
          const SizedBox(height: 6),
          ElevatedButton(
              onPressed: _busy ? null : _saveDefaultsConstraint,
              child: const Text('Save Constraints')),
          const Divider(height: 24),
          OutlinedButton(
              onPressed: _busy ? null : _checkBackend,
              child: const Text('Check Backend')),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _busy ? null : _generateTimetable,
              child: const Text('Generate Timetable')),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: _busy ? null : _runOfflineSolver,
              child: const Text('Run Offline Solver')),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: _busy ? null : _publishLatestDraft,
              child: const Text('Publish Latest Timetable')),
          const SizedBox(height: 12),
          if (_status.isNotEmpty)
            Text(_status, style: const TextStyle(color: Colors.blueGrey)),
          if (_offlineState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          if ((_offlineState.message ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_offlineState.message!,
                  style: const TextStyle(color: Colors.blueGrey)),
            ),
          if (_offlineState.result != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child:
                  OfflineSolverDiagnosticsView(result: _offlineState.result!),
            ),
        ],
      ),
    );
  }
}
