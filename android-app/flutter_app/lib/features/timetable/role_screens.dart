import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => const Text('Teacher Timetable View');
}

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});
  @override
  Widget build(BuildContext context) => const Text('Student Timetable View');
}

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});
  @override
  Widget build(BuildContext context) => const Text('Parent Timetable View');
}
