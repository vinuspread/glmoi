import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glmoi/core/auth/auth_service.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import 'package:glmoi/features/auth/domain/login_redirect.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EmailSignUpScreen extends ConsumerStatefulWidget {
  final LoginRedirect? redirect;

  const EmailSignUpScreen({super.key, this.redirect});

  @override
  ConsumerState<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends ConsumerState<EmailSignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  Uint8List? _profileImageBytes;
  var _isSubmitting = false;
  var _didNavigateAfterSignUp = false;

  void _navigateAfterSignUp() {
    if (_didNavigateAfterSignUp) return;
    _didNavigateAfterSignUp = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final rootNav = Navigator.of(context, rootNavigator: true);
      final rootContext = rootNav.context;

      final goTo = (widget.redirect?.goTo ?? '').trim();
      if (goTo.isNotEmpty) {
        GoRouter.of(rootContext).go(goTo);
        return;
      }

      if (widget.redirect?.popOnSuccess == true) {
        // Close /signup and then /login (if present) to return to the original screen.
        if (rootNav.canPop()) {
          rootNav.pop();
          Future.microtask(() {
            if (!mounted) return;
            final nav2 = Navigator.of(context, rootNavigator: true);
            if (nav2.canPop()) nav2.pop();
          });
          return;
        }
      }

      GoRouter.of(rootContext).go('/home');
    });
  }

  String _friendlySignUpError(Object e, {required String fallback}) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return '이메일을 올바르게 입력하세요';
        case 'missing-email':
          return '이메일을 입력하세요';
        case 'weak-password':
          return '비밀번호는 6자 이상으로 입력하세요';
        case 'missing-password':
          return '비밀번호를 입력하세요';
        case 'operation-not-allowed':
          return '현재 이메일 회원가입을 사용할 수 없습니다';
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
    return msg;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _profileImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 이미지 선택 실패: $e')),
      );
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 올바르게 입력하세요')),
      );
      return;
    }
    if (password.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상으로 입력하세요')),
      );
      return;
    }
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력하세요')),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
            nickname: nickname,
            profileImageBytes: _profileImageBytes,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입이 완료되었습니다.')),
      );

      _navigateAfterSignUp();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        final goLogin = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('이미 가입된 이메일입니다'),
              content: const Text('로그인 화면으로 이동할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('다른 이메일 입력'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('로그인으로 이동'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;
        if (goLogin == true) {
          context.go('/login', extra: widget.redirect);
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlySignUpError(e, fallback: '회원가입에 실패했습니다'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlySignUpError(e, fallback: '회원가입에 실패했습니다'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('이메일 회원가입'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: AppTheme.cardDecoration(elevated: true),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '프로필',
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.surfaceAlt,
                          backgroundImage: _profileImageBytes == null
                              ? null
                              : MemoryImage(_profileImageBytes!),
                          child: _profileImageBytes == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickProfileImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('프로필 이미지 선택'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nicknameController,
                      textInputAction: TextInputAction.next,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: '닉네임 (필수)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecoration(elevated: true),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '계정',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        helperText: '6자 이상',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(_isSubmitting ? '가입 중...' : '회원가입'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('로그인으로 돌아가기'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
