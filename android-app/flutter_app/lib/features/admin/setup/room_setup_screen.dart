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

enum _RoomCol { name, shortName, group, assignedTo, availability, actions }

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  String _searchQuery = '';
  final Set<_RoomCol> _hiddenCols = {};

  List<_RoomCol> get _visibleCols =>
      _RoomCol.values.where((c) => !_hiddenCols.contains(c)).toList();

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final rooms = planner.classrooms.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(q) ||
          r.type.toLowerCase().contains(q) ||
          r.abbr.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'Buildings & Rooms',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage rooms assigned to this timetable from your organization resources',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                          left: BorderSide(
                              color: Colors.blue.shade400, width: 4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade400, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Rooms are optional. Only add shared facilities (labs, computer rooms, libraries) that need to be scheduled across multiple classes. Classrooms permanently assigned to specific grades don\'t need to be added.',
                            style: TextStyle(color: Colors.blue, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Rooms (${planner.classrooms.length})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.storefront, size: 18),
                        label: const Text('Building Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(50)),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Columns'),
                        onPressed: () => _showColumnsMenu(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (planner.classrooms.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(Colors.grey.shade50),
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 56,
                              horizontalMargin: 16,
                              columnSpacing: 24,
                              columns: _visibleCols.map((c) {
                                return DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _colName(c),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (c == _RoomCol.name ||
                                          c == _RoomCol.shortName) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.unfold_more,
                                            size: 14,
                                            color: Colors.grey.shade400),
                                      ],
                                      if (c == _RoomCol.group) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.info_outline,
                                            size: 14,
                                            color: Colors.grey.shade400),
                                      ]
                                    ],
                                  ),
                                );
                              }).toList(),
                              rows: planner.classrooms.map((room) {
                                return DataRow(
                                  cells: _visibleCols.map((c) {
                                    return DataCell(_RoomCell(
                                      room: room,
                                      column: c,
                                      onDeleteRow: () => setState(() =>
                                          planner.classrooms.remove(room)),
                                    ));
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (planner.classrooms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildShortcutsLegend(),
                  ],
                  const SizedBox(height: 32),
                  const Text('Available Rooms',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search rooms...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showAddRoomDialog(context),
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Add New Room'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (rooms.isEmpty) ...[
                    const SizedBox(height: 24),
                    EmptyStatePlaceholder(
                      icon: Icons.domain,
                      title: 'No Rooms Added',
                      message:
                          'Rooms are optional. Only add shared facilities (labs, computer rooms, libraries) that need to be scheduled across multiple classes.',
                      actionLabel: 'Add New Room',
                      onAction: () => _showAddRoomDialog(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColumnsMenu(BuildContext context) {
    final planner = context.read<PlannerState>();
    showDialog(
      context: context,
      builder: (ctx) {
        return ChangeNotifierProvider<PlannerState>.value(
          value: planner,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Show/Hide Columns',
                    style: TextStyle(fontSize: 16)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _RoomCol.values.map((col) {
                    final isReq = col == _RoomCol.name ||
                        col == _RoomCol.shortName ||
                        col == _RoomCol.actions;
                    final isHidden = _hiddenCols.contains(col);
                    return CheckboxListTile(
                      value: !isHidden,
                      onChanged: isReq
                          ? null
                          : (val) {
                              setDialogState(() {
                                if (val == true) {
                                  _hiddenCols.remove(col);
                                } else {
                                  _hiddenCols.add(col);
                                }
                              });
                              setState(() {});
                            },
                      title: Row(
                        children: [
                          Icon(
                              isHidden ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                              color: isHidden
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(_colName(col),
                              style: TextStyle(
                                  color: isHidden ? Colors.grey : null)),
                          if (isReq) ...[
                            const SizedBox(width: 8),
                            Text('(Required)',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12)),
                          ]
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _colName(_RoomCol c) {
    switch (c) {
      case _RoomCol.name:
        return 'ROOM NAME';
      case _RoomCol.shortName:
        return 'SHORT NAME';
      case _RoomCol.group:
        return 'GROUP';
      case _RoomCol.assignedTo:
        return 'ASSIGNED TO';
      case _RoomCol.availability:
        return 'AVAILABILITY';
      case _RoomCol.actions:
        return 'ACTIONS';
    }
  }

  Widget _buildShortcutsLegend() {
    Widget keyBadge(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        );

    Widget shortcutItem(String key, String desc) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            keyBadge(key),
            const SizedBox(width: 6),
            Text(desc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Keyboard shortcuts:',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            shortcutItem('Enter', 'Edit / Save & move down'),
            shortcutItem('Tab', 'Save & move to next field'),
            shortcutItem('Esc', 'Cancel editing'),
            shortcutItem('↑↓', 'Navigate up/down'),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddRoomDialog(BuildContext context) async {
    final planner = context.read<PlannerState>();
    final nameCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    final buildingCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    bool showOptional = false;

    await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Room'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create a new room resource',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Room Name *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Room 101, Lab A',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Room name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: abbrCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Short Name',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., R101, LA',
                            helperText:
                                'Used for compact display in timetables',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Short name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => setDialogState(
                              () => showOptional = !showOptional),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                    showOptional
                                        ? Icons.keyboard_arrow_down
                                        : Icons.keyboard_arrow_right,
                                    color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                    showOptional
                                        ? 'Hide Optional Settings'
                                        : 'Show Optional Settings',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        if (showOptional) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: buildingCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Building Name (Optional)',
                                    hintText: 'e.g., Main Building',
                                    helperText:
                                        'Organize rooms by building location',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: capacityCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Capacity (Optional)',
                                    helperText: 'Maximum number of students',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    planner.addClassroom(ClassroomItem(
                      name: nameCtrl.text.trim(),
                      abbr: abbrCtrl.text.trim().isNotEmpty
                          ? abbrCtrl.text.trim()
                          : null,
                      buildingName: buildingCtrl.text.trim().isNotEmpty
                          ? buildingCtrl.text.trim()
                          : null,
                      capacity: int.tryParse(capacityCtrl.text.trim()),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create Room'),
                ),
              ],
            );
          },
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
        child: _BulkImportRoomsDialog(
          onImport: (rooms) async {
            for (final r in rooms) {
              planner.addClassroom(r);
            }
          },
        ),
      ),
    );
  }
}

class _RoomCell extends StatefulWidget {
  final ClassroomItem room;
  final _RoomCol column;
  final VoidCallback onDeleteRow;

  const _RoomCell(
      {required this.room, required this.column, required this.onDeleteRow});

  @override
  State<_RoomCell> createState() => _RoomCellState();
}

class _RoomCellState extends State<_RoomCell> {
  bool _isEditing = false;
  late TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initText();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitAndExit();
      }
    });
  }

  void _initText() {
    final text =
        widget.column == _RoomCol.name ? widget.room.name : widget.room.abbr;
    _ctrl = TextEditingController(text: text);
  }

  @override
  void didUpdateWidget(covariant _RoomCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) _initText();
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

    var updated = widget.room;
    if (widget.column == _RoomCol.name && val.isNotEmpty) {
      updated = updated.copyWith(
          name: val,
          abbr: updated.abbr == widget.room.name ? val : updated.abbr);
    } else if (widget.column == _RoomCol.shortName && val.isNotEmpty) {
      updated = updated.copyWith(abbr: val);
    }

    await planner.updateRoom(updated);
    if (mounted) setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.column == _RoomCol.actions) {
      return IconButton(
        icon: const Icon(Icons.remove_circle_outline, size: 18),
        color: Colors.grey.shade400,
        onPressed: widget.onDeleteRow,
      );
    }

    if (widget.column == _RoomCol.group) {
      final hasGroup =
          widget.room.groupId != null && widget.room.groupId!.isNotEmpty;
      return TextButton.icon(
        icon: Icon(hasGroup ? Icons.tag : Icons.add_circle_outline, size: 14),
        label: Text(hasGroup ? widget.room.groupId! : 'Add to group',
            style: TextStyle(color: hasGroup ? Colors.black87 : null)),
        onPressed: () => _showGroupDialog(context),
      );
    }

    if (widget.column == _RoomCol.assignedTo) {
      final tCount = widget.room.assignedTeacherIds.length;
      final cCount = widget.room.assignedClassIds.length;
      final total = tCount + cCount;

      return TextButton.icon(
        icon:
            Icon(total > 0 ? Icons.people : Icons.add_circle_outline, size: 14),
        label: Text(total > 0 ? '$total entities' : 'Assign to entities',
            style: TextStyle(color: total > 0 ? Colors.black87 : null)),
        onPressed: () => _showAssignEntitiesDialog(context),
      );
    }

    if (widget.column == _RoomCol.availability) {
      // Not implemented in Phase 12 mockups yet, placeholder styling
      return InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 12, color: Colors.green.shade700),
            ],
          ),
        ),
      );
    }

    // Editable text columns
    if (_isEditing) {
      return KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              setState(() {
                _initText();
                _isEditing = false;
              });
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              _commitAndExit();
            }
          }
        },
        child: SizedBox(
          width: widget.column == _RoomCol.name ? 200 : 120,
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _isEditing = true);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _focusNode.requestFocus();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        width: widget.column == _RoomCol.name ? 200 : 120,
        alignment: Alignment.centerLeft,
        child: Text(
          widget.column == _RoomCol.name ? widget.room.name : widget.room.abbr,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _showGroupDialog(BuildContext context) async {
    final planner = context.read<PlannerState>();
    final ctrl = TextEditingController(text: widget.room.groupId ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Add to Group'),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a group for ${widget.room.name}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              const Text(
                  'Rooms in the same group can be used interchangeably by the scheduler.',
                  style: TextStyle(fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Create New Group',
                  hintText: 'Enter group name...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                if (widget.room.groupId != null) ...[
                  TextButton(
                    onPressed: () {
                      planner.updateRoom(widget.room.copyWith(groupId: null));
                      Navigator.pop(ctx);
                    },
                    child:
                        const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final val = ctrl.text.trim();
                    planner.updateRoom(widget.room
                        .copyWith(groupId: val.isEmpty ? null : val));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignEntitiesDialog(BuildContext context) async {
    final planner = context.read<PlannerState>();
    final selTeachers = Set<String>.from(widget.room.assignedTeacherIds);
    final selClasses = Set<String>.from(widget.room.assignedClassIds);

    await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider<PlannerState>.value(
        value: planner,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => DefaultTabController(
            length: 2,
            child: AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.business,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fix Room For',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(widget.room.name,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: const Text(
                        'Select teachers or classes that should always use this room. All lessons involving the selected entities will be automatically assigned to this room.',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                    const TabBar(
                      tabs: [
                        Tab(
                            icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Icon(Icons.people),
                              SizedBox(width: 8),
                              Text('Teachers')
                            ])),
                        Tab(
                            icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Icon(Icons.school),
                              SizedBox(width: 8),
                              Text('Classes')
                            ])),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildEntityList(
                            items: planner.teachers
                                .map((t) => _Ent(t.id, t.fullName, t.abbr))
                                .toList(),
                            selectedIds: selTeachers,
                            onToggle: (id) => setDialogState(() {
                              selTeachers.contains(id)
                                  ? selTeachers.remove(id)
                                  : selTeachers.add(id);
                            }),
                          ),
                          _buildEntityList(
                            items: planner.classes
                                .map((c) => _Ent(c.id, c.name, c.abbr))
                                .toList(),
                            selectedIds: selClasses,
                            onToggle: (id) => setDialogState(() {
                              selClasses.contains(id)
                                  ? selClasses.remove(id)
                                  : selClasses.add(id);
                            }),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.all(16),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    planner.updateRoom(widget.room.copyWith(
                      assignedTeacherIds: selTeachers.toList(),
                      assignedClassIds: selClasses.toList(),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntityList(
      {required List<_Ent> items,
      required Set<String> selectedIds,
      required void Function(String) onToggle}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Select multiple',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {},
                child: const Text('Clear',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final isSel = selectedIds.contains(item.id);
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(item.abbr, style: const TextStyle(fontSize: 10)),
                ),
                title: Text(item.name),
                subtitle: Text(item.abbr),
                trailing: Icon(
                    isSel ? Icons.check_circle : Icons.circle_outlined,
                    color: isSel ? Colors.blue : Colors.grey),
                onTap: () => onToggle(item.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Ent {
  final String id, name, abbr;
  _Ent(this.id, this.name, this.abbr);
}

// ── Bulk Import Dialog ───────────────────────────────────────────────────────

class _BulkImportRoomsDialog extends StatefulWidget {
  const _BulkImportRoomsDialog({required this.onImport});
  final Future<void> Function(List<ClassroomItem>) onImport;

  @override
  State<_BulkImportRoomsDialog> createState() => _BulkImportRoomsDialogState();
}

class _BulkImportRoomsDialogState extends State<_BulkImportRoomsDialog> {
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

      int nameIdx = headers.indexOf('room name');
      int shortNameIdx = headers.indexOf('short name');
      int groupNameIdx = headers.indexOf('room group name');

      if (nameIdx == -1) {
        // Fallback to absolute columns if headers are missing
        nameIdx = 0;
        shortNameIdx = 1;
        groupNameIdx = 2;
      }

      final imported = <ClassroomItem>[];

      bool isHeader(List<dynamic> row) {
        if (row.isEmpty) return false;
        final firstItem = row[nameIdx].toString().trim().toLowerCase();
        return firstItem == 'room name';
      }

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || (i == 0 && isHeader(row))) continue;

        String name = '';
        if (nameIdx >= 0 && nameIdx < row.length) {
          name = row[nameIdx].toString().trim();
        }
        if (name.isEmpty) continue; // required field

        String abbr = '';
        if (shortNameIdx >= 0 && shortNameIdx < row.length) {
          abbr = row[shortNameIdx].toString().trim();
        }

        String groupName = '';
        if (groupNameIdx >= 0 && groupNameIdx < row.length) {
          groupName = row[groupNameIdx].toString().trim();
        }

        imported.add(ClassroomItem(
          name: name,
          abbr: abbr.isNotEmpty ? abbr : null,
          groupId: groupName.isNotEmpty ? groupName : null,
        ));
      }

      await widget.onImport(imported);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${imported.length} rooms')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error computing import: $e')));
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
        ['Room Name', 'Short Name', 'Room Group Name'],
        ['Science Lab 1', 'Sci-1', 'Science Labs'],
        ['Computer Lab A', 'Comp-A', 'Computer Labs'],
        ['Library', 'Lib', ''],
      ]);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/rooms_import_template.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Rooms Import Template',
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
    final planner = context.watch<PlannerState>();
    final Set<String> roomGroups = planner.classrooms
        .where((r) => r.groupId != null && r.groupId!.isNotEmpty)
        .map((r) => r.groupId!)
        .toSet();

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
                const Text('Import Rooms',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Import rooms with Name, Short Name, Room Group Name',
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
                  _bullet('Room Name', ' (required) - Full name of the room'),
                  _bullet(
                      'Short Name', ' (optional) - Abbreviation for display'),
                  _bullet('Room Group Name',
                      ' (optional) - Group name (e.g.,\n"Science Labs", "Computer Labs")'),
                ],
              ),
            ),
            if (roomGroups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.purple.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Existing Room Groups',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.purple.shade700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: roomGroups
                          .map((g) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(g,
                                    style: TextStyle(
                                        color: Colors.purple.shade900,
                                        fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
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
                  Text('Select your CSV file with rooms data.',
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
                    : 'Found ${(_csvData!.length > 1 ? _csvData!.length - 1 : 0)} entries to import (assuming header)',
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
                            'Import ${_csvData == null ? 0 : (_csvData!.length > 1 ? _csvData!.length - 1 : 0)} Rooms'),
                  ),
                ),
              ],
            )
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
