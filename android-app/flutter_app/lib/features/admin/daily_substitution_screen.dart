import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/database.dart';
import 'planner_state.dart';

class DailySubstitutionScreen extends StatefulWidget {
  const DailySubstitutionScreen({super.key});

  @override
  State<DailySubstitutionScreen> createState() => _DailySubstitutionScreenState();
}

class _DailySubstitutionScreenState extends State<DailySubstitutionScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<DailyAbsenceRow> _absences = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final planner = context.read<PlannerState>();
    final db = planner.db;
    if (db == null) return;

    setState(() => _loading = true);
    // Simple filter in memory for cross-platform DateTime stability in Drift
    final allAbsences = await db.select(db.dailyAbsences).get();
    final results = allAbsences.where((a) =>
        a.date.year == _selectedDate.year &&
        a.date.month == _selectedDate.month &&
        a.date.day == _selectedDate.day).toList();

    setState(() {
      _absences = results;
      _loading = false;
    });
  }

  Future<void> _addAbsence() async {
    final planner = context.read<PlannerState>();
    final db = planner.db;
    if (db == null) return;

    String? selectedTeacherId;
    final teachers = planner.teachers;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Teacher Absence'),
        content: DropdownButtonFormField<String>(
          items: teachers
              .map((t) => DropdownMenuItem(
                  value: t.id, child: Text('${t.firstName} ${t.lastName}')))
              .toList(),
          onChanged: (val) => selectedTeacherId = val,
          decoration: const InputDecoration(labelText: 'Select Teacher'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedTeacherId != null) {
                await db.into(db.dailyAbsences).insert(DailyAbsencesCompanion.insert(
                      entityId: selectedTeacherId!,
                      entityType: 'teacher',
                      date: _selectedDate,
                    ));
                if (context.mounted) Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Substitutions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _refreshData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.event_note, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Substitutions for ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_absences.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No absences recorded for this day.'),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _absences.length,
                itemBuilder: (context, index) {
                  final absence = _absences[index];
                  final teacher = context
                      .read<PlannerState>()
                      .teachers
                      .firstWhere((t) => t.id == absence.entityId,
                          orElse: () => TeacherItem(id: '?', firstName: 'Unknown', lastName: 'Teacher', abbr: '?'));
                  final teacherName = '${teacher.firstName} ${teacher.lastName}';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(teacherName),
                      subtitle: Text(absence.reason ?? 'No reason provided'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final db = context.read<PlannerState>().db;
                          if (db != null) {
                            await (db.delete(db.dailyAbsences)..where((t) => t.id.equals(absence.id))).go();
                            _refreshData();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAbsence,
        label: const Text('Add Absence'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
