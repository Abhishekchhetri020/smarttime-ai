import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class ClassSetupScreen extends StatefulWidget {
  const ClassSetupScreen({super.key});

  @override
  State<ClassSetupScreen> createState() => _ClassSetupScreenState();
}

class _ClassSetupScreenState extends State<ClassSetupScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final classes = planner.classes.where((c) {
      final q = _query.toLowerCase();
      return q.isEmpty || c.name.toLowerCase().contains(q) || c.abbr.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search classes',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: classes.isEmpty
                ? const Center(child: Text('No classes yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = classes[index];
                      return Card(
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.abbr),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddClassSheet(BuildContext context) async {
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
            Text('Add Class', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Class name')),
            const SizedBox(height: 12),
            TextField(controller: abbrCtrl, decoration: const InputDecoration(labelText: 'Abbreviation')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final planner = context.read<PlannerState>();
                  await planner.addClass(ClassItem(name: nameCtrl.text.trim(), abbr: abbrCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : abbrCtrl.text.trim()));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save Class'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
