import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryChip({
    super.key,
    required this.label,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          InkWell(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
