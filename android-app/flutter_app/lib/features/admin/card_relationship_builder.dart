import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../core/theme/app_theme.dart';
import 'planner_state.dart';

class CardRelationshipBuilder extends StatefulWidget {
  const CardRelationshipBuilder({super.key, this.existingRule});

  final CardRelationship? existingRule;

  @override
  State<CardRelationshipBuilder> createState() => _CardRelationshipBuilderState();
}

class _CardRelationshipBuilderState extends State<CardRelationshipBuilder> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  List<String> _selectedSubjectIds = [];
  List<String> _selectedClassIds = [];
  
  String _selectedCondition = 'Card distribution over the week';
  String _selectedImportance = 'Strict';
  bool _isActive = true;

  final List<String> _conditions = [
    // ── Reference app conditions ──
    'cannot follow',
    'cannot be the same day',
    'Card distribution over the week',
    'Two subjects must follow (In arbitrary order)',
    'Two subjects must follow',
    'Break cannot be between group of lessons',
    'Two subjects must be in one day (In arbitrary order)',
    'Two subjects must be in one day (In specified order)',
    'Group of cards from different classes must be in one day',
    'Divided cards from one subject must be on one day',
    'These subjects for the groups of listed classes must start at the same time',
    'The selected subjects have to be at the same time in all selected classes',
    'This subject must be on the same period each day',
    'Reserve space for selected subjects',
    'Subject must be first or last',
    'The selected subjects can be in the afternoon (outside teaching block)',
    // ── SmartTime-specific conditions (solver-wired) ──
    'Max consecutive periods = 2',
    'Max consecutive periods = 3',
    'Max gaps per day = 0',
    'Max gaps per day = 1',
    'Min gaps between subjects = 1',
    'Min gaps between subjects = 2',
    'Cards cannot overlap',
    'Must be on different days',
    'Specific days only',
  ];

  final List<String> _importances = [
    'Low',
    'Normal',
    'High',
    'Strict',
    'Optimize',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      final rule = widget.existingRule!;
      _selectedSubjectIds = List.from(rule.subjectIds);
      _selectedClassIds = List.from(rule.classIds);
      _selectedCondition = rule.condition;
      _selectedImportance = rule.importance;
      _noteController.text = rule.note;
      _isActive = rule.isActive;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveRule() {
    if (!_formKey.currentState!.validate()) return;
    
    final planner = context.read<PlannerState>();
    
    final rule = CardRelationship(
      id: widget.existingRule?.id ?? 'CR_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      subjectIds: _selectedSubjectIds,
      classIds: _selectedClassIds,
      condition: _selectedCondition,
      importance: _selectedImportance,
      note: _noteController.text.trim(),
      isActive: _isActive,
    );
    
    if (widget.existingRule != null) {
      planner.updateCardRelationship(rule);
    } else {
      planner.addCardRelationship(rule);
    }
    
    Navigator.pop(context);
  }

  Future<void> _openSubjectsSheet() async {
    final planner = context.read<PlannerState>();
    final result = await _showMultiSelectSheet(
      context: context,
      title: 'Select Subjects',
      items: planner.subjects.map((s) => _MultiSelectItem(id: s.id, label: s.name, color: s.color)).toList(),
      initialSelection: _selectedSubjectIds,
    );
    
    if (result != null) {
      setState(() => _selectedSubjectIds = result);
    }
  }

  Future<void> _openClassesSheet() async {
    final planner = context.read<PlannerState>();
    final result = await _showMultiSelectSheet(
      context: context,
      title: 'Select Classes',
      items: planner.classes.map((c) => _MultiSelectItem(id: c.id, label: c.name, color: c.color)).toList(),
      initialSelection: _selectedClassIds,
      allowSelectAll: true,
    );
    
    if (result != null) {
      setState(() => _selectedClassIds = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existingRule != null ? 'Edit Rule' : 'New Rule'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.existingRule != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                context.read<PlannerState>().removeCardRelationship(widget.existingRule!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Active Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rule Active Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: AppTheme.motherSage,
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Subjects Selector
            _buildSectionHeader('Apply to Subjects'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _openSubjectsSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedSubjectIds.isEmpty
                            ? 'Select specific subjects (optional)'
                            : '\${_selectedSubjectIds.length} Subjects Selected',
                        style: TextStyle(
                          color: _selectedSubjectIds.isEmpty ? Colors.grey.shade500 : const Color(0xFF1E293B),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Classes Selector
            _buildSectionHeader('Apply to Classes'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _openClassesSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedClassIds.isEmpty
                            ? 'Select specific classes (optional)'
                            : '\${_selectedClassIds.length} Classes Selected',
                        style: TextStyle(
                          color: _selectedClassIds.isEmpty ? Colors.grey.shade500 : const Color(0xFF1E293B),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Condition Dropdown
            _buildSectionHeader('Rule Condition'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCondition = val);
              },
            ),
            const SizedBox(height: 24),
            
            // Importance Dropdown
            _buildSectionHeader('Importance Level'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedImportance,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _importances.map((i) {
                return DropdownMenuItem(
                  value: i,
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: _getImportanceColor(i)),
                      const SizedBox(width: 8),
                      Text(i),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedImportance = val);
              },
            ),
            const SizedBox(height: 24),
            
            // Note Field
            _buildSectionHeader('Note / Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'e.g. Science classes must be consecutive',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saveRule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.motherSage,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Save Rule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
    );
  }

  Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'low': return Colors.green;
      case 'normal': return Colors.blue;
      case 'high': return Colors.orange;
      case 'strict': return Colors.red;
      case 'optimize': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _MultiSelectItem {
  final String id;
  final String label;
  final dynamic color;
  _MultiSelectItem({required this.id, required this.label, this.color});
}

Future<List<String>?> _showMultiSelectSheet({
  required BuildContext context,
  required String title,
  required List<_MultiSelectItem> items,
  required List<String> initialSelection,
  bool allowSelectAll = false,
}) {
  List<String> currentSelection = List.from(initialSelection);

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateSheet) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                if (allowSelectAll) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setStateSheet(() {
                              currentSelection = items.map((e) => e.id).toList();
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateSheet(() {
                              currentSelection.clear();
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = currentSelection.contains(item.id);
                      final cColor = item.color != null ? Color(item.color!) : null;
                      
                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: AppTheme.motherSage,
                        title: Row(
                          children: [
                            if (cColor != null) ...[
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: cColor, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                            ],
                            Text(item.label),
                          ],
                        ),
                        onChanged: (val) {
                          setStateSheet(() {
                            if (val == true) {
                              currentSelection.add(item.id);
                            } else {
                              currentSelection.remove(item.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, currentSelection),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.motherSage,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
