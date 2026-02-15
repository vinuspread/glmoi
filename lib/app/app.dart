import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/fcm/fcm_service.dart';
import 'router.dart';
import 'profile_nickname_prompt_host.dart';

class GlmoiApp extends ConsumerStatefulWidget {
  const GlmoiApp({super.key});

  @override
  ConsumerState<GlmoiApp> createState() => _GlmoiAppState();
}

class _GlmoiAppState extends ConsumerState<GlmoiApp> {
  @override
  void initState() {
    super.initState();
    // Initialize unified FCM service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navKey = ref.read(rootNavigatorKeyProvider);
      FCMService().initialize(navKey);
    });
  }

  @override
  Widget build(BuildContext context) {
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
