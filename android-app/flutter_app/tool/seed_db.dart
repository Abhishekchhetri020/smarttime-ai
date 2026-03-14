import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

void main() async {
  print('--- SmartTime AI Database Seeder ---');

  final dbPath = 'smarttime.sqlite';
  print('Targeting DB: $dbPath');
  final dbFile = File(dbPath);
  final database = NativeDatabase(dbFile);

  final random = Random();

  final schoolName = 'Audit Academy High';
  final workingDays = 6;
  final bellTimes = [
    '08:00-08:45', '08:45-09:30', '09:45-10:30', '10:30-11:15',
    '11:30-12:15', '12:15-13:00', '13:30-14:15', '14:15-15:00'
  ];

  final subjects = [
    {'id': 'S1', 'name': 'Mathematics', 'abbr': 'MAT', 'color': 0xFF3257B8},
    {'id': 'S2', 'name': 'English', 'abbr': 'ENG', 'color': 0xFF0E8A70},
    {'id': 'S3', 'name': 'Physics', 'abbr': 'PHY', 'color': 0xFF9A4D1C},
    {'id': 'S4', 'name': 'Chemistry', 'abbr': 'CHE', 'color': 0xFFB45520},
    {'id': 'S5', 'name': 'Biology', 'abbr': 'BIO', 'color': 0xFF1A8D6B},
    {'id': 'S6', 'name': 'History', 'abbr': 'HIS', 'color': 0xFF8C3AB8},
    {'id': 'S7', 'name': 'Geography', 'abbr': 'GEO', 'color': 0xFF7A5A17},
    {'id': 'S8', 'name': 'Computer Science', 'abbr': 'CS', 'color': 0xFF1C8E49},
  ];

  final classes = List.generate(10, (i) {
    final grade = (i / 2).floor() + 6;
    final section = i % 2 == 0 ? 'A' : 'B';
    return {'id': 'C$i', 'name': 'Class $grade$section', 'abbr': '$grade$section'};
  });

  final teachers = List.generate(40, (i) {
    final firstNames = ['Amit', 'Priya', 'Raj', 'Sneh', 'Vikram', 'Anjali', 'Deepak', 'Megha'];
    final lastNames = ['Sharma', 'Verma', 'Gupta', 'Singh', 'Chhetri', 'Kapoor', 'Reddy', 'Das'];
    final fn = firstNames[random.nextInt(firstNames.length)];
    final ln = lastNames[random.nextInt(lastNames.length)];
    return {
      'id': 'T$i',
      'firstName': fn,
      'lastName': ln,
      'abbr': '${fn[0]}${ln[0]}$i',
      'maxGapsPerDay': 2,
      'maxConsecutivePeriods': 4,
      'timeOff': {},
    };
  });

  final classrooms = List.generate(20, (i) {
    return {
      'id': 'R$i',
      'name': 'Room ${100 + i}',
      'roomType': i < 5 ? 'lab' : 'standard',
    };
  });

  final lessons = <Map<String, dynamic>>[];
  for (int i = 0; i < 150; i++) {
    final sub = subjects[random.nextInt(subjects.length)];
    final cls = classes[random.nextInt(classes.length)];
    final t1 = teachers[random.nextInt(teachers.length)];
    
    final tIds = [t1['id']];
    if (random.nextDouble() < 0.1) {
      tIds.add(teachers[random.nextInt(teachers.length)]['id'] as String);
    }

    final cIds = [cls['id']];
    if (random.nextDouble() < 0.1) {
      cIds.add(classes[random.nextInt(classes.length)]['id'] as String);
    }

    lessons.add({
      'id': 'L$i',
      'subjectId': sub['id'],
      'teacherIds': tIds.toSet().toList(),
      'classIds': cIds.toSet().toList(),
      'periodsPerWeek': 2 + random.nextInt(3),
      'countPerWeek': 2 + random.nextInt(3),
      'length': random.nextDouble() < 0.15 ? 'double' : 'single',
      'requiredClassroomId': random.nextDouble() < 0.3 ? classrooms[random.nextInt(classrooms.length)]['id'] : null,
      'isPinned': false,
    });
  }

  final plannerJson = {
    'schoolName': schoolName,
    'workingDays': workingDays,
    'bellTimes': bellTimes,
    'subjects': subjects,
    'classes': classes,
    'teachers': teachers,
    'classrooms': classrooms,
    'lessons': lessons,
    'divisions': [],
    'scheduleEntries': bellTimes.asMap().entries.map((e) => {
      'id': 'P${e.key}',
      'label': 'Period ${e.key + 1}',
      'timeRange': e.value,
      'type': 0, // period
    }).toList(),
  };

  final encoded = jsonEncode(plannerJson);

  final executor = database;
  
  try {
    await executor.ensureOpen(_User());
    await executor.runCustom('PRAGMA user_version = 12;');
    
    // 1. Clear existing
    await executor.runCustom('DELETE FROM app_state;');
    await executor.runCustom('DELETE FROM lessons;');
    await executor.runCustom('DELETE FROM teachers;');
    await executor.runCustom('DELETE FROM subjects;');
    await executor.runCustom('DELETE FROM classes;');

    // 2. Insert granular tables for Solver
    for (var s in subjects) {
      await executor.runCustom('INSERT INTO subjects (id, name, abbr, color) VALUES (?, ?, ?, ?)', [s['id'], s['name'], s['abbr'], s['color']]);
    }
    for (var c in classes) {
      await executor.runCustom('INSERT INTO classes (id, name, abbr) VALUES (?, ?, ?)', [c['id'], c['name'], c['abbr']]);
    }
    for (var t in teachers) {
      await executor.runCustom('INSERT INTO teachers (id, name, abbreviation, max_gaps_per_day) VALUES (?, ?, ?, ?)', [t['id'], '${t['firstName']} ${t['lastName']}', t['abbr'], t['maxGapsPerDay']]);
    }
    for (var l in lessons) {
      await executor.runCustom('INSERT INTO lessons (id, subject_id, periods_per_week, teacher_ids, class_ids, is_pinned) VALUES (?, ?, ?, ?, ?, ?)', 
        [l['id'], l['subjectId'], l['periodsPerWeek'], jsonEncode(l['teacherIds']), jsonEncode(l['classIds']), 0]);
    }

    // 3. Insert Snapshot for PlannerState
    await executor.runCustom('INSERT OR REPLACE INTO app_state (id, planner_json, updated_at) VALUES (1, ?, ?)', [
      encoded,
      DateTime.now().millisecondsSinceEpoch,
    ]);
    
    print('Successfully seeded Tables and Snapshot (Version 12).');
  } catch (e) {
    print('Error seeding: $e');
  }
}

class _User extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 12;
}
