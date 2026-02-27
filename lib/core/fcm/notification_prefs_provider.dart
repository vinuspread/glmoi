import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_prefs_repository.dart';

final _notificationPrefsRepoProvider =
    Provider((ref) => NotificationPrefsRepository());

/// 자동수신 여부 스트림 Provider (기본값 true)
final autoContentEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(_notificationPrefsRepoProvider).watchAutoContent();
});

/// 자동수신 설정 Controller
final notificationPrefsControllerProvider =
    Provider((ref) => NotificationPrefsController(ref));

class NotificationPrefsController {
  final Ref _ref;
  NotificationPrefsController(this._ref);

  Future<void> setAutoContent(bool enabled) async {
    final repo = _ref.read(_notificationPrefsRepoProvider);
    final messaging = FirebaseMessaging.instance;

    if (enabled) {
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAuthorized) {
        await repo.setAutoContent(false);
        await messaging.unsubscribeFromTopic('all_users');
        throw Exception('알림 권한이 꺼져 있어 자동수신을 켤 수 없습니다.');
      }

      await repo.setAutoContent(true);
      await messaging.subscribeToTopic('all_users');
      return;
    }

    await repo.setAutoContent(false);
    await messaging.unsubscribeFromTopic('all_users');
  }
}
