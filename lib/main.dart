import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/router/app_router.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_admin/core/firebase/firebase_env_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Default admin entrypoint uses PROD so operators always see real data.
  // Use `lib/main_dev.dart` or `lib/main_prod.dart` explicitly if needed.
  await Firebase.initializeApp(options: FirebaseEnvOptions.prod);

  runApp(const ProviderScope(child: MaumSoriAdminApp(env: 'PROD')));
}

class MaumSoriAdminApp extends ConsumerWidget {
  // 👇 [수정 1] env 변수 추가
  final String? env;

  // 👇 [수정 2] 생성자에서 env 받도록 수정
  const MaumSoriAdminApp({super.key, this.env});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // 👇 [수정 3] 브라우저 탭 제목에 환경 표시 (예: MAD... [DEV])
      title: 'MAD: Master Admin Dashboard ${env == null ? "" : "[$env]"}',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
