import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database.dart';
import '../../core/theme/app_theme.dart';
import 'planner_state.dart';
import 'timetable_dashboard_screen.dart';

class MyTimetablesScreen extends StatefulWidget {
  const MyTimetablesScreen({super.key});

  @override
  State<MyTimetablesScreen> createState() => _MyTimetablesScreenState();
}

class _MyTimetablesScreenState extends State<MyTimetablesScreen> {
  final AppDatabase _db = AppDatabase();
  List<TimetableMeta> _timetables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimetables();
  }

  Future<void> _loadTimetables() async {
    setState(() => _isLoading = true);
    try {
      final list = await _db.loadAllTimetables();
      setState(() => _timetables = list);
    } catch (e) {
      debugPrint('Error loading timetables: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewTimetable() async {
    // Create an empty PlannerState, save it to get an ID, then navigate
    final planner = PlannerState(_db, dbId: 0);
    planner.draftName = 'New Timetable';
    planner.createdAt = DateTime.now();
    await planner.db!.savePlannerSnapshot(
      planner.toSolverPayload(), // Wait, toSolverPayload isn't what we save
      0,
    );
    // Actually wait, savePlannerSnapshot takes arbitrary JSON. If we just call _persist, it saves it.
  }

  void _openTimetable(int dbId) async {
    final p = PlannerState(_db, dbId: dbId);
    await p
        .refreshFromDatabase(); // CRITICAL: Await hydration before building dashboard

    if (!mounted) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<PlannerState>.value(
              value: p,
              child: const TimetableDashboardScreen(),
            ),
          ),
        )
        .then((_) => _loadTimetables()); // reload when coming back
  }

  Future<void> _duplicateTimetable(TimetableMeta meta) async {
    final existingData = await _db.loadPlannerSnapshot(meta.id);
    if (existingData == null) return;

    existingData['draftName'] = '${meta.name} (Copy)';
    existingData['createdAt'] = DateTime.now().toIso8601String();
    existingData['updatedAt'] = DateTime.now().toIso8601String();

    await _db.savePlannerSnapshot(existingData, 0); // 0 means insert new
    await _loadTimetables();
  }

  Future<void> _deleteTimetable(TimetableMeta meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Timetable?'),
        content: Text('Are you sure you want to delete "${meta.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteTimetable(meta.id);
        await _loadTimetables();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Cannot delete this timetable. It may be in use.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _renameTimetable(TimetableMeta meta) {
    final ctrl = TextEditingController(text: meta.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Timetable'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Timetable Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                final existingData = await _db.loadPlannerSnapshot(meta.id);
                if (existingData != null) {
                  existingData['draftName'] = newName;
                  await _db.savePlannerSnapshot(existingData, meta.id);
                }
              }
              if (mounted) Navigator.pop(ctx);
              _loadTimetables();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.motherSage,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drafts = _timetables.where((t) => t.status == 'draft').toList();
    final published =
        _timetables.where((t) => t.status == 'published').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, color: AppTheme.motherSage, size: 24),
            const SizedBox(width: 8),
            Text(
              'SmartTime AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.motherSage,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Timetables',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage all your timetables and track their status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final planner = PlannerState(_db, dbId: 0);
                        planner.draftName = 'New Timetable';
                        await planner.saveToDatabase();
                        _openTimetable(planner.dbId);
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'New Timetable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metric Cards
                  _buildMetricCard(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFE0E7FF),
                    iconColor: const Color(0xFF4F46E5),
                    title: 'Total Timetables',
                    value: _timetables.length.toString(),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    icon: Icons.check_circle_outline,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF22C55E),
                    title: 'Published',
                    value: published.length.toString(),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    icon: Icons.edit_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Drafts',
                    value: drafts.length.toString(),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                      'Published Timetables', published.length, Colors.green),
                  const SizedBox(height: 16),
                  if (published.isEmpty)
                    _buildEmptyPublishedState()
                  else
                    ...published.map((t) => _buildTimetableCard(t)),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                      'Draft Timetables', drafts.length, Colors.grey.shade600),
                  const SizedBox(height: 16),
                  ...drafts.map((t) => _buildTimetableCard(t)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color iconColor) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPublishedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF22C55E), size: 32),
          const SizedBox(height: 12),
          const Text(
            'No published timetables',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Publish a timetable to start using the substitute management system.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF166534).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableCard(TimetableMeta meta) {
    final initials = meta.name.isNotEmpty
        ? meta.name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    final df = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTimetable(meta.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  meta.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 12, color: Colors.grey.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      meta.status[0].toUpperCase() +
                                          meta.status.substring(1),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Updated: ${df.format(meta.updatedAt)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.insert_drive_file_outlined,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Created: ${df.format(meta.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final isPublished = meta.status == 'published';
                          final existingData =
                              await _db.loadPlannerSnapshot(meta.id);
                          if (existingData != null) {
                            existingData['status'] =
                                isPublished ? 'draft' : 'published';
                            await _db.savePlannerSnapshot(
                                existingData, meta.id);
                            await _loadTimetables();
                          }
                        },
                        icon: Icon(
                          meta.status == 'published'
                              ? Icons.unpublished_outlined
                              : Icons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          meta.status == 'published' ? 'Unpublish' : 'Publish',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: meta.status == 'published'
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'rename') _renameTimetable(meta);
                        if (val == 'duplicate') _duplicateTimetable(meta);
                        if (val == 'delete') _deleteTimetable(meta);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.black87),
                              SizedBox(width: 12),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18, color: Colors.black87),
                              SizedBox(width: 12),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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
}
