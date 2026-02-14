import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class QuoteManagementHeader extends StatelessWidget {
  final int? totalCount;
  final VoidCallback onAdd;

  const QuoteManagementHeader({
    super.key,
    required this.totalCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Quotes Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          if (totalCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total $totalCount',
                style: const TextStyle(
                  color: AppTheme.primaryPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Quote'),
          ),
        ],
      ),
    );
  }
}
