import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class PermissionDeniedCard extends StatelessWidget {
  final String userEmail;
  final String projectId;
  final String? resource;

  const PermissionDeniedCard({
    super.key,
    required this.userEmail,
    required this.projectId,
    this.resource,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '접근 권한이 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Firestore/Storage Rules의 관리자 이메일 allowlist를 확인해주세요.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text('email: $userEmail'),
            Text('project: $projectId'),
            if (resource != null) ...[
              const SizedBox(height: 8),
              Text('resource: $resource'),
            ],
          ],
        ),
      ),
    );
  }
}
