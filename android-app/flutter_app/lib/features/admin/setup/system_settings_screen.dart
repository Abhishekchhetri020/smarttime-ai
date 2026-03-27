import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../planner_state.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Optimization Weights ──
          _SectionCard(
            icon: Icons.balance_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Optimization Weights',
            subtitle:
                'Fine-tune how the AI prioritizes different scheduling goals',
            children: [
              _WeightSlider(
                label: 'Teacher Gaps',
                description:
                    'Minimize free periods between classes for teachers',
                icon: Icons.person_outline_rounded,
                value: planner.softWeights['teacher_gaps'] ?? 5,
                onChanged: (v) => planner.updateSoftWeight('teacher_gaps', v),
              ),
              const Divider(height: 24),
              _WeightSlider(
                label: 'Class Gaps',
                description:
                    'Minimize free periods between lessons for classes',
                icon: Icons.class_outlined,
                value: planner.softWeights['class_gaps'] ?? 5,
                onChanged: (v) => planner.updateSoftWeight('class_gaps', v),
              ),
              const Divider(height: 24),
              _WeightSlider(
                label: 'Subject Distribution',
                description: 'Spread subjects evenly across the week',
                icon: Icons.calendar_view_week_rounded,
                value: planner.softWeights['subject_distribution'] ?? 3,
                onChanged: (v) =>
                    planner.updateSoftWeight('subject_distribution', v),
              ),
              const Divider(height: 24),
              _WeightSlider(
                label: 'Room Stability',
                description: 'Keep teachers in the same room when possible',
                icon: Icons.meeting_room_outlined,
                value: planner.softWeights['teacher_room_stability'] ?? 1,
                onChanged: (v) =>
                    planner.updateSoftWeight('teacher_room_stability', v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── General Info ──
          _SectionCard(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF4F46E5),
            title: 'About Weights',
            subtitle: 'How the optimization engine uses these values',
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4DFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(
                      label: '0',
                      desc: 'Disabled — constraint is ignored',
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    _InfoItem(
                      label: '1–3',
                      desc: 'Low priority — nice to have',
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 8),
                    _InfoItem(
                      label: '4–6',
                      desc: 'Medium priority — standard',
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(height: 8),
                    _InfoItem(
                      label: '7–10',
                      desc: 'High priority — strongly enforced',
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Reset ──
          Center(
            child: TextButton.icon(
              onPressed: () {
                planner.updateSoftWeight('teacher_gaps', 5);
                planner.updateSoftWeight('class_gaps', 5);
                planner.updateSoftWeight('subject_distribution', 3);
                planner.updateSoftWeight('teacher_room_stability', 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weights reset to defaults')),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset to Defaults'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section Card ──
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Weight Slider ──
class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  Color _valueColor(int v) {
    if (v == 0) return Colors.grey;
    if (v <= 3) return const Color(0xFF059669);
    if (v <= 6) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final color = _valueColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(description,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            min: 0,
            max: 10,
            divisions: 10,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

// ── Info Item ──
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.desc,
    required this.color,
  });

  final String label;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(desc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
      ],
    );
  }
}
