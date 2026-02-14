import 'dart:io';

class AdConfig {
  final bool isBannerEnabled;
  final bool isInterstitialEnabled;
  final int interstitialFrequency;

  final String bannerAndroidUnitId;
  final String bannerIosUnitId;
  final String interstitialAndroidUnitId;
  final String interstitialIosUnitId;

  const AdConfig({
    this.isBannerEnabled = true,
    this.isInterstitialEnabled = true,
    this.interstitialFrequency = 5,
    this.bannerAndroidUnitId = '',
    this.bannerIosUnitId = '',
    this.interstitialAndroidUnitId = '',
    this.interstitialIosUnitId = '',
  });

  factory AdConfig.fromMap(Map<String, dynamic> map) {
    return AdConfig(
      // Keep keys aligned with app-admin AdConfigModel.
      isInterstitialEnabled: map['is_ad_enabled'] ?? true,
      interstitialFrequency:
          (map['interstitial_frequency'] as num?)?.toInt() ?? 5,
      isBannerEnabled: map['is_banner_enabled'] ?? true,
      bannerAndroidUnitId: (map['banner_android_unit_id'] as String?) ?? '',
      bannerIosUnitId: (map['banner_ios_unit_id'] as String?) ?? '',
      interstitialAndroidUnitId:
          (map['interstitial_android_unit_id'] as String?) ?? '',
      interstitialIosUnitId: (map['interstitial_ios_unit_id'] as String?) ?? '',
    );
  }

  String bannerUnitIdForPlatform() {
    if (Platform.isAndroid) return bannerAndroidUnitId.trim();
    if (Platform.isIOS) return bannerIosUnitId.trim();
    return '';
  }

  String interstitialUnitIdForPlatform() {
    if (Platform.isAndroid) return interstitialAndroidUnitId.trim();
    if (Platform.isIOS) return interstitialIosUnitId.trim();
    return '';
  }
}
