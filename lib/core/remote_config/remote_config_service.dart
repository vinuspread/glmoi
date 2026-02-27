import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static const _shareLink = 'share_link';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=co.vinus.glmoi';

  /// Remote Config 기본값.
  /// Firebase 콘솔에 값이 없거나 fetch 전이면 여기 값이 사용된다.
  static const _defaults = <String, dynamic>{
    _shareLink: _playStoreUrl,
  };

  /// 앱 시작 시 한 번 호출. 백그라운드 fetch로 앱 시작을 지연시키지 않는다.
  static Future<void> init() async {
    final rc = FirebaseRemoteConfig.instance;

    await rc.setConfigSettings(RemoteConfigSettings(
      // 프로덕션: 12시간 캐시 (Firebase 권장값)
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 12),
    ));

    await rc.setDefaults(_defaults);

    // 백그라운드 fetch: 실패해도 앱 동작에 영향 없음
    rc.fetchAndActivate().ignore();
  }

  /// 공유 링크 URL 반환.
  /// Remote Config에 'share_link' 키가 설정되어 있으면 그 값을 사용.
  /// 미설정이면 기본값 플레이스토어 URL을 반환.
  static String getShareLink() {
    final raw = FirebaseRemoteConfig.instance.getString(_shareLink).trim();
    if (raw.isEmpty) return _playStoreUrl;

    final uri = Uri.tryParse(raw);
    if (uri == null) return _playStoreUrl;

    final host = uri.host.toLowerCase();
    if (host == 'glmoi-prod.web.app') {
      return _playStoreUrl;
    }
    return raw;
  }
}
