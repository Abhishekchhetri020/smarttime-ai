import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_placeholder.dart';
import '../planner_state.dart';
import '../time_off_picker.dart';

// ── Column definitions ──────────────────────────────────────────────────────

enum _Col {
  name,
  shortName,
  designation,
  email,
  phone,
  color,
  availability,
  actions
}

const _colLabels = <_Col, String>{
  _Col.name: 'Name',
  _Col.shortName: 'Short Name',
  _Col.designation: 'Designation',
  _Col.email: 'Email',
  _Col.phone: 'Phone',
  _Col.color: 'Color',
  _Col.availability: 'Availability',
  _Col.actions: 'Actions',
};

const _colRequired = <_Col>{
  _Col.name,
  _Col.shortName,
  _Col.availability,
  _Col.actions
};

// ── Curated palette for auto-assigning unique colors ─────────────────────────

const _entityColors = [
  0xFF7C3AED, // Purple
  0xFF4F46E5, // Blue
  0xFFDB2777, // Pink
  0xFF059669, // Green
  0xFFD97706, // Amber
  0xFFDC2626, // Red
  0xFF0891B2, // Cyan
  0xFF7C2D12, // Brown
  0xFF4F46E5, // Indigo
  0xFF0D9488, // Teal
  0xFFBE185D, // Rose
  0xFF9333EA, // Violet
  0xFFEA580C, // Orange
  0xFF1D4ED8, // DarkBlue
  0xFF16A34A, // Emerald
  0xFF9F1239, // Crimson
  0xFF0284C7, // Sky
  0xFF6D28D9, // DeepPurple
  0xFFCA8A04, // Yellow
  0xFF475569, // Slate
];

int _autoColor(int index) => _entityColors[index % _entityColors.length];

// ── Screen ──────────────────────────────────────────────────────────────────

class TeacherSetupScreen extends StatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  State<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends State<TeacherSetupScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Visible columns (togglable)
  final Set<_Col> _visible = {
    _Col.name,
    _Col.shortName,
    _Col.designation,
    _Col.email,
    _Col.color,
    _Col.availability,
    _Col.actions,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<TeacherItem> _filtered(List<TeacherItem> all) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((t) =>
            t.fullName.toLowerCase().contains(q) ||
            t.abbr.toLowerCase().contains(q) ||
            (t.email ?? '').toLowerCase().contains(q))
        .toList();
  }

  String _colValue(_Col col, TeacherItem t) {
    switch (col) {
      case _Col.name:
        return t.fullName;
      case _Col.shortName:
        return t.abbr;
      case _Col.designation:
        return t.designation ?? '—';
      case _Col.email:
        return t.email ?? '—';
      case _Col.phone:
        return t.phone ?? '—';
      case _Col.color:
        return '';
      case _Col.availability:
        return 'Available';
      case _Col.actions:
        return '';
    }
  }

  void _showColumnPicker() {
    final planner = context.read<PlannerState>();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Show/Hide Columns',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                ..._Col.values.map((col) {
                  final required = _colRequired.contains(col);
                  final visible = _visible.contains(col);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      visible ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                      color: visible
                          ? Theme.of(ctx).colorScheme.primary
                          : Colors.grey,
                    ),
                    title: Row(
                      children: [
                        Text(_colLabels[col]!),
                        if (required) ...[
                          const SizedBox(width: 6),
                          Text('(Required)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                    trailing: visible
                        ? Icon(Icons.check,
                            size: 18, color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: required
                        ? null
                        : () {
                            setSt(() {
                              setState(() {
                                if (visible) {
                                  _visible.remove(col);
                                } else {
                                  _visible.add(col);
                                }
                              });
                            });
                          },
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showAddUserDialog({TeacherItem? existing}) async {
    final planner = context.read<PlannerState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: _AddUserDialog(
          existing: existing,
          onSave: (item) async {
            await planner.addTeacher(item);
          },
        ),
      ),
    );
  }

  Future<void> _showBulkImportDialog() async {
    final planner = context.read<PlannerState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: _BulkImportUsersDialog(
          onImport: (List<TeacherItem> imported) async {
            for (final t in imported) {
              await planner.addTeacher(t);
            }
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final teachers = planner.teachers;
    final filtered = _filtered(teachers);
    final theme = Theme.of(context);
    final visibleCols = _Col.values.where((c) => _visible.contains(c)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planner.sessionName.isNotEmpty ? planner.sessionName : 'Faculty',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              planner.sessionStartDate != null
                  ? planner.sessionStartDate!.substring(0, 10)
                  : '',
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Faculty card ─────────────────────────────────────
                  _FacultyCard(
                    teachers: filtered,
                    visibleCols: visibleCols,
                    colLabels: _colLabels,
                    colValue: _colValue,
                    onColumnsPressed: _showColumnPicker,
                    onRowTap: (t) => _showAddUserDialog(existing: t),
                    onDeleteRow: (t) {
                      context.read<PlannerState>().removeTeacher(t.id);
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Available Users section ───────────────────────────
                  _AvailableUsersSection(
                    allTeachers: teachers,
                    onAddUser: () => _showAddUserDialog(),
                    onBulkImport: () => _showBulkImportDialog(),
                    onAddToTimetable: (name, email) async {
                      // Parse name into first/last
                      final parts = name.trim().split(' ');
                      final first = parts.first;
                      final last =
                          parts.length > 1 ? parts.sublist(1).join(' ') : '';
                      final abbr = _autoAbbr(first, last);
                      await context.read<PlannerState>().addTeacher(
                            TeacherItem(
                              firstName: first,
                              lastName: last,
                              abbr: abbr,
                              email: email,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom nav ───────────────────────────────────────────────
          _BottomNavBar(
            onBack: () => Navigator.of(context).pop(),
            onNext: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ── Faculty Card ─────────────────────────────────────────────────────────────

class _FacultyCard extends StatefulWidget {
  const _FacultyCard({
    required this.teachers,
    required this.visibleCols,
    required this.colLabels,
    required this.colValue,
    required this.onColumnsPressed,
    required this.onRowTap,
    required this.onDeleteRow,
  });

  final List<TeacherItem> teachers;
  final List<_Col> visibleCols;
  final Map<_Col, String> colLabels;
  final String Function(_Col, TeacherItem) colValue;
  final VoidCallback onColumnsPressed;
  final void Function(TeacherItem) onRowTap;
  final void Function(TeacherItem) onDeleteRow;

  @override
  State<_FacultyCard> createState() => _FacultyCardState();
}

class _FacultyCardState extends State<_FacultyCard> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE0E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.people_alt_outlined,
                      color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Faculty',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Add teachers, instructors, and other teaching staff for this timetable',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Count + columns button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Faculty (${widget.teachers.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onColumnsPressed,
                  icon: const Icon(Icons.settings, size: 14),
                  label: const Text('Columns', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFFDDE0E9)),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Table
          if (widget.teachers.isEmpty)
            const EmptyStatePlaceholder(
              icon: Icons.people_outline,
              title: 'No Faculty Added',
              message:
                  'Add teachers, instructors, and other teaching staff for this timetable.',
            )
          else
            Scrollbar(
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
                  columns: widget.visibleCols
                      .map((c) => DataColumn(
                            label: Row(
                              children: [
                                Text(widget.colLabels[c]!.toUpperCase()),
                                const SizedBox(width: 4),
                                const Icon(Icons.unfold_more, size: 12),
                              ],
                            ),
                          ))
                      .toList(),
                  rows: widget.teachers.map((t) {
                    return DataRow(
                      cells: widget.visibleCols
                          .map((c) => DataCell(
                                _FacultyCell(
                                  teacher: t,
                                  column: c,
                                  initialValue: widget.colValue(c, t),
                                  onDelete: () => widget.onDeleteRow(t),
                                ),
                              ))
                          .toList(),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Keyboard Shortcuts Legend
          if (widget.teachers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keyboard shortcuts:',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShortcutItem(
                                keys: const ['Enter'],
                                desc: 'Edit / Save & move down'),
                            const SizedBox(height: 6),
                            _ShortcutItem(
                                keys: const ['Esc'], desc: 'Cancel editing'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShortcutItem(
                                keys: const ['Tab'],
                                desc: 'Save & move to next field'),
                            const SizedBox(height: 6),
                            _ShortcutItem(
                                keys: const ['↑', '↓'],
                                desc: 'Navigate up/down'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  const _ShortcutItem({required this.keys, required this.desc});
  final List<String> keys;
  final String desc;

  @override
  Widget build(BuildContext context) {
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
}

// ── Editable Cell Widget ─────────────────────────────────────────────────────

class _FacultyCell extends StatefulWidget {
  const _FacultyCell({
    required this.teacher,
    required this.column,
    required this.initialValue,
    required this.onDelete,
  });

  final TeacherItem teacher;
  final _Col column;
  final String initialValue;
  final VoidCallback onDelete;

  @override
  State<_FacultyCell> createState() => _FacultyCellState();
}

class _FacultyCellState extends State<_FacultyCell> {
  bool _isEditing = false;
  late TextEditingController _ctrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitAndExit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FacultyCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.initialValue != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    if (widget.column == _Col.actions ||
        widget.column == _Col.availability ||
        widget.column == _Col.color) return;
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  Future<void> _commitAndExit() async {
    final nav = Navigator.of(context); // just in case
    if (!mounted) return;

    final planner = context.read<PlannerState>();
    final val = _ctrl.text.trim();

    TeacherItem updated = widget.teacher;

    if (widget.column == _Col.name) {
      final parts = val.split(' ');
      final f = parts.first;
      final l = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      updated = updated.copyWith(firstName: f, lastName: l);
    } else if (widget.column == _Col.shortName) {
      updated = updated.copyWith(abbr: val);
    } else if (widget.column == _Col.designation) {
      updated = updated.copyWith(designation: val.isEmpty ? null : val);
    } else if (widget.column == _Col.email) {
      updated = updated.copyWith(email: val.isEmpty ? null : val);
    } else if (widget.column == _Col.phone) {
      updated = updated.copyWith(phone: val.isEmpty ? null : val);
    }

    await planner.updateTeacher(updated);
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _ctrl.text = widget.initialValue;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.column == _Col.actions) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.link, size: 18),
            color: Colors.grey.shade400,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            color: Colors.grey.shade400,
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    if (widget.column == _Col.color) {
      // Get index of this teacher for auto-color
      final planner = context.read<PlannerState>();
      final idx = planner.teachers.indexOf(widget.teacher);
      final colorVal = widget.teacher.color != null
          ? int.tryParse(widget.teacher.color!) ?? _autoColor(idx)
          : _autoColor(idx);
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color(colorVal),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
      );
    }

    if (widget.column == _Col.availability) {
      final offCount = widget.teacher.timeOff.values
          .where((v) => v == TimeOffState.unavailable)
          .length;
      return InkWell(
        onTap: () {
          final planner = context.read<PlannerState>();
          showDialog<void>(
            context: context,
            builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
              value: planner,
              child: _ManageAvailabilityDialog(teacher: widget.teacher),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF7EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Text(
                    offCount.toString(),
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
          ],
        ),
      );
    }

    if (_isEditing) {
      return SizedBox(
        width: 120, // max width for inline edit
        child: Focus(
          onKeyEvent: (node, event) {
            // Note: the event handling is usually better done inside a regular textfield, but this works minimally for ESC
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue)),
            ),
            onSubmitted: (_) => _commitAndExit(),
          ),
        ),
      );
    }

    // Default view mode
    return GestureDetector(
      onTap: _enterEditMode,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          widget.initialValue,
          style: TextStyle(
            color: widget.initialValue == '—' ? Colors.grey : Colors.black87,
            fontStyle: widget.initialValue == '—'
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}

// ── Available Users section ──────────────────────────────────────────────────

// Mock "directory" users (in real app comes from org membership)
const _mockOrgUsers = <(String, String)>[];

class _AvailableUsersSection extends StatefulWidget {
  const _AvailableUsersSection({
    required this.allTeachers,
    required this.onAddUser,
    required this.onBulkImport,
    required this.onAddToTimetable,
  });

  final List<TeacherItem> allTeachers;
  final Future<void> Function() onAddUser;
  final VoidCallback onBulkImport;
  final Future<void> Function(String name, String email) onAddToTimetable;

  @override
  State<_AvailableUsersSection> createState() => _AvailableUsersSectionState();
}

class _AvailableUsersSectionState extends State<_AvailableUsersSection> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchingUsers = _mockOrgUsers.where((u) {
      if (_q.isEmpty) return true;
      return u.$1.toLowerCase().contains(_q.toLowerCase()) ||
          u.$2.toLowerCase().contains(_q.toLowerCase());
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE0E9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Users',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),

          // Search
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: Colors.grey),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDDE0E9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDDE0E9)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onBulkImport,
                  icon: const Icon(Icons.upload, size: 16),
                  label:
                      const Text('Bulk Import', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFDDE0E9)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onAddUser,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add User', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // User tiles
          ...matchingUsers.map((u) {
            final alreadyAdded = widget.allTeachers
                .any((t) => t.email == u.$2 || t.fullName == u.$1);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDE0E9)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(u.$2,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: alreadyAdded
                        ? OutlinedButton(
                            onPressed: null,
                            child: const Text('Already Added'),
                          )
                        : OutlinedButton(
                            onPressed: () =>
                                widget.onAddToTimetable(u.$1, u.$2),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.3)),
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.05),
                            ),
                            child: const Text('Add to Timetable'),
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Add User Dialog ───────────────────────────────────────────────────────────

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({required this.onSave, this.existing});
  final Future<void> Function(TeacherItem) onSave;
  final TeacherItem? existing;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _nameCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  String _role = 'Member';
  bool _showAdditional = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  // Tracks the last value the auto-generator produced so we know if the user
  // has manually overridden it.
  String _lastAutoAbbr = '';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _nameCtrl.text = t.fullName;
      _shortNameCtrl.text = t.abbr;
      _lastAutoAbbr = t.abbr;
      _emailCtrl.text = t.email ?? '';
      _phoneCtrl.text = t.phone ?? '';
      _designationCtrl.text = t.designation ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String v) {
    // Only auto-fill if the field is empty OR still shows the previously
    // auto-generated value (i.e. the user has not manually typed anything).
    final current = _shortNameCtrl.text;
    if (current.isEmpty || current == _lastAutoAbbr) {
      final generated = _autoAbbrFull(v);
      _shortNameCtrl.text = generated;
      _lastAutoAbbr = generated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_add_outlined,
                          color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existing == null
                                ? 'Add New User'
                                : 'Edit User',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            'Add a new member to your organization',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Full name
                _FieldLabel(label: 'Full Name', required: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  onChanged: _onNameChanged,
                  decoration: _inputDec(
                      hint: 'Enter full name', icon: Icons.person_outline),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Name is required';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Short name
                _FieldLabel(
                    label: 'Short Name',
                    required: true,
                    badge: 'Auto-generated'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _shortNameCtrl,
                  decoration:
                      _inputDec(hint: 'e.g., JD', icon: Icons.label_outline),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Short name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text('Used in timetable views',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),

                const SizedBox(height: 16),

                // Additional details toggle
                InkWell(
                  onTap: () =>
                      setState(() => _showAdditional = !_showAdditional),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Text('Additional Details',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Optional',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        ),
                        const Spacer(),
                        Icon(
                          _showAdditional
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdditional) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add email and role to invite this user to your organization workspace.',
                            style: TextStyle(
                                fontSize: 12, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel(label: 'Email Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDec(
                        hint: 'Enter email address',
                        icon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 4),
                  Text('Required for workspace access',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  const _FieldLabel(label: 'Role'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Member', 'Admin', 'Teacher', 'Staff']
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _role = v ?? _role),
                  ),
                  const SizedBox(height: 4),
                  Text('Required for workspace access',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  const _FieldLabel(label: 'Phone Number'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '+1',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDec(
                              hint: 'Enter phone number',
                              icon: Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel(label: 'Designation'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _designationCtrl,
                    decoration: _inputDec(
                        hint: 'e.g., Mathematics Teacher, Principal',
                        icon: Icons.badge_outlined),
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFDDE0E9)),
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add, size: 16),
                        label: const Text('Add User'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawName = _nameCtrl.text.trim();
    setState(() => _saving = true);
    final parts = rawName.split(' ');
    final first = parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final abbr = _shortNameCtrl.text.trim().isNotEmpty
        ? _shortNameCtrl.text.trim()
        : _autoAbbr(first, last);

    await widget.onSave(
      TeacherItem(
        id: widget.existing?.id,
        firstName: first,
        lastName: last,
        abbr: abbr,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        designation: _designationCtrl.text.trim().isEmpty
            ? null
            : _designationCtrl.text.trim(),
        maxGapsPerDay: widget.existing?.maxGapsPerDay,
        maxConsecutivePeriods: widget.existing?.maxConsecutivePeriods,
        timeOff: widget.existing?.timeOff,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  static InputDecoration _inputDec(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: Colors.grey),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    this.required = false,
    this.badge,
  });
  final String label;
  final bool required;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (required)
          const Text(' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(badge!,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ),
        ],
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.onBack, required this.onNext});
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF0F6), width: 1.5)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFDDE0E9)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auto-abbr helpers ─────────────────────────────────────────────────────────

String _autoAbbr(String first, String last) {
  final f = first.isNotEmpty ? first[0].toUpperCase() : '';
  final l = last.isNotEmpty ? last[0].toUpperCase() : '';
  return '$f$l'.isNotEmpty ? '$f$l' : first.substring(0, 1).toUpperCase();
}

String _autoAbbrFull(String fullName) {
  final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    return parts[0].substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

// ── Bulk Import Users Dialog ──────────────────────────────────────────────────

class _BulkImportUsersDialog extends StatefulWidget {
  const _BulkImportUsersDialog({required this.onImport});
  final Future<void> Function(List<TeacherItem> imported) onImport;

  @override
  State<_BulkImportUsersDialog> createState() => _BulkImportUsersDialogState();
}

class _BulkImportUsersDialogState extends State<_BulkImportUsersDialog> {
  bool _importing = false;
  String? _pickedFileName;
  List<List<dynamic>>? _csvData;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
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

      int nameIdx = headers.indexOf('name');
      int shortNameIdx = headers.indexOf('short name');
      int emailIdx = headers.indexOf('email');
      int phoneIdx = headers.indexOf('phone');
      int desigIdx = headers.indexOf('designation');

      if (nameIdx == -1) {
        // Fallback to assuming the exact format
        nameIdx = 0;
        shortNameIdx = 1;
        emailIdx = 2;
        phoneIdx = 3;
        desigIdx = 5;
      }

      final imported = <TeacherItem>[];

      // skip header if first row is headers
      bool isHeader(List<dynamic> row) {
        return row.length > nameIdx &&
            row[nameIdx].toString().trim().toLowerCase() == 'name';
      }

      int startIdx = isHeader(rows.first) ? 1 : 0;

      for (int i = startIdx; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length <= nameIdx) continue;

        final rawName = row[nameIdx].toString().trim();
        if (rawName.isEmpty) continue;

        final parts = rawName.split(' ');
        final first = parts.first;
        final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        String abbr = '';
        if (shortNameIdx != -1 && row.length > shortNameIdx) {
          abbr = row[shortNameIdx].toString().trim();
        }
        if (abbr.isEmpty) abbr = _autoAbbr(first, last);

        String? email;
        if (emailIdx != -1 && row.length > emailIdx) {
          email = row[emailIdx].toString().trim();
          if (email.isEmpty) email = null;
        }

        String? phone;
        if (phoneIdx != -1 && row.length > phoneIdx) {
          phone = row[phoneIdx].toString().trim();
          if (phone.isEmpty) phone = null;
        }

        String? desig;
        if (desigIdx != -1 && row.length > desigIdx) {
          desig = row[desigIdx].toString().trim();
          if (desig.isEmpty) desig = null;
        }

        imported.add(TeacherItem(
          firstName: first,
          lastName: last,
          abbr: abbr,
          email: email,
          phone: phone,
          designation: desig,
        ));
      }

      await widget.onImport(imported);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error importing users: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_upload_outlined,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bulk Import Users',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          'Import multiple users from CSV format',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Content ──────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // CSV Format info box
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.15)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('CSV Format',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Template download coming soon!')));
                                },
                                icon: const Icon(Icons.download, size: 14),
                                label: const Text('Template',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                                  minimumSize: const Size(0, 30),
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Import users using CSV format. Only Name is required, all other fields are optional.',
                            style: TextStyle(
                                fontSize: 12.5,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 12),

                          // Code block
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFDDE0E9)),
                            ),
                            child: const Text(
                              'Column Order:\nName, Short Name, Email, Phone, Role, Designation',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Chips / checklist
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _RequirementItem(
                                  label: 'Name', required: true, theme: theme),
                              _RequirementItem(
                                  label: 'Short Name',
                                  required: false,
                                  theme: theme),
                              _RequirementItem(
                                  label: 'Email',
                                  required: false,
                                  theme: theme),
                              _RequirementItem(
                                  label: 'Phone',
                                  required: false,
                                  theme: theme),
                              _RequirementItem(
                                  label: 'Role', required: false, theme: theme),
                              _RequirementItem(
                                  label: 'Designation',
                                  required: false,
                                  theme: theme),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Upload Drop Zone
                    CustomPaint(
                      painter: _DashedRectPainter(color: Colors.grey.shade400),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            Icon(Icons.insert_drive_file,
                                size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            if (_pickedFileName != null)
                              Text(_pickedFileName!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  textAlign: TextAlign.center)
                            else
                              Text('Upload a CSV file to import users',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600)),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('Choose CSV File'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFDDE0E9)),
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (_csvData == null || _importing)
                          ? null
                          : _processImport,
                      icon: _importing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload, size: 16),
                      label: const Text('Import Users'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem(
      {required this.label, required this.required, required this.theme});
  final String label;
  final bool required;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          required ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: required ? theme.colorScheme.primary : Colors.grey.shade400,
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary.withOpacity(0.8)),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: required ? 'Required' : 'Optional'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    // Top
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    // Right
    var startY = 0.0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY),
          Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    // Bottom
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height),
          Offset(startX - dashWidth, size.height), paint);
      startX -= (dashWidth + dashSpace);
    }
    // Left
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= (dashWidth + dashSpace);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Manage Availability Dialog ───────────────────────────────────────────────

class _ManageAvailabilityDialog extends StatefulWidget {
  const _ManageAvailabilityDialog({required this.teacher});
  final TeacherItem teacher;

  @override
  State<_ManageAvailabilityDialog> createState() =>
      _ManageAvailabilityDialogState();
}

class _ManageAvailabilityDialogState extends State<_ManageAvailabilityDialog> {
  late Map<String, TimeOffState> _timeOff;
  List<int> _days = [];
  List<Map<String, dynamic>> _periods = [];

  @override
  void initState() {
    super.initState();
    _timeOff = Map<String, TimeOffState>.from(widget.teacher.timeOff);
    _loadSchedule();
  }

  void _loadSchedule() {
    final planner = context.read<PlannerState>();
    _days = List.generate(planner.workingDays, (i) => i);
    _periods = planner.bellTimes.map((b) => {'time': b}).toList();
  }

  void _toggleCell(int day, int periodIndex) {
    setState(() {
      final key = '$day,$periodIndex';
      final current = _timeOff[key] ?? TimeOffState.available;
      if (current == TimeOffState.unavailable) {
        _timeOff.remove(key); // defaults to available
      } else {
        _timeOff[key] = TimeOffState.unavailable;
      }
    });
  }

  void _onSave() {
    final planner = context.read<PlannerState>();
    planner.updateTeacherConstraints(widget.teacher.id, timeOff: _timeOff);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offCount =
        _timeOff.values.where((v) => v == TimeOffState.unavailable).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Availability for ${widget.teacher.abbr}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                    left: BorderSide(color: Colors.blue.shade600, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Mark periods when '),
                              TextSpan(
                                  text: widget.teacher.abbr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const TextSpan(text: ' is '),
                              const TextSpan(
                                  text: 'not available',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const TextSpan(
                                  text:
                                      ' for scheduling. Click any cell to toggle availability.'),
                            ],
                          ),
                          style: TextStyle(
                              color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 28),
                      _legendChip(true),
                      const SizedBox(width: 12),
                      _legendChip(false),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grid
            if (_days.isEmpty || _periods.isEmpty)
              const Center(
                  child: Text(
                      "No schedule configured. Please set up Bell Schedule first.",
                      style: TextStyle(color: Colors.grey)))
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 500),
                      child: Table(
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.grey.shade300),
                        ),
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        children: [
                          // Header Row (Days)
                          TableRow(
                            decoration:
                                const BoxDecoration(color: Color(0xFFF8F9FB)),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Period/Day',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                              ..._days.map((d) {
                                const names = [
                                  'Sun',
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat'
                                ];
                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(names[d],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                );
                              }),
                            ],
                          ),
                          // Data Rows (Periods)
                          ...List.generate(_periods.length, (pIdx) {
                            final pMap = _periods[pIdx];
                            final timeStr = pMap['time'] as String;
                            final parts = timeStr.split('|');
                            final title = parts.length > 1
                                ? parts[0]
                                : 'Period ${pIdx + 1}';
                            final timeRange =
                                parts.length > 1 ? parts[1] : timeStr;

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      Text(timeRange,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                ..._days.map((d) {
                                  final isOff = _timeOff['$d,$pIdx'] ==
                                      TimeOffState.unavailable;
                                  return TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.fill,
                                    child: InkWell(
                                      onTap: () => _toggleCell(d, pIdx),
                                      child: Container(
                                        color: isOff
                                            ? const Color(0xFFFDECEE)
                                            : const Color(0xFFEBF7EE),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: isOff
                                                    ? Colors.white
                                                    : const Color(0xFF4CAF50),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isOff
                                                    ? Icons.close
                                                    : Icons.check,
                                                size: 14,
                                                color: isOff
                                                    ? const Color(0xFFD32F2F)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${_days.length} working days • ',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text('$offCount period${offCount == 1 ? '' : 's'} marked off',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFEBF7EE) : const Color(0xFFFDECEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAvailable ? Icons.check : Icons.close,
              size: 14,
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD32F2F)),
          const SizedBox(width: 4),
          Text(isAvailable ? 'Available' : 'Time Off',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
