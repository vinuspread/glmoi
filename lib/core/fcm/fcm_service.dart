import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'local_notification_service.dart';
import 'notification_prefs_repository.dart';

/// FCM service for handling foreground/background/terminated message events
/// Unified service that handles both FCM messages and local notification taps
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  /// Initialize FCM message listeners and local notification service
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) {
      debugPrint('[FCM] Already initialized, skipping');
      return;
    }

    _navigatorKey = navigatorKey;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _syncTopicSubscription();

        // Get FCM token
        final token = await _messaging.getToken();
        debugPrint('[FCM] Token: $token');
        if (token != null) {
          await _saveFcmToken(token);
        }

        _messaging.onTokenRefresh.listen((token) async {
          await _saveFcmToken(token);
          await _syncTopicSubscription();
        });

        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            _messaging.getToken().then((t) {
              if (t != null) _saveFcmToken(t);
            });
            await _syncTopicSubscription();
          } else {
            await _messaging.unsubscribeFromTopic('all_users');
          }
        });

        // Initialize local notification service with tap handler
        await LocalNotificationService().initialize(
          onNotificationTap: _handleLocalNotificationTap,
        );

        // Setup FCM message listeners
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check if app was launched by tapping notification
        _checkInitialMessage();

        _initialized = true;
        debugPrint('[FCM] Initialization complete');
      } else {
        debugPrint('[FCM] Permission denied');
      }
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  Future<void> _syncTopicSubscription() async {
    final settings = await _messaging.getNotificationSettings();
    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!isAuthorized) {
      await _messaging.unsubscribeFromTopic('all_users');
      debugPrint(
          '[FCM] Notification permission denied — unsubscribed from all_users topic');
      return;
    }

    final autoEnabled = await NotificationPrefsRepository().getAutoContent();
    if (autoEnabled) {
      await _messaging.subscribeToTopic('all_users');
      debugPrint('[FCM] Subscribed to all_users topic');
      return;
    }

    await _messaging.unsubscribeFromTopic('all_users');
    debugPrint(
        '[FCM] Auto content disabled — unsubscribed from all_users topic');
  }

  Future<void> refreshTopicSubscription() async {
    try {
      await _syncTopicSubscription();
    } catch (e) {
      debugPrint('[FCM] Failed to refresh topic subscription: $e');
    }
  }

  /// Handle local notification tap (from background message handler)
  void _handleLocalNotificationTap(String? payload) {
    debugPrint('[FCM LocalNotif] Notification tapped with payload: $payload');

    if (payload == null) {
      debugPrint('[FCM LocalNotif] Payload is null');
      return;
    }

    if (_navigatorKey == null) {
      debugPrint('[FCM LocalNotif] Navigator key is null');
      return;
    }

    // Parse pipe-separated payload format: "quoteId|quoteType"
    final parts = payload.split('|');
    debugPrint('[FCM LocalNotif] Payload parts: $parts');

    if (parts.length != 2) {
      debugPrint('[FCM LocalNotif] Invalid payload format (expected 2 parts)');
      return;
    }

    final quoteId = parts[0];
    final quoteType = parts[1];
    final route = '/quotes/$quoteId?type=$quoteType';

    debugPrint('[FCM LocalNotif] Navigating to: $route');

    final context = _navigatorKey!.currentContext;
    if (context != null && context.mounted) {
      context.push(route);
      debugPrint('[FCM LocalNotif] Navigation success');
    } else {
      debugPrint('[FCM LocalNotif] Context is null or not mounted');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'uid': uid, 'fcm_token': token}, SetOptions(merge: true));
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribe() async {
    try {
      await _messaging.unsubscribeFromTopic('all_users');
      debugPrint('[FCM] Unsubscribed from all_users topic');
      _initialized = false;
    } catch (e) {
      debugPrint('[FCM] Unsubscribe error: $e');
    }
  }

  /// Handle foreground messages using system-style local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM Foreground] Message received: ${message.messageId}');
    debugPrint('[FCM Foreground] Data: ${message.data}');

    final notification = message.notification;
    if (notification != null || message.data.isNotEmpty) {
      final title = notification?.title ?? '오늘의 좋은글';
      final body = notification?.body ??
          (message.data['content'] as String?) ??
          '새로운 알림이 도착했습니다';

      final dataImageUrl = message.data['image_url'] as String?;
      debugPrint('[FCM Foreground] Title: ${notification?.title}');
      debugPrint('[FCM Foreground] Body: ${notification?.body}');
      debugPrint(
        '[FCM Foreground] Image: ${notification?.android?.imageUrl ?? notification?.apple?.imageUrl ?? dataImageUrl ?? 'none'}',
      );

      final quoteId = message.data['quote_id'] as String?;
      final quoteType = message.data['quote_type'] as String? ?? 'quote';
      final payload = quoteId != null ? '$quoteId|$quoteType' : null;

      LocalNotificationService().showBigTextNotification(
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  /// Handle message tap (app was in background/terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM Tap] Message opened: ${message.messageId}');
    debugPrint('[FCM Tap] Data: ${message.data}');

    _navigateToQuote(message.data);
  }

  /// Check if app was launched by tapping a notification
  Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      debugPrint(
        '[FCM Initial] App launched from notification: ${message.messageId}',
      );
      debugPrint('[FCM Initial] Data: ${message.data}');

      // Delay navigation until app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToQuote(message.data);
      });
    }
  }

  /// Navigate to quote detail screen based on message data
  void _navigateToQuote(Map<String, dynamic> data) {
    debugPrint('[FCM Navigation] Attempting navigation with data: $data');

    final quoteId = data['quote_id'] as String?;
    final quoteType =
        data['quote_type'] as String? ?? 'quote'; // Default to 'quote'

    if (quoteId == null) {
      debugPrint('[FCM Navigation] Missing quote_id in message data');
      return;
    }

    if (_navigatorKey == null) {
      debugPrint('[FCM Navigation] Navigator key is null');
      return;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null || !context.mounted) {
      debugPrint('[FCM Navigation] Navigator context not available');
      return;
    }

    // Navigate to quote detail screen
    // Route format: /quotes/:id?type=quote|thought|malmoi
    final route = '/quotes/$quoteId?type=$quoteType';
    debugPrint('[FCM Navigation] Navigating to: $route');

    context.push(route);
    debugPrint('[FCM Navigation] Navigation success');
  }
}
