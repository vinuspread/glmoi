import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../core/auth/auth_service.dart';
import 'router.dart';

/// App-level host that enforces: logged-in users must have a nickname.
///
/// This lives outside of presentation so design-only changes can freely edit UI
/// without touching auth/profile business logic.
class ProfileNicknamePromptHost extends ConsumerStatefulWidget {
  final Widget child;
  const ProfileNicknamePromptHost({super.key, required this.child});

  @override
  ConsumerState<ProfileNicknamePromptHost> createState() =>
      _ProfileNicknamePromptHostState();
}

class _ProfileNicknamePromptHostState
    extends ConsumerState<ProfileNicknamePromptHost> {
  var _prompting = false;
  var _didPromptThisSession = false;
  var _missingNicknameRetries = 0;
  Timer? _retryTimer;
  ProviderSubscription<bool>? _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = ref.listenManual<bool>(authProvider, (prev, next) {
      if (next) {
        _ensureNickname();
      }
    });

    if (FirebaseAuth.instance.currentUser != null) {
      _ensureNickname();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _authSub?.close();
    super.dispose();
  }

  void _ensureNickname() {
    if (_didPromptThisSession || _prompting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Avoid prompting during the first few seconds after account creation.
    // Email sign-up updates displayName right after creation; auth state changes
    // may arrive before displayName is visible here.
    final createdAt = user.metadata.creationTime;
    if (createdAt != null) {
      final age = DateTime.now().difference(createdAt);
      if (age.inSeconds >= 0 && age.inSeconds < 15) {
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(milliseconds: 600), _ensureNickname);
        return;
      }
    }

    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) {
      _missingNicknameRetries = 0;
      return;
    }

    // Retry a few times before prompting. This smooths out timing races where
    // displayName is being updated right after login/sign-up.
    if (_missingNicknameRetries < 3) {
      _missingNicknameRetries += 1;
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 500), _ensureNickname);
      return;
    }

    _prompting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Auth state can flip to "logged in" before profile fields (displayName)
      // are updated (ex: email sign-up). Reload and re-check once before prompting.
      try {
        await user.reload();
      } catch (_) {
        // Best-effort; proceed to prompt if still missing.
      }

      final refreshed = FirebaseAuth.instance.currentUser;
      final refreshedName = (refreshed?.displayName ?? '').trim();
      if (refreshed != null && refreshedName.isNotEmpty) {
        _didPromptThisSession = true;
        _prompting = false;
        return;
      }

      if (!mounted) {
        _prompting = false;
        return;
      }

      // MaterialApp.router's builder context can be above the Navigator.
      // Always use the router's root navigator context for dialogs.
      final navState = ref.read(rootNavigatorKeyProvider).currentState;
      if (navState == null || !navState.mounted) {
        _prompting = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureNickname();
        });
        return;
      }

      final controller = TextEditingController();
      try {
        final nickname = await showDialog<String>(
          context: navState.context,
          barrierDismissible: false,
          builder: (context) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('닉네임을 입력해주세요'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    hintText: '닉네임 (필수)',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) {
                    final trimmed = v.trim();
                    if (trimmed.isEmpty) return;
                    Navigator.of(context, rootNavigator: true)
                        .pop<String>(trimmed);
                  },
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      final trimmed = controller.text.trim();
                      if (trimmed.isEmpty) return;
                      Navigator.of(context, rootNavigator: true)
                          .pop<String>(trimmed);
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
        );

        if (!mounted) return;
        final trimmed = (nickname ?? '').trim();
        if (trimmed.isEmpty) return;

        await ref.read(authProvider.notifier).updateNickname(trimmed);
        _didPromptThisSession = true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('닉네임이 저장되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          var msg = e.toString().trim();
          if (e is FirebaseException && e.plugin == 'cloud_firestore') {
            msg = '닉네임 저장에 실패했습니다. 잠시 후 다시 시도해주세요.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('닉네임 저장 실패: $msg')),
          );
        }
      } finally {
        controller.dispose();
        _prompting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
