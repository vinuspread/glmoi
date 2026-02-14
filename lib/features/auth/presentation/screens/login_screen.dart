import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glmoi/core/auth/auth_service.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import 'package:glmoi/features/auth/domain/login_redirect.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final LoginRedirect? redirect;

  const LoginScreen({super.key, this.redirect});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _didNavigateAfterLogin = false;
  var _isEmailLoading = false;
  var _isKakaoLoading = false;
  var _isGoogleLoading = false;

  void _navigateAfterLogin() {
    if (_didNavigateAfterLogin) return;
    _didNavigateAfterLogin = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final rootNav = Navigator.of(context, rootNavigator: true);
      final rootContext = rootNav.context;

      final goTo = (widget.redirect?.goTo ?? '').trim();
      if (goTo.isNotEmpty) {
        GoRouter.of(rootContext).go(goTo);
        return;
      }

      if (widget.redirect?.popOnSuccess == true && rootNav.canPop()) {
        rootNav.pop();
        return;
      }

      GoRouter.of(rootContext).go('/home');
    });
  }

  String _friendlyLoginError(Object e, {required String fallback}) {
    if (e is FirebaseException) {
      // Avoid surfacing raw FirebaseException strings to users.
      if (e.plugin == 'cloud_firestore') {
        return '회원정보 저장에 실패했습니다. 잠시 후 다시 시도해주세요.';
      }
      if (e.plugin == 'cloud_functions') {
        return '로그인 처리에 실패했습니다. 잠시 후 다시 시도해주세요.';
      }
    }

    if (e is PlatformException) {
      // Kakao login errors often surface as PlatformException.
      if (e.code.trim() == 'NotSupportError' ||
          (e.message ?? '').toLowerCase().contains('not connected to kakao')) {
        return '카카오톡앱 로그인을 먼저 진행하세요';
      }
      final msg = (e.message ?? '').trim();
      if (msg.isNotEmpty) return msg;
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return '이메일을 올바르게 입력하세요';
        case 'missing-email':
          return '이메일을 입력하세요';
        case 'user-not-found':
          return '가입되지 않은 이메일입니다';
        case 'wrong-password':
        case 'invalid-credential':
          return '이메일 또는 비밀번호가 올바르지 않습니다';
        case 'user-disabled':
          return '비활성화된 계정입니다';
        case 'too-many-requests':
          return '요청이 많아요. 잠시 후 다시 시도하세요';
        case 'network-request-failed':
          return '네트워크 연결을 확인해주세요';
      }

      final msg = (e.message ?? '').trim();
      if (msg.isNotEmpty) return msg;
      return fallback;
    }

    var msg = e.toString().trim();
    const badStatePrefix = 'Bad state: ';
    if (msg.startsWith(badStatePrefix)) {
      msg = msg.substring(badStatePrefix.length).trim();
    }
    const exceptionPrefix = 'Exception: ';
    if (msg.startsWith(exceptionPrefix)) {
      msg = msg.substring(exceptionPrefix.length).trim();
    }

    if (msg.isEmpty) return fallback;
    if (msg.toLowerCase() == 'null') return fallback;

    // Defensive mapping: sometimes Kakao errors arrive as a non-PlatformException
    // (or wrapped) but keep the same message. Never show raw developer text.
    final lower = msg.toLowerCase();
    if (lower.contains('not connected to kakao') ||
        lower.contains('kakaotalk is installed but not connected to kakao')) {
      return '카카오톡앱 로그인을 먼저 진행하세요';
    }

    return msg;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // If the auth state is already restored, don't stay on the login screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authProvider)) {
        _navigateAfterLogin();
      }
    });
  }

  Future<void> _loginWithEmail() async {
    if (_isEmailLoading) return;

    setState(() => _isEmailLoading = true);

    try {
      await ref.read(authProvider.notifier).loginWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser != null) {
        _navigateAfterLogin();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyLoginError(e, fallback: '로그인에 실패했습니다'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF7F2),
                Color(0xFFFAF7F2),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '마음소리',
                    textAlign: TextAlign.center,
                    style: t.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '눈이 편안한 글, 마음을 울리는 한 줄',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    decoration: AppTheme.cardDecoration(elevated: true),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '이메일로 로그인',
                          style: t.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: '이메일',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _loginWithEmail(),
                          decoration: const InputDecoration(
                            labelText: '비밀번호',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _isEmailLoading ? null : _loginWithEmail,
                            child: _isEmailLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('로그인'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () =>
                              context.push('/signup', extra: widget.redirect),
                          child: const Text('이메일로 회원가입'),
                        ),
                        const Divider(height: 28),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE500),
                              foregroundColor: const Color(0xFF191919),
                            ),
                            onPressed: _isKakaoLoading
                                ? null
                                : () async {
                                    setState(() => _isKakaoLoading = true);

                                    try {
                                      await ref
                                          .read(authProvider.notifier)
                                          .loginWithKakao();

                                      if (!context.mounted) return;
                                      if (FirebaseAuth.instance.currentUser !=
                                          null) {
                                        _navigateAfterLogin();
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _friendlyLoginError(
                                              e,
                                              fallback: '카카오 로그인에 실패했습니다',
                                            ),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isKakaoLoading = false);
                                      }
                                    }
                                  },
                            icon: _isKakaoLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF191919)),
                                    ),
                                  )
                                : const Icon(Icons.chat_bubble),
                            label: Text(
                                _isKakaoLoading ? '로그인 중...' : '카카오톡으로 시작하기'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _isGoogleLoading
                                ? null
                                : () async {
                                    setState(() => _isGoogleLoading = true);

                                    try {
                                      await ref
                                          .read(authProvider.notifier)
                                          .loginWithGoogle();

                                      if (!context.mounted) return;
                                      if (FirebaseAuth.instance.currentUser !=
                                          null) {
                                        _navigateAfterLogin();
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _friendlyLoginError(
                                              e,
                                              fallback: '구글 로그인에 실패했습니다',
                                            ),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(
                                            () => _isGoogleLoading = false);
                                      }
                                    }
                                  },
                            icon: _isGoogleLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.g_mobiledata),
                            label: Text(
                                _isGoogleLoading ? '로그인 중...' : '구글로 시작하기'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => context.go('/home'),
                          child: Text(
                            '로그인 없이 둘러보기',
                            style: t.textTheme.labelLarge?.copyWith(
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '로그인 후 글 작성/좋아요/공유 기능을 사용할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
