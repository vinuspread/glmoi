import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class GlemoiTabBar extends StatelessWidget {
  final TabController controller;

  const GlemoiTabBar({super.key, required this.controller});

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
          Tab(text: '검수 대기'),
          Tab(text: '승인됨'),
          Tab(text: '신고됨'),
        ],
      ),
    );
  }
}
