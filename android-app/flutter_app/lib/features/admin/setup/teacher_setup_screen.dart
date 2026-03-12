import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class TeacherSetupScreen extends StatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  State<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends State<TeacherSetupScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final teachers = planner.teachers.where((t) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          t.fullName.toLowerCase().contains(q) ||
          t.abbr.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeacherSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search teachers',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: teachers.isEmpty
                ? const Center(child: Text('No teachers yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: teachers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final t = teachers[index];
                      return Card(
                        child: ListTile(
                          title: Text(t.fullName),
                          subtitle: Text(
                            '${t.abbr} • max gaps: ${t.maxGapsPerDay ?? '-'}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTeacherSheet(BuildContext context) async {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    final gapsCtrl = TextEditingController(text: '2');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Teacher', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'First name')),
              const SizedBox(height: 12),
              TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Last name')),
              const SizedBox(height: 12),
              TextField(controller: abbrCtrl, decoration: const InputDecoration(labelText: 'Abbreviation')),
              const SizedBox(height: 12),
              TextField(controller: gapsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max gaps per day')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final planner = context.read<PlannerState>();
                    await planner.addTeacher(
                      TeacherItem(
                        firstName: firstCtrl.text.trim(),
                        lastName: lastCtrl.text.trim(),
                        abbr: abbrCtrl.text.trim().isEmpty ? firstCtrl.text.trim() : abbrCtrl.text.trim(),
                        maxGapsPerDay: int.tryParse(gapsCtrl.text.trim()),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Teacher'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
