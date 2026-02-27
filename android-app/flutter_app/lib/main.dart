import 'package:flutter/material.dart';

void main() {
  runApp(const SmartTimeApp());
}

class SmartTimeApp extends StatelessWidget {
  const SmartTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTime AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D91)),
        useMaterial3: true,
      ),
      home: const TeacherTimetableScreen(),
    );
  }
}

class TeacherTimetableScreen extends StatelessWidget {
  const TeacherTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demoRows = const [
      'Mon P1 - VIII A - English',
      'Mon P3 - VIII B - English',
      'Tue P2 - VII A - English',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Timetable')),
      body: ListView.builder(
        itemCount: demoRows.length,
        itemBuilder: (context, i) => ListTile(title: Text(demoRows[i])),
      ),
    );
  }
}
