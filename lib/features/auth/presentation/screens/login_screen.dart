import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glmoi/core/auth/auth_service.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import 'package:glmoi/features/auth/domain/login_redirect.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    // Warm, calm solid background (or very subtle gradient)
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Area


                Image.asset(
                  'assets/icons/logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      '글모이',
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineSmall?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '누구나 작가가 되는 공간',
                  textAlign: TextAlign.center,
                  style: t.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),

                // Login Card
                Container(
                  decoration: AppTheme.cardDecoration(elevated: true),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // More internal padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '이메일로 로그인',
                        style: t.textTheme.titleLarge // Larger section title
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Email Input
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(fontSize: 18), // Larger input text
                        decoration: const InputDecoration(
                          labelText: '이메일 주소',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Input
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _loginWithEmail(),
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button (Height 48)
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isEmailLoading ? null : _loginWithEmail,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero, // Remove padding to fit in 48px
                          ),
                          child: _isEmailLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('로그인', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            context.push('/signup', extra: widget.redirect),
                        child: const Text('이메일로 회원가입', style: TextStyle(fontSize: 16)),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(),
                      ),

                      // Kakao Login (Height 48)
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE500),
                            foregroundColor: const Color(0xFF191919),
                            padding: EdgeInsets.zero, // Remove padding
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
                              : SvgPicture.asset(
                                  'assets/icons/kakao.svg',
                                  width: 24,
                                  height: 24,
                                ),
                          label: Text(
                              _isKakaoLoading ? '로그인 중...' : '카카오톡으로 시작하기',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google Login (Height 48)
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero, // Remove padding
                          ),
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
                              : SvgPicture.asset(
                                  'assets/icons/google.svg',
                                  width: 24,
                                  height: 24,
                                ),
                          label: Text(
                              _isGoogleLoading ? '로그인 중...' : '구글로 시작하기',
                              // Use app accent color for consistency if desired, or black
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          '로그인 없이 둘러보기',
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.border,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom helper text
                const SizedBox(height: 32),
                Text(
                  '로그인 후 글 작성/좋아요/공유 기능을\n자유롭게 이용해보세요.',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
