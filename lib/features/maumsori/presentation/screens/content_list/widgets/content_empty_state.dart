import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class ContentEmptyState extends StatelessWidget {
  final bool isSearching;

  const ContentEmptyState({super.key, required this.isSearching});

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
            isSearching ? '검색 결과가 없습니다' : '등록된 글이 없습니다',
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
