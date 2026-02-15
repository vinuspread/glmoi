import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/profile_edit_dialog.dart';
import '../providers/user_stats_provider.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final isLoggedIn = ref.watch(authProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!isLoggedIn || currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: AppTheme.cardDecoration(elevated: true),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 40, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text('로그인이 필요합니다.', style: t.textTheme.titleMedium),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('로그인하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 프로필 카드
            Container(
              decoration: AppTheme.cardDecoration(elevated: true),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 프로필 이미지
                  GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final saved = await showDialog<bool>(
                        context: context,
                        builder: (_) => const ProfileEditDialog(),
                      );
                      if (saved == true) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('프로필이 저장되었습니다.')),
                        );
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: currentUser.photoURL != null &&
                                currentUser.photoURL!.isNotEmpty
                            ? Image.network(
                                currentUser.photoURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultProfileIcon(),
                              )
                            : _defaultProfileIcon(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 닉네임
                  Text(
                    currentUser.displayName ?? '사용자',
                    style: t.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // 이메일
                  if (currentUser.email != null)
                    Text(
                      currentUser.email!,
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 16),

                  // 프로필 수정 버튼
                  TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final saved = await showDialog<bool>(
                        context: context,
                        builder: (_) => const ProfileEditDialog(),
                      );
                      if (saved == true) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('프로필이 저장되었습니다.')),
                        );
                        ref.invalidate(userStatsProvider);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('프로필 수정'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 통계 카드
            Container(
              decoration: AppTheme.cardDecoration(elevated: true),
              padding: const EdgeInsets.all(20),
              child: ref.watch(userStatsProvider).when(
                    data: (stats) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '내 활동',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          icon: Icons.edit_note,
                          label: '내가 쓴 글',
                          count: stats.myQuotesCount,
                          onTap: () => context.push('/malmoi/mine'),
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          icon: Icons.bookmark,
                          label: '담은 글',
                          count: stats.savedQuotesCount,
                          onTap: () => context.push('/saved-quotes'),
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          icon: Icons.favorite,
                          label: '좋아요',
                          count: stats.likedQuotesCount,
                          onTap: null,
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          '내가 받은 감정',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ReactionStat(
                              iconPath: 'assets/icons/reactions/comfort.png',
                              label: '위로',
                              count:
                                  stats.receivedReactionStats['comfort'] ?? 0,
                            ),
                            _ReactionStat(
                              iconPath: 'assets/icons/reactions/empathize.png',
                              label: '공감',
                              count:
                                  stats.receivedReactionStats['empathize'] ?? 0,
                            ),
                            _ReactionStat(
                              iconPath: 'assets/icons/reactions/good.png',
                              label: '멋진글',
                              count: stats.receivedReactionStats['good'] ?? 0,
                            ),
                            _ReactionStat(
                              iconPath: 'assets/icons/reactions/touched.png',
                              label: '감동',
                              count:
                                  stats.receivedReactionStats['touched'] ?? 0,
                            ),
                            _ReactionStat(
                              iconPath: 'assets/icons/reactions/fan.png',
                              label: '팬',
                              count: stats.receivedReactionStats['fan'] ?? 0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '통계를 불러올 수 없습니다.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return const Icon(
      Icons.person,
      color: AppTheme.textSecondary,
      size: 50,
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Text(
          '$count개',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.accent,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              size: 20, color: AppTheme.textSecondary),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: content,
    );
  }
}

class _ReactionStat extends StatelessWidget {
  final String iconPath;
  final String label;
  final int count;

  const _ReactionStat({
    required this.iconPath,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              iconPath,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sentiment_satisfied,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }
}
