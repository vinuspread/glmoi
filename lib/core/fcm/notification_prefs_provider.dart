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
    await repo.setAutoContent(enabled);

    // FCM topic 구독/해지
    final messaging = FirebaseMessaging.instance;
    if (enabled) {
      await messaging.subscribeToTopic('all_users');
    } else {
      await messaging.unsubscribeFromTopic('all_users');
    }
  }
}
