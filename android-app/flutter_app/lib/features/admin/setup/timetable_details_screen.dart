import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class TimetableDetailsScreen extends StatefulWidget {
  const TimetableDetailsScreen({super.key});

  @override
  State<TimetableDetailsScreen> createState() => _TimetableDetailsScreenState();
}

class _TimetableDetailsScreenState extends State<TimetableDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _descriptionCtrl;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final planner = context.read<PlannerState>();
    _nameCtrl = TextEditingController(text: planner.sessionName);
    _schoolNameCtrl = TextEditingController(text: planner.schoolName);
    _descriptionCtrl = TextEditingController();
    if (planner.sessionStartDate != null) {
      _startDate = DateTime.tryParse(planner.sessionStartDate!);
    }
    if (planner.sessionEndDate != null) {
      _endDate = DateTime.tryParse(planner.sessionEndDate!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial =
        isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final planner = context.read<PlannerState>();

    // Save school name
    if (_schoolNameCtrl.text.trim().isNotEmpty) {
      planner.setSchoolName(_schoolNameCtrl.text.trim());
    }

    // Save session details
    planner.setSessionDetails(
      name: _nameCtrl.text.trim(),
      start: _startDate?.toIso8601String(),
      end: _endDate?.toIso8601String(),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Timetable Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ─── School Name Section ──────────────────────────────────────
            Row(
              children: [
                Icon(Icons.school_outlined,
                    color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'School Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'This name will appear on all exported timetables (PDF, Word, Excel).',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'School Name *',
                hintText: 'e.g., Springfield High School',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.apartment),
                helperText: 'Appears on the header of exported reports',
                helperStyle: TextStyle(color: Colors.grey.shade500),
              ),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'School name is required'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),

            // ─── Timetable Information ────────────────────────────────────
            Row(
              children: [
                Icon(Icons.table_chart_outlined,
                    color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Timetable Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Timetable Name *',
                hintText: 'e.g., Full_Demo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_view_week),
              ),
              maxLength: 100,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Please enter a timetable/session name'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText:
                    'Add any additional notes or context about this timetable...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ─── Academic Session ─────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.event_outlined,
                    color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Academic Session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Optional)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                    left: BorderSide(color: Colors.blue.shade400, width: 3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade400, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Academic session details are optional. If you choose to fill these, all three fields (name, start date, end date) should be completed for proper tracking.',
                      style: TextStyle(
                          color: Colors.blue, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'e.g., 2024-2025, Fall 2024, Term 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bookmark_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateCard(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // ─── Bottom Save / Next bar ─────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Save', style: TextStyle(fontSize: 16)),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaceholder = date == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isPlaceholder
              ? Colors.grey.shade50
              : theme.colorScheme.primaryContainer.withAlpha(30),
          border: Border.all(
            color: isPlaceholder
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.primary.withAlpha(100),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isPlaceholder
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isPlaceholder
                      ? 'Select Date'
                      : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPlaceholder
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isPlaceholder ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
