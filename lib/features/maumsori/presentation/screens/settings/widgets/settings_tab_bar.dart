import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class SettingsTabBar extends StatelessWidget {
  final TabController controller;

  const SettingsTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        labelColor: AppTheme.primaryPurple,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryPurple,
        tabs: const [
          Tab(text: '콘텐츠 설정'),
          Tab(text: '버전/모드 관리'),
          Tab(text: '약관 관리'),
        ],
      ),
    );
  }
}
