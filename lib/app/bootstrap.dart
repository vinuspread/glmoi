import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;

import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK (required for login/share)
  kakao.KakaoSdk.init(
    nativeAppKey: 'c113b598f60db67366a6d48caa459b74',
  );

  await Firebase.initializeApp();
  runApp(const ProviderScope(child: GlmoiApp()));
}
