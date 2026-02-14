import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class QuoteManagementSidebar extends StatelessWidget {
  const QuoteManagementSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '마음소리 Admin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const _SidebarHeader(label: 'Projects'),
          const _SidebarMenuTile(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
          ),
          const _SidebarMenuTile(
            icon: Icons.format_quote,
            label: 'Quotes',
            isActive: true,
          ),
          const _SidebarMenuTile(
            icon: Icons.image_outlined,
            label: 'Image Pool',
          ),
          const SizedBox(height: 24),
          const _SidebarHeader(label: 'Management'),
          const _SidebarMenuTile(icon: Icons.people_outline, label: 'Users'),
          const _SidebarMenuTile(
            icon: Icons.settings_outlined,
            label: 'Remote Config',
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final String label;
  const _SidebarHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _SidebarMenuTile({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? AppTheme.primaryPurple : AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryPurple : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
