import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(String?)? _onNotificationTap;

  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_initialized) return;

    _onNotificationTap = onNotificationTap;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
            '[LocalNotification] Notification tapped: ${response.payload}');
        _onNotificationTap?.call(response.payload);
      },
    );

    // Check if app was launched by tapping a notification (terminated state)
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final response = launchDetails.notificationResponse;
      if (response != null) {
        debugPrint(
            '[LocalNotification] App launched from notification: ${response.payload}');
        // Handle the pending notification tap after a short delay
        // to ensure the app navigation context is ready
        Future.delayed(const Duration(milliseconds: 800), () {
          _onNotificationTap?.call(response.payload);
        });
      }
    }

    _initialized = true;
  }

  Future<void> showBigTextNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final bigTextStyleInformation = BigTextStyleInformation(
        body,
        contentTitle: title,
        htmlFormatContentTitle: false,
        htmlFormatBigText: false,
      );

      final androidDetails = AndroidNotificationDetails(
        'glmoi_notifications',
        '글모이 알림',
        channelDescription: '오늘의 글 자동발송 알림',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: bigTextStyleInformation,
        enableVibration: true,
        playSound: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotification] Error showing notification: $e');
    }
  }

  Future<String> _downloadAndSaveImage(String url) async {
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }
}
