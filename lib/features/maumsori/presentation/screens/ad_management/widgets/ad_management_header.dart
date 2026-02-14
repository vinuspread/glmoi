import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class AdManagementHeader extends StatelessWidget {
  const AdManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.ads_click, color: AppTheme.primaryPurple, size: 28),
          const SizedBox(width: 12),
          const Text(
            '광고 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
