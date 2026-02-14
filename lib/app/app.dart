import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/font_scale_provider.dart';
import 'router.dart';
import 'profile_nickname_prompt_host.dart';

class GlmoiApp extends ConsumerWidget {
  const GlmoiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      title: 'Glmoi',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale.scale),
          ),
          child: ProfileNicknamePromptHost(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
