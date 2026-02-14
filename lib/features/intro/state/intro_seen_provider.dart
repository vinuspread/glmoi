import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kIntroSeenKey = 'intro_seen_v1';

final introSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kIntroSeenKey) ?? false;
});

final introSeenControllerProvider = Provider((ref) {
  return IntroSeenController(ref);
});

class IntroSeenController {
  final Ref _ref;
  IntroSeenController(this._ref);

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroSeenKey, true);
    _ref.invalidate(introSeenProvider);
  }
}
