import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class ActivityStatsSection extends StatelessWidget {
  final Map<String, int> stats;

  const ActivityStatsSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 활동',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActivityCard(
                icon: Icons.edit_note,
                label: '글모이 새글',
                sublabel: '(1주일간)',
                value: '${stats['newMalmoi'] ?? 0}',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActivityCard(
                icon: Icons.people,
                label: '전체 회원',
                sublabel: '',
                value: '${stats['totalUsers'] ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActivityCard(
                icon: Icons.person_add,
                label: '신규 회원',
                sublabel: '(1주일간)',
                value: '${stats['newUsers'] ?? 0}',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final String value;
  final Color color;

  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (sublabel.isNotEmpty)
                Text(
                  ' $sublabel',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
