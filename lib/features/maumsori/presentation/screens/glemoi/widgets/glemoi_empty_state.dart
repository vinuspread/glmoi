import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class GlemoiEmptyState extends StatelessWidget {
  final String message;

  const GlemoiEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
