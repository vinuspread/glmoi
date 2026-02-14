import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';
import 'profile_nickname_prompt_host.dart';

class GlmoiApp extends ConsumerWidget {
  const GlmoiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Glmoi',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return ProfileNicknamePromptHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
