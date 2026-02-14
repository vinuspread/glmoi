class AdConfigModel {
  // Legacy key: is_ad_enabled (kept for backward compatibility)
  final bool isInterstitialEnabled;
  final int interstitialFrequency; // 전면 광고 노출 빈도 (N회 마다)

  // Banner (bottom fixed)
  final bool isBannerEnabled;

  // AdMob unit ids (changeable without app update)
  final String bannerAndroidUnitId;
  final String bannerIosUnitId;
  final String interstitialAndroidUnitId;
  final String interstitialIosUnitId;

  AdConfigModel({
    this.isInterstitialEnabled = true,
    this.interstitialFrequency = 5,
    this.isBannerEnabled = true,
    this.bannerAndroidUnitId = '',
    this.bannerIosUnitId = '',
    this.interstitialAndroidUnitId = '',
    this.interstitialIosUnitId = '',
  });

  bool get isAdEnabled => isInterstitialEnabled;

  factory AdConfigModel.fromMap(Map<String, dynamic> map) {
    return AdConfigModel(
      isInterstitialEnabled: map['is_ad_enabled'] ?? true,
      interstitialFrequency: map['interstitial_frequency'] ?? 5,
      isBannerEnabled: map['is_banner_enabled'] ?? true,
      bannerAndroidUnitId: (map['banner_android_unit_id'] as String?) ?? '',
      bannerIosUnitId: (map['banner_ios_unit_id'] as String?) ?? '',
      interstitialAndroidUnitId:
          (map['interstitial_android_unit_id'] as String?) ?? '',
      interstitialIosUnitId: (map['interstitial_ios_unit_id'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_ad_enabled': isInterstitialEnabled,
      'interstitial_frequency': interstitialFrequency,
      'is_banner_enabled': isBannerEnabled,
      'banner_android_unit_id': bannerAndroidUnitId,
      'banner_ios_unit_id': bannerIosUnitId,
      'interstitial_android_unit_id': interstitialAndroidUnitId,
      'interstitial_ios_unit_id': interstitialIosUnitId,
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
