class AdConfigModel {
  // Legacy key: is_ad_enabled (kept for backward compatibility)
  final bool isInterstitialEnabled;

  // Banner (bottom fixed)
  final bool isBannerEnabled;

  // AdMob unit ids (changeable without app update)
  final String bannerAndroidUnitId;
  final String bannerIosUnitId;
  final String interstitialAndroidUnitId;
  final String interstitialIosUnitId;

  // 트리거 조건별 설정
  final bool triggerOnNavigation;
  final int navigationFrequency; // 화면 이동 N회마다

  final bool triggerOnPost;
  final int postFrequency; // 글 작성 N회마다

  final bool triggerOnShare;
  final int shareFrequency; // 공유 N회마다

  final bool triggerOnExit; // 앱 종료 시

  AdConfigModel({
    this.isInterstitialEnabled = true,
    this.isBannerEnabled = true,
    this.bannerAndroidUnitId = '',
    this.bannerIosUnitId = '',
    this.interstitialAndroidUnitId = '',
    this.interstitialIosUnitId = '',
    this.triggerOnNavigation = true,
    this.navigationFrequency = 15,
    this.triggerOnPost = false,
    this.postFrequency = 5,
    this.triggerOnShare = false,
    this.shareFrequency = 3,
    this.triggerOnExit = false,
  });

  bool get isAdEnabled => isInterstitialEnabled;

  // Legacy: 하위 호환성을 위해 유지
  int get interstitialFrequency => navigationFrequency;

  factory AdConfigModel.fromMap(Map<String, dynamic> map) {
    return AdConfigModel(
      isInterstitialEnabled: map['is_ad_enabled'] ?? true,
      isBannerEnabled: map['is_banner_enabled'] ?? true,
      bannerAndroidUnitId: (map['banner_android_unit_id'] as String?) ?? '',
      bannerIosUnitId: (map['banner_ios_unit_id'] as String?) ?? '',
      interstitialAndroidUnitId:
          (map['interstitial_android_unit_id'] as String?) ?? '',
      interstitialIosUnitId: (map['interstitial_ios_unit_id'] as String?) ?? '',
      triggerOnNavigation: map['trigger_on_navigation'] ?? true,
      navigationFrequency:
          (map['navigation_frequency'] as num?)?.toInt() ??
          (map['interstitial_frequency'] as num?)?.toInt() ??
          15, // 하위 호환
      triggerOnPost: map['trigger_on_post'] ?? false,
      postFrequency: (map['post_frequency'] as num?)?.toInt() ?? 5,
      triggerOnShare: map['trigger_on_share'] ?? false,
      shareFrequency: (map['share_frequency'] as num?)?.toInt() ?? 3,
      triggerOnExit: map['trigger_on_exit'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_ad_enabled': isInterstitialEnabled,
      'is_banner_enabled': isBannerEnabled,
      'banner_android_unit_id': bannerAndroidUnitId,
      'banner_ios_unit_id': bannerIosUnitId,
      'interstitial_android_unit_id': interstitialAndroidUnitId,
      'interstitial_ios_unit_id': interstitialIosUnitId,
      'trigger_on_navigation': triggerOnNavigation,
      'navigation_frequency': navigationFrequency,
      'trigger_on_post': triggerOnPost,
      'post_frequency': postFrequency,
      'trigger_on_share': triggerOnShare,
      'share_frequency': shareFrequency,
      'trigger_on_exit': triggerOnExit,
      // 하위 호환성을 위해 유지
      'interstitial_frequency': navigationFrequency,
    };
  }
}

class AppConfigModel {
  final String minVersion;
  final String latestVersion;
  final bool isMaintenanceMode;
  final String maintenanceMessage;

  // Composer defaults
  final int composerFontSize; // px
  final double composerLineHeight;
  final double composerDimStrength;
  final String composerFontStyle; // gothic | serif

  // Categories
  final List<String> categories;

  AppConfigModel({
    this.minVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.isMaintenanceMode = false,
    this.maintenanceMessage = '서버 점검 중입니다.',

    this.composerFontSize = 24,
    this.composerLineHeight = 1.6,
    this.composerDimStrength = 0.4,
    this.composerFontStyle = 'gothic',

    this.categories = const ['힐링', '응원', '행복', '지혜', '기타'],
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    final parsedCategories = rawCategories is List
        ? rawCategories.whereType<String>().toList()
        : <String>[];

    return AppConfigModel(
      minVersion: map['min_version'] ?? '1.0.0',
      latestVersion: map['latest_version'] ?? '1.0.0',
      isMaintenanceMode: map['is_maintenance_mode'] ?? false,
      maintenanceMessage: map['maintenance_message'] ?? '서버 점검 중입니다.',

      composerFontSize: (map['composer_font_size'] as num?)?.toInt() ?? 24,
      composerLineHeight:
          (map['composer_line_height'] as num?)?.toDouble() ?? 1.6,
      composerDimStrength:
          (map['composer_dim_strength'] as num?)?.toDouble() ?? 0.4,
      composerFontStyle: (map['composer_font_style'] as String?) ?? 'gothic',

      categories: parsedCategories.isEmpty
          ? const ['힐링', '응원', '행복', '지혜', '기타']
          : parsedCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min_version': minVersion,
      'latest_version': latestVersion,
      'is_maintenance_mode': isMaintenanceMode,
      'maintenance_message': maintenanceMessage,

      'composer_font_size': composerFontSize,
      'composer_line_height': composerLineHeight,
      'composer_dim_strength': composerDimStrength,
      'composer_font_style': composerFontStyle,

      'categories': categories,
    };
  }
}

class TermsConfigModel {
  final String termsOfService;
  final String privacyPolicy;

  TermsConfigModel({this.termsOfService = '', this.privacyPolicy = ''});

  factory TermsConfigModel.fromMap(Map<String, dynamic> map) {
    return TermsConfigModel(
      termsOfService: map['terms_of_service'] ?? '',
      privacyPolicy: map['privacy_policy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'terms_of_service': termsOfService,
      'privacy_policy': privacyPolicy,
    };
  }
}

class CompanyInfoModel {
  final String content;

  CompanyInfoModel({this.content = ''});

  factory CompanyInfoModel.fromMap(Map<String, dynamic> map) {
    return CompanyInfoModel(content: map['content'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'content': content};
  }
}
