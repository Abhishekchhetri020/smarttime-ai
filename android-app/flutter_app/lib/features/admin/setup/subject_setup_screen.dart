import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_placeholder.dart';
import '../planner_state.dart';
import '../time_off_picker.dart';
// ── Column Enum ──────────────────────────────────────────────────────────────

enum _SubjCol { name, shortName, color, availability, actions }

const _colLabels = {
  _SubjCol.name: 'NAME',
  _SubjCol.shortName: 'SHORT NAME',
  _SubjCol.color: 'COLOR',
  _SubjCol.availability: 'AVAILABILITY',
  _SubjCol.actions: 'ACTIONS',
};

const _requiredCols = {
  _SubjCol.name,
  _SubjCol.shortName,
  _SubjCol.availability,
  _SubjCol.actions
};

// ── Default "Available Subjects" ─────────────────────────────────────────────

class _AvailableSubject {
  final String name;
  final String abbr;
  final Color dotColor;

  const _AvailableSubject(this.name, this.abbr, this.dotColor);
}

const _defaultSubjects = [
  _AvailableSubject('AUDIO VISUAL', 'AV', Colors.blue),
  _AvailableSubject('Art & Craft', 'A&C', Colors.orange),
  _AvailableSubject('CHEMISTRY', 'CHE', Colors.green),
  _AvailableSubject('Computer Science', 'CS', Colors.indigo),
  _AvailableSubject('English', 'ENG', Colors.red),
  _AvailableSubject('Geography', 'GEO', Colors.teal),
  _AvailableSubject('Hindi', 'HIN', Colors.brown),
  _AvailableSubject('History', 'HIS', Colors.deepPurple),
  _AvailableSubject('Mathematics', 'MATH', Colors.pink),
  _AvailableSubject('Music', 'MUS', Colors.amber),
  _AvailableSubject('Physics', 'PHY', Colors.cyan),
  _AvailableSubject('Science', 'SCI', Colors.lightGreen),
];

// ── Main Screen ──────────────────────────────────────────────────────────────

class SubjectSetupScreen extends StatefulWidget {
  const SubjectSetupScreen({super.key});

  @override
  State<SubjectSetupScreen> createState() => _SubjectSetupScreenState();
}

class _SubjectSetupScreenState extends State<SubjectSetupScreen> {
  String _searchQuery = '';
  final _scrollCtrl = ScrollController();

  final Set<_SubjCol> _visibleCols = {
    _SubjCol.name,
    _SubjCol.shortName,
    _SubjCol.availability,
    _SubjCol.actions,
  };

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showColumnsMenu(BuildContext context) {
    final planner = context.read<PlannerState>();
    showDialog(
      context: context,
      builder: (ctx) {
        return ChangeNotifierProvider<PlannerState>.value(
          value: planner,
          child: StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Show/Hide Columns',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _SubjCol.values.map((c) {
                  final isRequired = _requiredCols.contains(c);
                  final isVisible = _visibleCols.contains(c);
                  return CheckboxListTile(
                    value: isVisible,
                    onChanged: isRequired
                        ? null
                        : (val) {
                            setDialogState(() {
                              setState(() {
                                if (val == true) {
                                  _visibleCols.add(c);
                                } else {
                                  _visibleCols.remove(c);
                                }
                              });
                            });
                          },
                    title: Row(
                      children: [
                        Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                          color: isRequired ? Colors.deepPurple : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_colLabels[c]!.substring(0, 1) +
                            _colLabels[c]!.substring(1).toLowerCase()),
                        if (isRequired) ...[
                          const SizedBox(width: 8),
                          Text('(Required)',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    dense: true,
                    activeColor: Colors.deepPurple,
                  );
                }).toList(),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    // Filter available subjects – remove those already in timetable
    final existingNames =
        planner.subjects.map((s) => s.name.toLowerCase()).toSet();
    final filteredAvailable = _defaultSubjects.where((ds) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          ds.name.toLowerCase().contains(q) ||
          ds.abbr.toLowerCase().contains(q);
      return matchesSearch && !existingNames.contains(ds.name.toLowerCase());
    }).toList();

    final orderedCols =
        _SubjCol.values.where((c) => _visibleCols.contains(c)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subjects & Activities',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Define subjects like Math, Science, and activities like Assembly',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Count + Columns ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subjects (${planner.subjects.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showColumnsMenu(context),
                  icon: const Icon(Icons.settings, size: 14),
                  label: const Text('Columns', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ─── DataTable ───────────────────────────────────────────
            if (planner.subjects.isEmpty)
              const EmptyStatePlaceholder(
                icon: Icons.menu_book_outlined,
                title: 'No Subjects Added',
                message:
                    'Add subjects (e.g., Math, Science) or activities (e.g., Assembly) to schedule them.',
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  controller: _scrollCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8F9FB)),
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                      dataTextStyle:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      columns: orderedCols.map((c) {
                        return DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_colLabels[c]!),
                              if (c == _SubjCol.name ||
                                  c == _SubjCol.shortName) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.unfold_more,
                                    size: 14, color: Colors.grey.shade400),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      rows: planner.subjects.map((subj) {
                        return DataRow(
                          cells: orderedCols.map((c) {
                            return DataCell(_SubjectCell(
                              subject: subj,
                              column: c,
                              onDeleteRow: () =>
                                  setState(() => planner.subjects.remove(subj)),
                            ));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            // ─── Keyboard Shortcuts ──────────────────────────────────
            if (planner.subjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildShortcutsLegend(),
            ],
            const SizedBox(height: 32),

            // ─── Available Subjects ──────────────────────────────────
            const Text('Available Subjects',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBulkImportDialog(context),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Bulk Import'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddSubjectDialog(context),
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('Add New Subject'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: filteredAvailable.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No available subjects found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: filteredAvailable.map((ds) {
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 6,
                            backgroundColor: ds.dotColor,
                          ),
                          title: Text(ds.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(ds.abbr,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                          trailing: OutlinedButton(
                            onPressed: () {
                              planner.addSubject(SubjectItem(
                                name: ds.name,
                                abbr: ds.abbr,
                                color: ds.dotColor.toARGB32(),
                              ));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Add to Timetable',
                                style: TextStyle(fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutsLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFBFBFD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keyboard shortcuts:',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _shortcutRow(['Enter'], 'Edit / Save & move down')),
              Expanded(
                  child: _shortcutRow(['Tab'], 'Save & move to next field')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _shortcutRow(['Esc'], 'Cancel editing')),
              Expanded(child: _shortcutRow(['↑↓'], 'Navigate up/down')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shortcutRow(List<String> keys, String desc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('/',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1))
              ],
            ),
            child: Text(keys[i],
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ),
        ],
        const SizedBox(width: 8),
        Flexible(
            child: Text(desc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
      ],
    );
  }

  Future<void> _showAddSubjectDialog(BuildContext context) async {
    final planner = context.read<PlannerState>();
    final nameCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Subject',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Create a new subject resource',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name *',
                      hintText: 'e.g., Physics, Mathematics',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Subject name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: abbrCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Short Name',
                      hintText: 'e.g., PHY, MATH',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _ShowOptionalSettingsSection(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final abbr = abbrCtrl.text.trim().isNotEmpty
                              ? abbrCtrl.text.trim()
                              : nameCtrl.text
                                  .trim()
                                  .substring(0,
                                      nameCtrl.text.trim().length.clamp(0, 3))
                                  .toUpperCase();
                          planner.addSubject(SubjectItem(
                            name: nameCtrl.text.trim(),
                            abbr: abbr,
                            color: Colors.blue.toARGB32(),
                          ));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Create Subject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBulkImportDialog(BuildContext context) async {
    final planner = context.read<PlannerState>();
    await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: _BulkImportSubjectsDialog(
          onImport: (subjects) async {
            for (final s in subjects) {
              await planner.addSubject(s);
            }
          },
        ),
      ),
    );
  }
}

// ── Show Optional Settings (expandable placeholder) ──────────────────────────

class _ShowOptionalSettingsSection extends StatefulWidget {
  const _ShowOptionalSettingsSection();
  @override
  State<_ShowOptionalSettingsSection> createState() =>
      _ShowOptionalSettingsSectionState();
}

class _ShowOptionalSettingsSectionState
    extends State<_ShowOptionalSettingsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _expanded ? 'Hide Optional Settings' : 'Show Optional Settings',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          Text('No additional optional settings at this time.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ],
    );
  }
}

// ── Subject Cell (Inline Editing) ────────────────────────────────────────────

class _SubjectCell extends StatefulWidget {
  const _SubjectCell({
    required this.subject,
    required this.column,
    required this.onDeleteRow,
  });

  final SubjectItem subject;
  final _SubjCol column;
  final VoidCallback onDeleteRow;

  @override
  State<_SubjectCell> createState() => _SubjectCellState();
}

class _SubjectCellState extends State<_SubjectCell> {
  bool _isEditing = false;
  late TextEditingController _ctrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _initialValue);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitAndExit();
      }
    });
  }

  String get _initialValue {
    switch (widget.column) {
      case _SubjCol.name:
        return widget.subject.name;
      case _SubjCol.shortName:
        return widget.subject.abbr;
      default:
        return '';
    }
  }

  @override
  void didUpdateWidget(covariant _SubjectCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _ctrl.text = _initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    if (widget.column == _SubjCol.actions ||
        widget.column == _SubjCol.availability ||
        widget.column == _SubjCol.color) {
      return;
    }
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  void _commitAndExit() {
    if (!mounted) return;
    final planner = context.read<PlannerState>();
    final val = _ctrl.text.trim();
    SubjectItem updated = widget.subject;

    if (widget.column == _SubjCol.name) {
      updated = updated.copyWith(name: val);
    } else if (widget.column == _SubjCol.shortName) {
      updated = updated.copyWith(abbr: val);
    }

    planner.updateSubject(updated);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    // ── Actions column ──
    if (widget.column == _SubjCol.actions) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 18, color: Colors.red.shade400),
            onPressed: widget.onDeleteRow,
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
          ),
        ],
      );
    }

    // ── Color column ──
    if (widget.column == _SubjCol.color) {
      return CircleAvatar(
        radius: 10,
        backgroundColor: Color(widget.subject.color),
      );
    }

    // ── Availability column ──
    if (widget.column == _SubjCol.availability) {
      final timeOffCount = widget.subject.timeOff.values
          .where((v) => v == TimeOffState.unavailable)
          .length;
      return InkWell(
        onTap: () => _showAvailabilityDialog(context, widget.subject),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeOffCount > 0
                    ? '$timeOffCount'
                    : '${planner.bellTimes.length * planner.workingDays}',
                style: TextStyle(
                  color: timeOffCount > 0
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Inline editing (Name / Short Name) ──
    if (_isEditing) {
      return SizedBox(
        width: widget.column == _SubjCol.name ? 180 : 120,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _ctrl.text = _initialValue;
                setState(() => _isEditing = false);
              }
            }
          },
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _commitAndExit(),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _enterEditMode,
      child: Container(
        constraints:
            BoxConstraints(minWidth: widget.column == _SubjCol.name ? 100 : 60),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          _initialValue,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  void _showAvailabilityDialog(BuildContext context, SubjectItem subject) {
    final planner = context.read<PlannerState>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: _ManageSubjectAvailabilityDialog(
          subject: subject,
          bellTimes: planner.bellTimes,
          workingDays: planner.workingDays,
          onSave: (newTimeOff) {
            planner.updateSubjectConstraints(subject.id, newTimeOff);
          },
        ),
      ),
    );
  }
}

// ── Manage Availability Dialog ───────────────────────────────────────────────

class _ManageSubjectAvailabilityDialog extends StatefulWidget {
  const _ManageSubjectAvailabilityDialog({
    required this.subject,
    required this.bellTimes,
    required this.workingDays,
    required this.onSave,
  });

  final SubjectItem subject;
  final List<String> bellTimes;
  final int workingDays;
  final void Function(Map<String, TimeOffState>) onSave;

  @override
  State<_ManageSubjectAvailabilityDialog> createState() =>
      _ManageSubjectAvailabilityDialogState();
}

class _ManageSubjectAvailabilityDialogState
    extends State<_ManageSubjectAvailabilityDialog> {
  late Map<String, TimeOffState> _grid;
  late List<int> _dayIndices;

  static const _dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _grid = Map<String, TimeOffState>.from(widget.subject.timeOff);
    _dayIndices = List.generate(widget.workingDays, (i) => i + 1);
  }

  String _key(int periodIndex, int dayIndex) => '$periodIndex:$dayIndex';

  TimeOffState _state(int p, int d) =>
      _grid[_key(p, d)] ?? TimeOffState.available;

  void _toggle(int p, int d) {
    final key = _key(p, d);
    setState(() {
      _grid[key] = _state(p, d) == TimeOffState.available
          ? TimeOffState.unavailable
          : TimeOffState.available;
    });
  }

  String _periodLabel(int idx) {
    if (idx >= widget.bellTimes.length) return 'Period ${idx + 1}';
    final bt = widget.bellTimes[idx];
    final parts = bt.split('|');
    return parts.isNotEmpty ? parts[0] : 'Period ${idx + 1}';
  }

  String _periodTime(int idx) {
    if (idx >= widget.bellTimes.length) return '';
    final bt = widget.bellTimes[idx];
    final parts = bt.split('|');
    return parts.length > 1 ? parts[1] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Manage Availability for ${widget.subject.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            color: Colors.blue.shade800, fontSize: 13),
                        children: [
                          const TextSpan(text: 'Mark periods when '),
                          TextSpan(
                              text: widget.subject.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' is '),
                          const TextSpan(
                              text: 'not available',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(
                              text:
                                  ' for scheduling. Click any cell or headers to toggle availability.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade400, size: 16),
                const SizedBox(width: 4),
                const Text('Available', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.cancel, color: Colors.red.shade400, size: 16),
                const SizedBox(width: 4),
                const Text('Time Off', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF8F9FB)),
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    dataTextStyle: const TextStyle(fontSize: 12),
                    columns: [
                      const DataColumn(label: Text('Period/Day')),
                      ..._dayIndices.map((d) => DataColumn(
                            label: Text(
                                d < _dayNames.length ? _dayNames[d] : 'Day $d'),
                          )),
                    ],
                    rows: List.generate(widget.bellTimes.length, (pIdx) {
                      return DataRow(cells: [
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_periodLabel(pIdx),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            if (_periodTime(pIdx).isNotEmpty)
                              Text(_periodTime(pIdx),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500)),
                          ],
                        )),
                        ..._dayIndices.map((dIdx) {
                          final state = _state(pIdx, dIdx);
                          return DataCell(
                            GestureDetector(
                              onTap: () => _toggle(pIdx, dIdx),
                              child: Container(
                                width: 60,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: state == TimeOffState.available
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  state == TimeOffState.available
                                      ? Icons.check
                                      : Icons.close,
                                  color: state == TimeOffState.available
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        }),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${widget.workingDays} working days',
                style:
                    TextStyle(color: Colors.deepPurple.shade400, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    widget.onSave(_grid);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bulk Import Subjects Dialog ──────────────────────────────────────────────

class _BulkImportSubjectsDialog extends StatefulWidget {
  const _BulkImportSubjectsDialog({required this.onImport});
  final Future<void> Function(List<SubjectItem>) onImport;

  @override
  State<_BulkImportSubjectsDialog> createState() =>
      _BulkImportSubjectsDialogState();
}

class _BulkImportSubjectsDialogState extends State<_BulkImportSubjectsDialog> {
  bool _importing = false;
  String? _pickedFileName;
  List<List<dynamic>>? _csvData;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      final csvString = utf8.decode(file.bytes!);
      final data = const CsvToListConverter().convert(csvString);
      setState(() {
        _pickedFileName = file.name;
        _csvData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to parse CSV: $e')));
      }
    }
  }

  Future<void> _processImport() async {
    if (_csvData == null || _csvData!.isEmpty) return;
    setState(() => _importing = true);

    try {
      final rows = _csvData!;
      final headers =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

      int nameIdx = headers.indexOf('subject name');
      int shortNameIdx = headers.indexOf('short name');

      if (nameIdx == -1) {
        nameIdx = 0;
        shortNameIdx = 1;
      }

      final imported = <SubjectItem>[];

      bool isHeader(List<dynamic> row) {
        if (row.isEmpty) return false;
        return row[nameIdx].toString().trim().toLowerCase() == 'subject name';
      }

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || (i == 0 && isHeader(row))) continue;

        String name = '';
        if (nameIdx >= 0 && nameIdx < row.length) {
          name = row[nameIdx].toString().trim();
        }
        if (name.isEmpty) continue;

        String abbr = '';
        if (shortNameIdx >= 0 && shortNameIdx < row.length) {
          abbr = row[shortNameIdx].toString().trim();
        }
        if (abbr.isEmpty) {
          abbr = name.substring(0, name.length.clamp(0, 3)).toUpperCase();
        }

        imported.add(SubjectItem(
          name: name,
          abbr: abbr,
          color: Colors.blue.toARGB32(),
        ));
      }

      await widget.onImport(imported);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${imported.length} subjects')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing subjects: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _downloadSample() async {
    try {
      final String csvContent = const ListToCsvConverter().convert([
        ['Subject Name', 'Short Name'],
        ['Mathematics', 'MATH'],
        ['Physics', 'PHY'],
        ['English', 'ENG'],
      ]);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/subjects_import_template.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Subjects Import Template',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate template: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Import Subjects',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Import subjects with their names and optional short names',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text('CSV Format',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bullet(
                      'Subject Name', ' (required) - Full name of the subject'),
                  _bullet(
                      'Short Name', ' (optional) - Abbreviation for display'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download_outlined,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      const Text('Step 1: Download Sample',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Download a sample CSV to see the expected format.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download Sample'),
                      onPressed: _downloadSample,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.upload_file_outlined,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      const Text('Step 2: Upload Your CSV',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Select your CSV file with subjects data.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(_pickedFileName == null
                          ? 'Select CSV File'
                          : 'Change File ($_pickedFileName)'),
                      onPressed: _importing ? null : _pickFile,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _csvData == null
                    ? 'Select a CSV file to continue'
                    : 'Found ${(_csvData!.length > 1 ? _csvData!.length - 1 : 0)} entries to import',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _importing ? null : () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _importing || _csvData == null ? null : _processImport,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                    child: _importing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.blue),
                          )
                        : Text(
                            'Import ${_csvData == null ? 0 : (_csvData!.length > 1 ? _csvData!.length - 1 : 0)} Subjects'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8, left: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.blue.shade700, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800)),
                TextSpan(
                    text: desc, style: TextStyle(color: Colors.blue.shade700)),
              ]),
            ),
          )
        ],
      ),
    );
  }
}
