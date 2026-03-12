import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final rooms = planner.classrooms.where((r) {
      final q = _query.toLowerCase();
      return q.isEmpty || r.name.toLowerCase().contains(q) || r.roomType.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search rooms',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: rooms.isEmpty
                ? const Center(child: Text('No rooms yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = rooms[index];
                      return Card(
                        child: ListTile(
                          title: Text(r.name),
                          subtitle: Text(r.roomType),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRoomSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'standard');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Room', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Room name')),
            const SizedBox(height: 12),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Room type')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final planner = context.read<PlannerState>();
                  planner.addClassroom(ClassroomItem(name: nameCtrl.text.trim(), roomType: typeCtrl.text.trim().isEmpty ? 'standard' : typeCtrl.text.trim()));
                  Navigator.pop(context);
                },
                child: const Text('Save Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
