import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 계정 섹션
          if (isLoggedIn) ...[
            const _SectionHeader(title: '계정'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.person_outline,
              title: '마이페이지',
              onTap: () => context.push('/mypage'),
            ),
            _SettingsTile(
              icon: Icons.logout,
              title: '로그아웃',
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  try {
                    await ref.read(authProvider.notifier).logout();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('로그아웃되었습니다.')),
                    );
                    context.go('/home');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그아웃 실패: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ] else ...[
            const _SectionHeader(title: '계정'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.login,
              title: '로그인',
              onTap: () => context.push('/login'),
            ),
            const SizedBox(height: 24),
          ],

          // 앱 정보 섹션
          const _SectionHeader(title: '앱 정보'),
          const SizedBox(height: 8),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: '버전 정보',
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(elevated: true),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accent),
        title: Text(title),
        trailing: trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }
}
