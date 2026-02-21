import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/fcm/notification_prefs_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/font_scale_provider.dart';
import '../../../core/backend/functions_client.dart';
import '../../../core/config/app_config_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);
    final currentFontScale = ref.watch(fontScaleProvider);
    final appConfigAsync = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 글모이 설정 섹션
          const _SectionHeader(title: '글모이 설정'),
          const SizedBox(height: 8),
          Container(
            decoration: AppTheme.cardDecoration(elevated: true),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '콘텐츠 폰트 크기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '등록된 글의 크기 설정',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: FontScaleLevel.values.map((level) {
                    final isSelected = currentFontScale == level;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          height: 48,
                          child: isSelected
                              ? FilledButton(
                                  onPressed: null,
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(level.label),
                                )
                              : OutlinedButton(
                                  onPressed: () {
                                    ref
                                        .read(fontScaleProvider.notifier)
                                        .setScale(level);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(level.label),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 계정 섹션
          if (isLoggedIn) ...[
            const _SectionHeader(title: '계정'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.person_outline,
              title: '마이페이지',
              onTap: () => context.push('/mypage'),
            ),
            _AutoContentToggleTile(),
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
            _SettingsTile(
              icon: Icons.delete_forever,
              title: '탈퇴하기',
              onTap: () => _showDeleteAccountDialog(context, ref),
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
          _SettingsTile(
            icon: Icons.business_outlined,
            title: '회사소개',
            onTap: () => context.push('/settings/company-info'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () => context.push('/settings/terms'),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: '버전 정보',
            trailing: appConfigAsync.when(
              data: (config) => Text(
                config.latestVersion,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text(
                '1.0.0',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
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

class _AutoContentToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoEnabled =
        ref.watch(autoContentEnabledProvider).valueOrNull ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(elevated: true),
      child: ListTile(
        leading:
            const Icon(Icons.notifications_outlined, color: AppTheme.accent),
        title: const Text('좋은글자동수신'),
        trailing: Switch(
          value: autoEnabled,
          onChanged: (value) async {
            await ref
                .read(notificationPrefsControllerProvider)
                .setAutoContent(value);
          },
          activeColor: AppTheme.accent,
        ),
        onTap: () async {
          await ref
              .read(notificationPrefsControllerProvider)
              .setAutoContent(!autoEnabled);
        },
      ),
    );
  }
}

Future<void> _showDeleteAccountDialog(
    BuildContext context, WidgetRef ref) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('탈퇴하기'),
      content: const Text(
        '계정을 탈퇴하시겠습니까?\n\n작성한 글과 모든 활동 기록이 삭제되며, 복구할 수 없습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('탈퇴하기'),
        ),
      ],
    ),
  );

  if (shouldDelete != true) return;

  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final callable = FunctionsClient.instance.httpsCallable('deleteAccount');
    await callable.call();

    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계정이 삭제되었습니다.')),
    );

    context.go('/home');
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('탈퇴 실패: $e')),
    );
  }
}
