import 'package:flutter/material.dart';

import '../../../../core/database.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet for filtering unscheduled lessons by Classes, Teachers,
/// Subjects, or Rooms — matching the reference app's 4-tab filter modal.
class FilterUnscheduledSheet extends StatefulWidget {
  const FilterUnscheduledSheet({
    super.key,
    required this.classes,
    required this.teachers,
    required this.subjects,
    required this.rooms,
    required this.selectedClassIds,
    required this.selectedTeacherIds,
    required this.selectedSubjectIds,
    required this.selectedRoomIds,
  });

  final List<ClassRow> classes;
  final List<TeacherRow> teachers;
  final List<SubjectRow> subjects;
  final List<Map<String, dynamic>> rooms;
  final Set<String> selectedClassIds;
  final Set<String> selectedTeacherIds;
  final Set<String> selectedSubjectIds;
  final Set<String> selectedRoomIds;

  static Future<_FilterResult?> show(
    BuildContext context, {
    required List<ClassRow> classes,
    required List<TeacherRow> teachers,
    required List<SubjectRow> subjects,
    required List<Map<String, dynamic>> rooms,
    required Set<String> selectedClassIds,
    required Set<String> selectedTeacherIds,
    required Set<String> selectedSubjectIds,
    required Set<String> selectedRoomIds,
  }) {
    return showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: FilterUnscheduledSheet(
          classes: classes,
          teachers: teachers,
          subjects: subjects,
          rooms: rooms,
          selectedClassIds: selectedClassIds,
          selectedTeacherIds: selectedTeacherIds,
          selectedSubjectIds: selectedSubjectIds,
          selectedRoomIds: selectedRoomIds,
        ),
      ),
    );
  }

  @override
  State<FilterUnscheduledSheet> createState() => _FilterUnscheduledSheetState();
}

class _FilterResult {
  final Set<String> classIds;
  final Set<String> teacherIds;
  final Set<String> subjectIds;
  final Set<String> roomIds;
  const _FilterResult({
    required this.classIds,
    required this.teacherIds,
    required this.subjectIds,
    required this.roomIds,
  });
}

class _FilterUnscheduledSheetState extends State<FilterUnscheduledSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Set<String> _classIds;
  late final Set<String> _teacherIds;
  late final Set<String> _subjectIds;
  late final Set<String> _roomIds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _classIds = Set.of(widget.selectedClassIds);
    _teacherIds = Set.of(widget.selectedTeacherIds);
    _subjectIds = Set.of(widget.selectedSubjectIds);
    _roomIds = Set.of(widget.selectedRoomIds);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _classIds.clear();
      _teacherIds.clear();
      _subjectIds.clear();
      _roomIds.clear();
    });
  }

  void _done() {
    Navigator.pop(
      context,
      _FilterResult(
        classIds: _classIds,
        teacherIds: _teacherIds,
        subjectIds: _subjectIds,
        roomIds: _roomIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 22, color: AppTheme.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Filter Unscheduled Lessons',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.indigo,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.indigo,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded, size: 18), text: 'Classes'),
            Tab(
                icon: Icon(Icons.people_alt_outlined, size: 18),
                text: 'Teachers'),
            Tab(
                icon: Icon(Icons.menu_book_outlined, size: 18),
                text: 'Subjects'),
            Tab(
                icon: Icon(Icons.meeting_room_outlined, size: 18),
                text: 'Rooms'),
          ],
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CheckboxList(
                items: widget.classes
                    .map((c) => _CheckItem(
                        id: c.id, label: c.abbr.isNotEmpty ? c.abbr : c.name))
                    .toList(),
                selectedIds: _classIds,
                onChanged: () => setState(() {}),
                emptyMessage: 'No classes available',
              ),
              _CheckboxList(
                items: widget.teachers
                    .map((t) => _CheckItem(id: t.id, label: t.name))
                    .toList(),
                selectedIds: _teacherIds,
                onChanged: () => setState(() {}),
                emptyMessage: 'No teachers available',
              ),
              _CheckboxList(
                items: widget.subjects
                    .map((s) => _CheckItem(
                        id: s.id, label: s.abbr.isNotEmpty ? s.abbr : s.name))
                    .toList(),
                selectedIds: _subjectIds,
                onChanged: () => setState(() {}),
                emptyMessage: 'No subjects available',
              ),
              _CheckboxList(
                items: widget.rooms
                    .map((r) => _CheckItem(
                        id: r['id'] as String? ?? '',
                        label:
                            r['name'] as String? ?? r['id'] as String? ?? ''))
                    .toList(),
                selectedIds: _roomIds,
                onChanged: () => setState(() {}),
                emptyMessage: 'No rooms available',
              ),
            ],
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 0.8)),
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: _clearAll,
                child: Text('Clear all filters',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _done,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.indigo,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckItem {
  final String id;
  final String label;
  const _CheckItem({required this.id, required this.label});
}

class _CheckboxList extends StatelessWidget {
  const _CheckboxList({
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    required this.emptyMessage,
  });
  final List<_CheckItem> items;
  final Set<String> selectedIds;
  final VoidCallback onChanged;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child:
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    final allSelected = items.every((item) => selectedIds.contains(item.id));
    return ListView(
      children: [
        CheckboxListTile(
          title: const Text('Select All',
              style: TextStyle(fontWeight: FontWeight.w600)),
          value: allSelected,
          onChanged: (v) {
            if (v == true) {
              selectedIds.addAll(items.map((e) => e.id));
            } else {
              for (final item in items) {
                selectedIds.remove(item.id);
              }
            }
            onChanged();
          },
        ),
        const Divider(height: 1),
        for (final item in items)
          CheckboxListTile(
            title: Text(item.label),
            value: selectedIds.contains(item.id),
            onChanged: (v) {
              if (v == true) {
                selectedIds.add(item.id);
              } else {
                selectedIds.remove(item.id);
              }
              onChanged();
            },
          ),
      ],
    );
  }
}
