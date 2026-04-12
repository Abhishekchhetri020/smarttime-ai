import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/empty_state_placeholder.dart';
import '../planner_state.dart';
import '../time_off_picker.dart';

class ClassSetupScreen extends StatefulWidget {
  const ClassSetupScreen({super.key});

  @override
  State<ClassSetupScreen> createState() => _ClassSetupScreenState();
}

class _ClassSetupScreenState extends State<ClassSetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(context),
                const SizedBox(height: 24),
                const _ClassCard(),
                const SizedBox(height: 24),
                const _AvailableClassesSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.account_balance,
              color: Theme.of(context).colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grades & Divisions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Define grade levels (e.g., Grade 5) and their divisions (A, B, C)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Classes Card ─────────────────────────────────────────────────────────────

enum _ClassCol { name, shortName, classTeacher, color, availability, actions }

const _colLabels = {
  _ClassCol.name: 'NAME',
  _ClassCol.shortName: 'SHORT NAME',
  _ClassCol.classTeacher: 'CLASS TEACHER',
  _ClassCol.color: 'COLOR',
  _ClassCol.availability: 'AVAILABILITY',
  _ClassCol.actions: 'ACTIONS',
};

const _classEntityColors = [
  0xFF4F46E5,
  0xFF7C3AED,
  0xFFDB2777,
  0xFF059669,
  0xFFD97706,
  0xFFDC2626,
  0xFF0891B2,
  0xFF7C2D12,
  0xFF4F46E5,
  0xFF0D9488,
  0xFFBE185D,
  0xFF9333EA,
  0xFFEA580C,
  0xFF1D4ED8,
  0xFF16A34A,
  0xFF9F1239,
  0xFF0284C7,
  0xFF6D28D9,
  0xFFCA8A04,
  0xFF475569,
];

int _classAutoColor(int index) =>
    _classEntityColors[index % _classEntityColors.length];

String _classAutoAbbr(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1)
    return parts[0].length > 3
        ? parts[0].substring(0, 3).toUpperCase()
        : parts[0].toUpperCase();
  return parts.map((p) => p[0]).join().toUpperCase();
}

class _ClassCard extends StatefulWidget {
  const _ClassCard();

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  final _scrollController = ScrollController();
  final Set<_ClassCol> _visibleCols = _ClassCol.values.toSet();

  void _showColumnsSheet() {
    final planner = context.read<PlannerState>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return ChangeNotifierProvider<PlannerState>.value(
          value: planner,
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Show/Hide Columns',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      ..._ClassCol.values.map((col) {
                        return CheckboxListTile(
                          title: Text(_colLabels[col]!),
                          value: _visibleCols.contains(col),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                _visibleCols.add(col);
                              } else {
                                if (_visibleCols.length > 2) {
                                  _visibleCols.remove(col);
                                }
                              }
                            });
                            setState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final classes = planner.classes;

    if (classes.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.meeting_room_outlined,
        title: 'No Classes Added',
        message:
            'Add grades and divisions (e.g., Grade 9A, Grade 10B) to schedule lessons for them.',
      );
    }

    final cols =
        _ClassCol.values.where((c) => _visibleCols.contains(c)).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Classes (${classes.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                OutlinedButton.icon(
                  onPressed: _showColumnsSheet,
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('Columns'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable table
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 48 - 32),
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  headingRowColor:
                      MaterialStateProperty.all(Colors.grey.shade50),
                  columns: cols.map((c) {
                    final label = _colLabels[c]!;
                    Widget title = Text(label);
                    // Add info icon for Class Teacher
                    if (c == _ClassCol.name || c == _ClassCol.shortName) {
                      title = Row(
                        children: [
                          title,
                          const SizedBox(width: 4),
                          Icon(Icons.unfold_more,
                              size: 14, color: Colors.grey.shade400),
                        ],
                      );
                    }
                    return DataColumn(label: title);
                  }).toList(),
                  rows: classes.map((cls) {
                    return DataRow(
                      cells: cols.map((c) {
                        final val = _getColValue(cls, c);
                        return DataCell(
                          _ClassCell(
                            initialValue: val,
                            classItem: cls,
                            column: c,
                            onDeleteRow: () {
                              final p = context.read<PlannerState>();
                              p.removeClass(cls.id);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const Divider(height: 1),
          // Keyboard shortcuts legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keyboard shortcuts:',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    const _ShortcutItem(
                        keys: ['Enter'], desc: 'Edit / Save & move down'),
                    const _ShortcutItem(keys: ['Esc'], desc: 'Cancel editing'),
                    const _ShortcutItem(
                        keys: ['Tab'], desc: 'Save & move to next field'),
                    const _ShortcutItem(
                        keys: ['↑', '↓'], desc: 'Navigate up/down'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getColValue(ClassItem c, _ClassCol col) {
    switch (col) {
      case _ClassCol.name:
        return c.name;
      case _ClassCol.shortName:
        return c.abbr;
      case _ClassCol.color:
        return '';
      default:
        return '';
    }
  }
}

// ── Interactive Class Cell ───────────────────────────────────────────────────

class _ClassCell extends StatefulWidget {
  const _ClassCell({
    required this.initialValue,
    required this.classItem,
    required this.column,
    required this.onDeleteRow,
  });

  final String initialValue;
  final ClassItem classItem;
  final _ClassCol column;
  final VoidCallback onDeleteRow;

  @override
  State<_ClassCell> createState() => _ClassCellState();
}

class _ClassCellState extends State<_ClassCell> {
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
  void didUpdateWidget(_ClassCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.initialValue != _ctrl.text) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _commitAndExit() async {
    if (!mounted) return;
    final planner = context.read<PlannerState>();
    final val = _ctrl.text.trim();

    var updated = widget.classItem;

    if (widget.column == _ClassCol.name) {
      updated = updated.copyWith(
          name: val, abbr: updated.abbr == updated.name ? val : updated.abbr);
    } else if (widget.column == _ClassCol.shortName) {
      updated = updated.copyWith(abbr: val);
    }

    await planner.updateClass(updated);
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.column == _ClassCol.actions) {
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
            onPressed: widget.onDeleteRow,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    if (widget.column == _ClassCol.color) {
      final planner = context.read<PlannerState>();
      final idx = planner.classes.indexOf(widget.classItem);
      final colorVal = widget.classItem.color != null
          ? int.tryParse(widget.classItem.color!) ?? _classAutoColor(idx)
          : _classAutoColor(idx);
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

    if (widget.column == _ClassCol.classTeacher) {
      final planner = context.watch<PlannerState>();
      final assignedId = widget.classItem.classTeacherId;
      final assigned = assignedId != null
          ? planner.teachers
              .cast<TeacherItem?>()
              .firstWhere((t) => t?.id == assignedId, orElse: () => null)
          : null;

      final label = assigned?.fullName ?? 'Tap to assign';
      final isAssigned = assigned != null;

      return InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Select Class Teacher',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const SizedBox(height: 16),
                      if (planner.teachers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text('No faculty members available.',
                              style: TextStyle(color: Colors.grey)),
                        )
                      else ...[
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          leading:
                              const Icon(Icons.person_off, color: Colors.red),
                          title: const Text('None (Unassign)',
                              style: TextStyle(color: Colors.red)),
                          onTap: () {
                            planner.updateClass(widget.classItem
                                .copyWith(classTeacherId: null));
                            Navigator.pop(ctx);
                          },
                        ),
                        const Divider(),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: planner.teachers.length,
                            itemBuilder: (context, index) {
                              final t = planner.teachers[index];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Text(t.abbr,
                                      style: const TextStyle(fontSize: 12)),
                                ),
                                title: Text(t.fullName),
                                onTap: () {
                                  planner.updateClass(widget.classItem
                                      .copyWith(classTeacherId: t.id));
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isAssigned
                ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50)
                : Colors.grey.shade50,
            border: Border.all(
                color: isAssigned
                    ? Theme.of(context).colorScheme.primary.withAlpha(100)
                    : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isAssigned ? Icons.person : Icons.person_add_alt_1,
                  size: 14,
                  color: isAssigned
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isAssigned
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade500,
                  fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.column == _ClassCol.availability) {
      final offCount = widget.classItem.timeOff.values
          .where((v) => v == TimeOffState.unavailable)
          .length;
      return InkWell(
        onTap: () {
          final planner = context.read<PlannerState>();
          showDialog<void>(
            context: context,
            builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
              value: planner,
              child:
                  _ManageClassAvailabilityDialog(classItem: widget.classItem),
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
        width: 120,
        child: Focus(
          onKeyEvent: (node, event) {
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
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

    return InkWell(
      onTap: () {
        setState(() => _isEditing = true);
      },
      child: Container(
        width: 120,
        alignment: Alignment.centerLeft,
        child: Text(
          widget.initialValue.isEmpty ? '-' : widget.initialValue,
        ),
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
        Row(
            children: keys
                .map((k) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(k,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList()),
        const SizedBox(width: 4),
        Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ── Available Classes Section ────────────────────────────────────────────────

class _AvailableClassesSection extends StatefulWidget {
  const _AvailableClassesSection();

  @override
  State<_AvailableClassesSection> createState() =>
      _AvailableClassesSectionState();
}

class _AvailableClassesSectionState extends State<_AvailableClassesSection> {
  final _searchCtrl = TextEditingController();

  void _showAddClassSheet() {
    final planner = context.read<PlannerState>();
    final nameCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // Tracks the last auto-generated abbreviation so manual edits are preserved.
    String lastAutoAbbr = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add New Class',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Class name is required';
                    return null;
                  },
                  onChanged: (val) {
                    // Auto-fill only when user hasn't manually overridden it.
                    final currentAbbr = abbrCtrl.text;
                    if (currentAbbr.isEmpty || currentAbbr == lastAutoAbbr) {
                      final generated = _classAutoAbbr(val);
                      abbrCtrl.text = generated;
                      lastAutoAbbr = generated;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: abbrCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Short Name', border: OutlineInputBorder()),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Short name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await planner.addClass(ClassItem(
                        name: nameCtrl.text.trim(),
                        abbr: abbrCtrl.text.trim().isEmpty
                            ? nameCtrl.text.trim()
                            : abbrCtrl.text.trim()));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBulkImport() {
    final planner = context.read<PlannerState>();
    showDialog<void>(
        context: context,
        builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
              value: planner,
              child: _BulkImportClassesDialog(onImport: (items) async {
                for (var i in items) {
                  await planner.addClass(i);
                }
              }),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Classes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search classes...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showBulkImport,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Bulk Import'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: _showAddClassSheet,
                icon: const Icon(Icons.add_circle, size: 18),
                label: const Text('Add New Class'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Empty state for manual dummy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Center(
              child: Text(
                  "Use the search bar to locate additional items that can be imported to this schedule.",
                  style: TextStyle(color: Colors.grey))),
        ),
      ],
    );
  }
}

// ── Bulk Import Dialog ───────────────────────────────────────────────────────

class _BulkImportClassesDialog extends StatefulWidget {
  const _BulkImportClassesDialog({required this.onImport});
  final Future<void> Function(List<ClassItem>) onImport;

  @override
  State<_BulkImportClassesDialog> createState() =>
      _BulkImportClassesDialogState();
}

class _BulkImportClassesDialogState extends State<_BulkImportClassesDialog> {
  bool _importing = false;
  String? _pickedFileName;
  List<List<dynamic>>? _csvData;

  Future<void> _downloadSample() async {
    final csv = const ListToCsvConverter().convert([
      ['Class Name', 'Short Name', 'Class Teacher Name'],
      ['VI A', '6A', 'Mr. Ajay Khanna'],
      ['VI B', '6B', ''],
      ['VII A', '7A', 'Ms. Kiran Bhat'],
    ]);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/classes_import_template.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Classes Import Template');
  }

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
            .showSnackBar(SnackBar(content: Text('Failed to parse file: $e')));
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

      int nameIdx = headers.indexOf('class name');
      int shortIdx = headers.indexOf('short name');
      int teacherIdx = headers.indexOf('class teacher name');
      if (nameIdx == -1) {
        nameIdx = 0;
        shortIdx = 1;
        teacherIdx = 2;
      }

      final imported = <ClassItem>[];
      int startIdx = nameIdx != -1 ? 1 : 0;

      for (int i = startIdx; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length <= nameIdx) continue;
        final name = row[nameIdx].toString().trim();
        if (name.isEmpty) continue;

        String abbr = '';
        if (shortIdx != -1 && row.length > shortIdx) {
          abbr = row[shortIdx].toString().trim();
        }
        if (abbr.isEmpty) abbr = _classAutoAbbr(name);

        String? teacherName;
        if (teacherIdx != -1 && row.length > teacherIdx) {
          teacherName = row[teacherIdx].toString().trim();
          if (teacherName.isEmpty) teacherName = null;
        }

        // Try to find matching teacher
        String? classTeacherId;
        if (teacherName != null) {
          final planner = context.read<PlannerState>();
          for (final t in planner.teachers) {
            if (t.fullName.toLowerCase() == teacherName.toLowerCase()) {
              classTeacherId = t.id;
              break;
            }
          }
        }

        imported.add(ClassItem(
          name: name,
          abbr: abbr,
          classTeacherId: classTeacherId,
        ));
      }

      await widget.onImport(imported);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${imported.length} classes')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import error: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  int get _parsedCount {
    if (_csvData == null || _csvData!.length < 2) return 0;
    return _csvData!.length - 1;
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
                  const Text('Import Classes',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Import classes with names, short names, and class teachers',
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
                          'Class Name', ' (required) - Full name of the class'),
                      _bullet('Short Name',
                          ' (optional) - Abbreviation for display'),
                      _bullet('Class Teacher Name',
                          ' (optional) - Teacher name\n(must match existing teacher)'),
                    ],
                  )),
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
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _downloadSample,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download Sample'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40)),
                      )
                    ],
                  )),
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
                          const Icon(Icons.upload_file_outlined,
                              size: 18, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Text('Step 2: Upload Your File',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Select your CSV or Excel file with classes data.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label:
                            Text(_pickedFileName ?? 'Select CSV / Excel File'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40)),
                      ),
                      if (_pickedFileName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    '$_pickedFileName · $_parsedCount rows found',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.green))),
                          ],
                        ),
                      ],
                    ],
                  )),
              const SizedBox(height: 24),
              if (_pickedFileName == null)
                const Center(
                    child: Text('Select a CSV file to continue',
                        style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _parsedCount > 0 && !_importing
                          ? _processImport
                          : null,
                      child: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Import $_parsedCount Classes'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ));
  }

  Widget _bullet(String title, String desc) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            Expanded(
                child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900)),
              TextSpan(
                  text: desc, style: TextStyle(color: Colors.blue.shade800)),
            ]))),
          ],
        ));
  }
}

// ── Manage Availability Dialog ───────────────────────────────────────────────

class _ManageClassAvailabilityDialog extends StatefulWidget {
  const _ManageClassAvailabilityDialog({required this.classItem});
  final ClassItem classItem;

  @override
  State<_ManageClassAvailabilityDialog> createState() =>
      _ManageClassAvailabilityDialogState();
}

class _ManageClassAvailabilityDialogState
    extends State<_ManageClassAvailabilityDialog> {
  late Map<String, TimeOffState> _timeOff;
  List<int> _days = [];
  List<Map<String, dynamic>> _periods = [];

  @override
  void initState() {
    super.initState();
    _timeOff = Map<String, TimeOffState>.from(widget.classItem.timeOff);
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
    planner.updateClassConstraints(widget.classItem.id, timeOff: _timeOff);
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
                  'Manage Availability for ${widget.classItem.abbr}',
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
                                  text: widget.classItem.abbr,
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
                      constraints: const BoxConstraints(minWidth: 500),
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
