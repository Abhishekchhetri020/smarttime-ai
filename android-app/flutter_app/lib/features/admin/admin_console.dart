import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generate_screen.dart';
import 'lessons_builder_screen.dart';
import 'planner_state.dart';
import 'time_off_matrix.dart';

class AdminConsole extends StatelessWidget {
  const AdminConsole({super.key, required this.role, this.plannerState});
  final String role;
  final PlannerState? plannerState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => plannerState ?? PlannerState(),
      child: Consumer<PlannerState>(
        builder: (context, planner, _) {
          if (!planner.setupComplete) {
            return SetupWizard(role: role);
          }
          return const MainPlannerScreen();
        },
      ),
    );
  }
}

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key, required this.role});
  final String role;

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  int _currentStep = 0;
  final _schoolName = TextEditingController();
  final _schoolYear = TextEditingController(text: '2026-2027');

  @override
  void dispose() {
    _schoolName.dispose();
    _schoolYear.dispose();
    super.dispose();
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(context: context, initialTime: initial);
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.role} Setup Wizard')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            planner.saveSchoolSettings(name: _schoolName.text.trim(), year: _schoolYear.text.trim());
            planner.completeSetup();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              ElevatedButton(
                key: const Key('wizard_continue_btn'),
                onPressed: details.onStepContinue,
                child: Text(_currentStep == 2 ? 'Finish Setup' : 'Continue'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('School Settings'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(
                  key: const Key('school_name_field'),
                  controller: _schoolName,
                  decoration: const InputDecoration(labelText: 'School name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('school_year_field'),
                  controller: _schoolYear,
                  decoration: const InputDecoration(labelText: 'School year'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Days Configuration'),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  key: const Key('days_count_dropdown'),
                  initialValue: planner.days.length,
                  items: [for (int i = 5; i <= 10; i++) DropdownMenuItem(value: i, child: Text('$i days'))],
                  onChanged: (v) {
                    if (v != null) planner.setDaysCount(v);
                  },
                  decoration: const InputDecoration(labelText: 'Number of days'),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < planner.days.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: planner.days[i].name,
                            decoration: InputDecoration(labelText: 'Day ${i + 1} name'),
                            onChanged: (v) => planner.updateDay(
                              i,
                              name: v,
                              abbreviation: planner.days[i].abbreviation,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            initialValue: planner.days[i].abbreviation,
                            decoration: const InputDecoration(labelText: 'Abbr.'),
                            onChanged: (v) => planner.updateDay(
                              i,
                              name: planner.days[i].name,
                              abbreviation: v,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Bell Times & Breaks'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  key: const Key('periods_dropdown'),
                  initialValue: planner.periodsPerDay,
                  items: [for (int i = 4; i <= 12; i++) DropdownMenuItem(value: i, child: Text('$i periods'))],
                  onChanged: (v) {
                    if (v != null) planner.setPeriodsPerDay(v);
                  },
                  decoration: const InputDecoration(labelText: 'Periods per day'),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < planner.bellSlots.length; i++)
                  Card(
                    child: ListTile(
                      title: Text('Period ${i + 1}'),
                      subtitle: Text('${planner.bellSlots[i].start.format(context)} - ${planner.bellSlots[i].end.format(context)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final picked = await _pickTime(context, planner.bellSlots[i].start);
                              if (picked != null) planner.updateBellSlot(i, start: picked);
                            },
                            child: const Text('Start'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await _pickTime(context, planner.bellSlots[i].end);
                              if (picked != null) planner.updateBellSlot(i, end: picked);
                            },
                            child: const Text('End'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: planner.addBreak,
                  icon: const Icon(Icons.free_breakfast),
                  label: const Text('Add Break Between Periods'),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < planner.breaks.length; i++)
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      title: Text('Break ${i + 1}'),
                      subtitle: Text(
                        'After P${planner.breaks[i].afterPeriod} • ${planner.breaks[i].start.format(context)} - ${planner.breaks[i].end.format(context)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => planner.removeBreak(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MainPlannerScreen extends StatelessWidget {
  const MainPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SmartTime Builder'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Subjects'),
              Tab(text: 'Classes'),
              Tab(text: 'Classrooms'),
              Tab(text: 'Teachers'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Lessons Builder',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LessonsBuilderScreen()),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
            ),
            IconButton(
              tooltip: 'Generate',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GenerateScreen()),
                );
              },
              icon: const Icon(Icons.auto_awesome),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            SubjectsTab(),
            ClassesTab(),
            ClassroomsTab(),
            TeachersTab(),
          ],
        ),
      ),
    );
  }
}

class SubjectsTab extends StatelessWidget {
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Scaffold(
      body: ListView.builder(
        itemCount: planner.subjects.length,
        itemBuilder: (_, index) {
          final s = planner.subjects[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: s.color),
              title: Text(s.name),
              subtitle: Text(s.abbreviation),
              onTap: () => _showSubjectAvailability(context, s.id, s.unavailableSlots),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('subjects_fab'),
        onPressed: () => _showAddSubject(context),
        label: const Text('Add Subject'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showSubjectAvailability(BuildContext context, String subjectId, Set<String> slots) async {
    final planner = context.read<PlannerState>();
    Set<String> current = Set<String>.from(slots);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Subject Time-Off Matrix', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: TimeOffMatrix(
                    days: planner.days.map((d) => d.abbreviation).toList(),
                    periodsPerDay: planner.periodsPerDay,
                    unavailableSlots: current,
                    onChanged: (next) => setSheetState(() => current = next),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  planner.setSubjectAvailability(subjectId, current);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSubject(BuildContext context) async {
    final name = TextEditingController();
    final abbr = TextEditingController();
    final colors = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    Color? selected;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Choose color *')),
                Wrap(
                  spacing: 8,
                  children: colors
                      .map((c) => GestureDetector(
                            onTap: () => setDialogState(() => selected = c),
                            child: CircleAvatar(
                              backgroundColor: c,
                              child: selected == c ? const Icon(Icons.check, color: Colors.white) : null,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty || abbr.text.trim().isEmpty || selected == null) return;
              context.read<PlannerState>().addSubject(
                    name: name.text.trim(),
                    abbreviation: abbr.text.trim(),
                    color: selected!,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ClassesTab extends StatelessWidget {
  const ClassesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Scaffold(
      body: ListView(
        children: planner.classes
            .map((c) => Card(child: ListTile(title: Text(c.name), subtitle: Text(c.abbreviation))))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClass(context),
        label: const Text('Add Class'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddClass(BuildContext context) async {
    final name = TextEditingController();
    final abbr = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty || abbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addClass(name: name.text.trim(), abbreviation: abbr.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ClassroomsTab extends StatelessWidget {
  const ClassroomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Scaffold(
      body: ListView(
        children: planner.classrooms
            .map((r) => Card(
                  child: ListTile(
                    title: Text(r.name),
                    subtitle: Text('${r.abbreviation} • ${r.type}'),
                  ),
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoom(context),
        label: const Text('Add Classroom'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddRoom(BuildContext context) async {
    final name = TextEditingController();
    final abbr = TextEditingController();
    String type = 'Regular';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Classroom'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                ],
                onChanged: (v) => setDialogState(() => type = v ?? 'Regular'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty || abbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addClassroom(
                    name: name.text.trim(),
                    abbreviation: abbr.text.trim(),
                    type: type,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class TeachersTab extends StatelessWidget {
  const TeachersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    return Scaffold(
      body: ListView(
        children: planner.teachers
            .map((t) => Card(
                  child: ListTile(
                    title: Text(t.fullName),
                    subtitle: Text(t.abbreviation),
                    onTap: () => _showTeacherAvailability(context, t.id, t.unavailableSlots),
                  ),
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeacher(context),
        label: const Text('Add Teacher'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showTeacherAvailability(BuildContext context, String teacherId, Set<String> slots) async {
    final planner = context.read<PlannerState>();
    Set<String> current = Set<String>.from(slots);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Teacher Time-Off Matrix', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: TimeOffMatrix(
                    days: planner.days.map((d) => d.abbreviation).toList(),
                    periodsPerDay: planner.periodsPerDay,
                    unavailableSlots: current,
                    onChanged: (next) => setSheetState(() => current = next),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  planner.setTeacherAvailability(teacherId, current);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTeacher(BuildContext context) async {
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final abbr = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
            TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
            TextField(controller: abbr, decoration: const InputDecoration(labelText: 'Abbreviation')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (firstName.text.trim().isEmpty || abbr.text.trim().isEmpty) return;
              context.read<PlannerState>().addTeacher(
                    firstName: firstName.text.trim(),
                    lastName: lastName.text.trim(),
                    abbreviation: abbr.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
