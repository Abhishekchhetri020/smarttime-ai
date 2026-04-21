import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'planner_state.dart';
import 'card_relationship_builder.dart';

class CardRelationshipsScreen extends StatefulWidget {
  const CardRelationshipsScreen({super.key});

  @override
  State<CardRelationshipsScreen> createState() =>
      _CardRelationshipsScreenState();
}

class _CardRelationshipsScreenState extends State<CardRelationshipsScreen> {
  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final rules = planner.cardRelationships;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Card Relationships'),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Global Constraints',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage relationships and constraints between subjects and classes.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<PlannerState>.value(
                          value: planner,
                          child: const CardRelationshipBuilder(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.motherSage,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: rules.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return _RuleCard(
                        rule: rule,
                        planner: planner,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChangeNotifierProvider<PlannerState>.value(
                                value: planner,
                                child: CardRelationshipBuilder(
                                  existingRule: rule,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(
              Icons.rule_folder_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Rules Defined',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create card relationships to enforce\nadvanced constraints in your timetable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              final planner = context.read<PlannerState>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<PlannerState>.value(
                    value: planner,
                    child: const CardRelationshipBuilder(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Rule'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.planner,
    required this.onTap,
  });

  final CardRelationship rule;
  final PlannerState planner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Resolve subject abbreviations
    final subjects = rule.subjectIds.map((id) {
      final s = planner.subjects.where((x) => x.id == id).firstOrNull;
      return s?.abbr ?? 'Unknown Subject';
    }).join(', ');

    // Resolve class abbreviations
    final classes = rule.classIds.map((id) {
      final c = planner.classes.where((x) => x.id == id).firstOrNull;
      return c?.abbr ?? 'Unknown Class';
    }).join(', ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            color: rule.isActive ? Colors.white : Colors.grey.shade50,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelRow(
                            'Condition', rule.condition, Colors.black87, true),
                        const SizedBox(height: 8),
                        if (subjects.isNotEmpty)
                          _buildLabelRow('Subjects', subjects,
                              const Color(0xFF6366F1), false),
                        if (subjects.isNotEmpty && classes.isNotEmpty)
                          const SizedBox(height: 6),
                        if (classes.isNotEmpty)
                          _buildLabelRow('Classes', classes,
                              const Color(0xFF0891B2), false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: rule.isActive,
                    onChanged: (val) {
                      final idx = planner.cardRelationships
                          .indexWhere((r) => r.id == rule.id);
                      if (idx >= 0) {
                        planner.cardRelationships[idx].isActive = val;
                        // The class setter in Provider needs to be wrapped or manually called notifyListeners
                        // but since CardRelationship is mutable and planner_state doesn't know, we must force save
                        planner.updateCardRelationship(
                            planner.cardRelationships[idx]);
                      }
                    },
                    activeColor: AppTheme.motherSage,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getImportanceColor(rule.importance).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag,
                            size: 14,
                            color: _getImportanceColor(rule.importance)),
                        const SizedBox(width: 4),
                        Text(
                          rule.importance,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getImportanceColor(rule.importance),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rule.note.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rule.note,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelRow(
      String label, String value, Color valueColor, bool isBold) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'strict':
        return Colors.red;
      case 'optimize':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
