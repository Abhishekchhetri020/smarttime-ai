import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

// ── Public API ───────────────────────────────────────────────────────────────

Future<void> showLessonWizardDialog(BuildContext context,
    {LessonSpec? lesson}) {
  final planner = context.read<PlannerState>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider<PlannerState>.value(
      value: planner,
      child: _LessonWizardDialog(lesson: lesson),
    ),
  );
}

// ── Frequency Config ─────────────────────────────────────────────────────────

class _FreqConfig {
  int count;
  String length;
  _FreqConfig({this.count = 1, this.length = 'single'});
}

const _lengthOptions = [
  ('single', 'Single'),
  ('double', 'Double'),
  ('triple', 'Triple'),
  ('4', '4 periods'),
  ('5', '5 periods'),
  ('6', '6 periods'),
  ('7', '7 periods'),
  ('8', '8 periods'),
];

int _lenToInt(String l) {
  switch (l) {
    case 'single':
      return 1;
    case 'double':
      return 2;
    case 'triple':
      return 3;
    default:
      return int.tryParse(l) ?? 1;
  }
}

String _lenLabel(String l) => '${_lenToInt(l)}P';

// ── Wizard Dialog ────────────────────────────────────────────────────────────

class _LessonWizardDialog extends StatefulWidget {
  const _LessonWizardDialog({this.lesson});
  final LessonSpec? lesson;
  @override
  State<_LessonWizardDialog> createState() => _LessonWizardDialogState();
}

class _LessonWizardDialogState extends State<_LessonWizardDialog> {
  int _step = 0; // 0=Sections, 1=Setup, 2=Frequency
  bool get isEditing => widget.lesson != null;

  // ── Step 1: Sections ──
  final Set<String> _selectedClassIds = {};
  bool _isFacultyOnly = false;

  // ── Step 2: Setup ──
  String? _subjectId;

  final Set<String> _selectedTeacherIds = {};
  final Set<String> _selectedRoomIds = {};

  // ── Step 3: Frequency ──
  final List<_FreqConfig> _freqConfigs = [_FreqConfig()];

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    if (l != null) {
      _selectedClassIds.addAll(l.classIds);
      _isFacultyOnly = l.classIds.isEmpty;
      _subjectId = l.subjectId;
      _selectedTeacherIds.addAll(l.teacherIds);
      if (l.requiredClassroomId != null) {
        _selectedRoomIds.add(l.requiredClassroomId!);
      }
      _freqConfigs.clear();
      _freqConfigs.add(_FreqConfig(count: l.countPerWeek, length: l.length));
    }
  }

  bool get _canProceedStep0 => _selectedClassIds.isNotEmpty || _isFacultyOnly;
  bool get _canProceedStep1 =>
      _subjectId != null &&
      _subjectId!.isNotEmpty &&
      _selectedTeacherIds.isNotEmpty;

  int get _totalPeriods {
    int total = 0;
    for (final fc in _freqConfigs) {
      total += fc.count * _lenToInt(fc.length);
    }
    return total;
  }

  void _save() {
    final planner = context.read<PlannerState>();

    // Collapse frequency configs into main lesson(s)
    // For simplicity we create one lesson per config or combine them
    // The mockup shows countPerWeek + length as a single pair,
    // but allows multiple configs. We'll store as separate lessons if
    // configs have different lengths, or sum counts if same length.
    final Map<String, int> merged = {};
    for (final fc in _freqConfigs) {
      merged[fc.length] = (merged[fc.length] ?? 0) + fc.count;
    }

    bool isFirst = true;
    for (final entry in merged.entries) {
      planner.addLesson(
        id: isFirst ? widget.lesson?.id : null,
        subjectId: _subjectId!,
        teacherIds: _selectedTeacherIds.toList(),
        classIds: _selectedClassIds.toList(),
        countPerWeek: entry.value,
        length: entry.key,
        requiredClassroomId:
            _selectedRoomIds.isEmpty ? null : _selectedRoomIds.first,
      );
      isFirst = false;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildStepper(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _step == 0
                    ? _buildStep1()
                    : _step == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
              child: Text(isEditing ? 'Edit Lesson' : 'Add New Lesson',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const labels = ['Sections', 'Setup', 'Frequency'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final isDone = _step > i;
          final isActive = _step == i;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? Colors.deepPurple
                            : isActive
                                ? Colors.deepPurple
                                : Colors.grey.shade200,
                        border: isActive
                            ? Border.all(color: Colors.deepPurple, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                )),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? Colors.deepPurple
                              : Colors.grey.shade600,
                        )),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      color:
                          _step > i ? Colors.deepPurple : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────── Step 1

  Widget _buildStep1() {
    final planner = context.watch<PlannerState>();
    final allClasses = planner.classes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Sections',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
            'Select student sections, or skip to schedule an activity without sections',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 16),
        _MultiSelectDropdown<ClassItem>(
          hint: 'Search and select sections...',
          items: allClasses,
          selectedIds: _selectedClassIds,
          getId: (c) => c.id,
          getLabel: (c) => c.name,
          onChanged: (ids) => setState(() => _selectedClassIds
            ..clear()
            ..addAll(ids)),
        ),
        const SizedBox(height: 16),
        const Center(
            child: Text('OR',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            setState(() {
              _isFacultyOnly = true;
              _selectedClassIds.clear();
              _step = 1;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.deepPurple.shade50,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.people,
                      color: Colors.deepPurple.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add a faculty only activity',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                          'For activities like staff meetings, duties, or release time',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────── Step 2

  Widget _buildStep2() {
    final planner = context.watch<PlannerState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configure Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Set up faculty, subjects, and rooms for this activity',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 20),

        // Subject / Activity
        const Text.rich(TextSpan(children: [
          TextSpan(
              text: 'Subject / Activity ',
              style: TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(
              text: '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 8),
        _SubjectSearchField(
          subjects: planner.subjects,
          selectedSubjectId: _subjectId,
          onSelected: (id) => setState(() => _subjectId = id),
          onTextChanged: (text) {},
        ),
        Text('Select from existing subjects or type a new name to create one',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        const SizedBox(height: 20),

        // Faculty
        const Text.rich(TextSpan(children: [
          TextSpan(
              text: 'Faculty ', style: TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(
              text: '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 8),
        _MultiSelectDropdown<TeacherItem>(
          hint: 'Select faculty...',
          items: planner.teachers,
          selectedIds: _selectedTeacherIds,
          getId: (t) => t.id,
          getLabel: (t) => t.fullName,
          onChanged: (ids) => setState(() => _selectedTeacherIds
            ..clear()
            ..addAll(ids)),
        ),
        const SizedBox(height: 20),

        // Room
        Row(
          children: [
            const Text('Room', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text('Use room group',
                  style: TextStyle(
                      fontSize: 12, color: Colors.deepPurple.shade400)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _MultiSelectDropdown<ClassroomItem>(
          hint: 'Select rooms (optional)...',
          items: planner.classrooms,
          selectedIds: _selectedRoomIds,
          getId: (r) => r.id,
          getLabel: (r) => r.name,
          onChanged: (ids) => setState(() => _selectedRoomIds
            ..clear()
            ..addAll(ids)),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────── Step 3

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Define how many times per week and duration',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFBFBFD),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text('Frequency per week',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),

              // Frequency rows
              ..._freqConfigs.asMap().entries.map((e) {
                final idx = e.key;
                final fc = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // −/+ counter
                      _CounterButton(
                          icon: Icons.remove,
                          onPressed: fc.count > 1
                              ? () => setState(() => fc.count--)
                              : null),
                      Container(
                        width: 44,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${fc.count}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      _CounterButton(
                          icon: Icons.add,
                          onPressed: () => setState(() => fc.count++)),
                      const SizedBox(width: 8),
                      const Text('×',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(width: 8),
                      // Length dropdown
                      Expanded(
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: fc.length,
                              isExpanded: true,
                              isDense: true,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87),
                              items: _lengthOptions
                                  .map((o) => DropdownMenuItem(
                                      value: o.$1, child: Text(o.$2)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => fc.length = v);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('= ${fc.count * _lenToInt(fc.length)}P',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                      if (_freqConfigs.length > 1)
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: Colors.grey.shade400),
                          onPressed: () =>
                              setState(() => _freqConfigs.removeAt(idx)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                );
              }),

              TextButton.icon(
                onPressed: () =>
                    setState(() => _freqConfigs.add(_FreqConfig())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add another configuration',
                    style: TextStyle(fontSize: 13)),
              ),

              const Divider(),
              // Preview
              Row(
                children: [
                  const Text('Preview',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const Spacer(),
                  Text(
                      '$_totalPeriods period${_totalPeriods == 1 ? '' : 's'} / week',
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _buildPreviewChips(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'Want to fix specific time slots? ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                            fontSize: 12)),
                    TextSpan(
                        text:
                            'You can fix lessons to specific days and periods later in the Timetable Editor.',
                        style: TextStyle(
                            color: Colors.amber.shade700, fontSize: 12)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreviewChips() {
    final chips = <Widget>[];
    for (final fc in _freqConfigs) {
      for (int i = 0; i < fc.count; i++) {
        chips.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.deepPurple.shade200),
          ),
          child: Text(_lenLabel(fc.length),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700)),
        ));
      }
    }
    return chips;
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_step > 0)
            TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          if (_step < 2)
            FilledButton.icon(
              onPressed: _step == 0
                  ? (_canProceedStep0 ? () => setState(() => _step = 1) : null)
                  : (_canProceedStep1 ? () => setState(() => _step = 2) : null),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Next'),
            )
          else
            FilledButton.icon(
              onPressed: _canProceedStep1 ? _save : null,
              icon: const Icon(Icons.check, size: 16),
              label: Text(isEditing ? 'Update Lesson' : 'Create Lesson'),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600),
            ),
        ],
      ),
    );
  }
}

// ── Counter Button ───────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        style: IconButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── Subject Search Field ─────────────────────────────────────────────────────

class _SubjectSearchField extends StatefulWidget {
  const _SubjectSearchField({
    required this.subjects,
    required this.selectedSubjectId,
    required this.onSelected,
    required this.onTextChanged,
  });
  final List<SubjectItem> subjects;
  final String? selectedSubjectId;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onTextChanged;

  @override
  State<_SubjectSearchField> createState() => _SubjectSearchFieldState();
}

class _SubjectSearchFieldState extends State<_SubjectSearchField> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSubjectId != null) {
      final match =
          widget.subjects.where((s) => s.id == widget.selectedSubjectId);
      if (match.isNotEmpty) _ctrl.text = match.first.name;
    }
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showDropdown = true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _ctrl.text.toLowerCase();
    final filtered = widget.subjects
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search subjects or type custom activity',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (text) {
            widget.onTextChanged(text);
            setState(() => _showDropdown = true);
            // If exact match, select it
            final exactMatch = widget.subjects.where(
                (s) => s.name.toLowerCase() == text.toLowerCase().trim());
            if (exactMatch.isNotEmpty) {
              widget.onSelected(exactMatch.first.id);
            } else if (text.trim().isNotEmpty) {
              widget.onSelected(text.trim());
            } else {
              widget.onSelected(null);
            }
          },
          onTap: () => setState(() => _showDropdown = true),
        ),
        if (_showDropdown && filtered.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final s = filtered[index];
                return ListTile(
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(s.color),
                    ),
                  ),
                  title: Text(s.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(s.abbr,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  dense: true,
                  onTap: () {
                    _ctrl.text = s.name;
                    widget.onSelected(s.id);
                    setState(() => _showDropdown = false);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Multi-Select Dropdown ────────────────────────────────────────────────────

class _MultiSelectDropdown<T> extends StatefulWidget {
  const _MultiSelectDropdown({
    required this.hint,
    required this.items,
    required this.selectedIds,
    required this.getId,
    required this.getLabel,
    required this.onChanged,
  });
  final String hint;
  final List<T> items;
  final Set<String> selectedIds;
  final String Function(T) getId;
  final String Function(T) getLabel;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_MultiSelectDropdown<T>> createState() =>
      _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<_MultiSelectDropdown<T>> {
  bool _expanded = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) =>
            widget.getLabel(item).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _expanded ? Colors.deepPurple : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.selectedIds.isEmpty
                      ? Text(widget.hint,
                          style: TextStyle(color: Colors.grey.shade500))
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: widget.selectedIds.map((id) {
                            final match = widget.items
                                .where((item) => widget.getId(item) == id);
                            final label = match.isEmpty
                                ? id
                                : widget.getLabel(match.first);
                            return Chip(
                              label: Text(label,
                                  style: const TextStyle(fontSize: 11)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                final newIds =
                                    Set<String>.from(widget.selectedIds)
                                      ..remove(id);
                                widget.onChanged(newIds);
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                ),
                Icon(Icons.expand_more, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple.shade200),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search options...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final id = widget.getId(item);
                      final isSelected = widget.selectedIds.contains(id);
                      return CheckboxListTile(
                        title: Text(widget.getLabel(item),
                            style: const TextStyle(fontSize: 14)),
                        value: isSelected,
                        dense: true,
                        onChanged: (checked) {
                          final newIds = Set<String>.from(widget.selectedIds);
                          if (checked == true) {
                            newIds.add(id);
                          } else {
                            newIds.remove(id);
                          }
                          widget.onChanged(newIds);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
