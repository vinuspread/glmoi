import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;

import '../core/fcm/local_notification_service.dart';
import '../core/remote_config/remote_config_service.dart';
import 'app.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ========== START ==========');
  debugPrint('[FCM Background] Message ID: ${message.messageId}');
  debugPrint('[FCM Background] Full data: ${message.data}');

  final content = message.data['content'] as String?;
  final quoteId = message.data['quote_id'] as String?;
  final quoteType = message.data['quote_type'] as String?;
  final notification = message.notification;

  if (notification != null) {
    debugPrint(
        '[FCM Background] Notification payload detected. Skip local notification to avoid duplicate.');
    debugPrint('[FCM Background] ========== END ==========');
    return;
  }

  debugPrint(
      '[FCM Background] Parsed - quoteId: $quoteId, quoteType: $quoteType, content: ${content?.substring(0, content.length > 50 ? 50 : content.length)}...');

  if (content != null) {
    await LocalNotificationService().initialize();

    final payload = quoteId != null ? '$quoteId|${quoteType ?? 'quote'}' : null;

    debugPrint(
        '[FCM Background] Creating local notification with payload: $payload');

    await LocalNotificationService().showBigTextNotification(
      title: '오늘의 좋은글',
      body: content,
      payload: payload,
    );

    debugPrint('[FCM Background] Local notification created successfully');
  } else {
    debugPrint(
        '[FCM Background] WARNING: content is null, skipping notification');
  }

  debugPrint('[FCM Background] ========== END ==========');
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK (required for login/share)
  kakao.KakaoSdk.init(
    nativeAppKey: 'c113b598f60db67366a6d48caa459b74',
  );

  await Firebase.initializeApp();

  // Remote Config 초기화 (백그라운드 fetch, 앱 시작 지연 없음)
  await RemoteConfigService.init();

  // FCM background message handler setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: GlmoiApp()));
}
