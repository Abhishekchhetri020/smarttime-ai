import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SubjectSetupScreen extends StatefulWidget {
  const SubjectSetupScreen({super.key});

  @override
  State<SubjectSetupScreen> createState() => _SubjectSetupScreenState();
}

class _SubjectSetupScreenState extends State<SubjectSetupScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final subjects = planner.subjects.where((s) {
      final q = _query.toLowerCase();
      return q.isEmpty || s.name.toLowerCase().contains(q) || s.abbr.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search subjects',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: subjects.isEmpty
                ? const Center(child: Text('No subjects yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = subjects[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Color(s.color)),
                          title: Text(s.name),
                          subtitle: Text(s.abbr),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSubjectSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Subject', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Subject name')),
            const SizedBox(height: 12),
            TextField(controller: abbrCtrl, decoration: const InputDecoration(labelText: 'Abbreviation')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final planner = context.read<PlannerState>();
                  await planner.addSubject(SubjectItem(name: nameCtrl.text.trim(), abbr: abbrCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : abbrCtrl.text.trim(), color: Colors.blue.value));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save Subject'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
