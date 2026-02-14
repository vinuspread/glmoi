import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [필수] Riverpod 사용 시 필요
import 'main.dart'; // MaumSoriAdminApp 불러오기
import 'package:app_admin/core/firebase/firebase_env_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // glmoi-dev 프로젝트의 웹 설정값 입력
  await Firebase.initializeApp(options: FirebaseEnvOptions.prod);

  // 앱 실행
  runApp(
    // [중요] Riverpod 상태 관리를 위해 ProviderScope로 감싸야 함
    const ProviderScope(child: MaumSoriAdminApp(env: 'PROD')),
  );
}
