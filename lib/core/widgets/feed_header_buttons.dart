import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';

/// AppBar 좌측에 표시되는 버튼 (로그인 or 프로필)
class FeedLeadingButton extends ConsumerWidget {
  const FeedLeadingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoggedIn
              ? _ProfileImageButton(
                  photoUrl: currentUser?.photoURL,
                  onTap: () => context.push('/mypage'),
                )
              : _RoundTextButton(
                  label: '로그인',
                  onTap: () => context.push('/login'),
                ),
        ],
      ),
    );
  }
}

/// AppBar 우측에 표시되는 버튼 (설정)
class FeedTrailingButton extends StatelessWidget {
  const FeedTrailingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _RoundTextButton(
        label: '설정',
        onTap: () => context.push('/settings'),
      ),
    );
  }
}

/// 라운드 박스 텍스트 버튼 (글모이 상세 스타일 참고)
class _RoundTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RoundTextButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius24), // More rounded
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          border: Border.all(
            color: AppTheme.border, // Use solid border color
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15, // Slightly larger text
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// 프로필 이미지 버튼 (원형)
class _ProfileImageButton extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;

  const _ProfileImageButton({
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius24),
      child: Container(
        width: 44, // Larger size 40 -> 44
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.border,
            width: 1,
          ),
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultProfileIcon(),
                )
              : _defaultProfileIcon(),
        ),
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return const Icon(
      Icons.person,
      color: AppTheme.textSecondary,
      size: 24,
    );
  }
}
