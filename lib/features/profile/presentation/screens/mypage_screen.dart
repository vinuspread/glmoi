import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/profile_image_edit_dialog.dart';

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
                        builder: (_) => const ProfileImageEditDialog(),
                      );
                      if (saved == true) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('프로필 이미지가 저장되었습니다.')),
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
                        builder: (_) => const ProfileImageEditDialog(),
                      );
                      if (saved == true) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('프로필 이미지가 저장되었습니다.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('프로필 수정'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 내 활동
            Container(
              decoration: AppTheme.cardDecoration(elevated: true),
              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.edit_note, color: AppTheme.accent),
                    title: const Text('내가 쓴 글'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/malmoi/mine'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bookmark, color: AppTheme.accent),
                    title: const Text('담은 글'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/saved-quotes'),
                  ),
                ],
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
