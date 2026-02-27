import 'dart:io';

import 'package:flutter/foundation.dart';

class AdConfig {
  final bool isBannerEnabled;
  final bool isInterstitialEnabled;
  final int interstitialFrequency;

  final String bannerAndroidUnitId;
  final String bannerIosUnitId;
  final String interstitialAndroidUnitId;
  final String interstitialIosUnitId;

  // 트리거 조건별 설정
  final bool triggerOnNavigation;
  final int navigationFrequency;
  final bool triggerOnPost;
  final int postFrequency;
  final bool triggerOnShare;
  final int shareFrequency;
  final bool triggerOnExit;

  const AdConfig({
    this.isBannerEnabled = true,
    this.isInterstitialEnabled = true,
    this.interstitialFrequency = 5,
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
      // 트리거 조건 파싱
      triggerOnNavigation: map['trigger_on_navigation'] ?? true,
      navigationFrequency: (map['navigation_frequency'] as num?)?.toInt() ?? 15,
      triggerOnPost: map['trigger_on_post'] ?? false,
      postFrequency: (map['post_frequency'] as num?)?.toInt() ?? 5,
      triggerOnShare: map['trigger_on_share'] ?? false,
      shareFrequency: (map['share_frequency'] as num?)?.toInt() ?? 3,
      triggerOnExit: map['trigger_on_exit'] ?? false,
    );
  }

  static const String _googleTestPublisherPrefix =
      'ca-app-pub-3940256099942544/';

  static bool _isGoogleTestAdUnit(String unitId) {
    return unitId.trim().startsWith(_googleTestPublisherPrefix);
  }

  static String _sanitizeUnitIdForBuild(String unitId) {
    final trimmed = unitId.trim();
    if (trimmed.isEmpty) return '';

    if (kReleaseMode && _isGoogleTestAdUnit(trimmed)) {
      return '';
    }

    return trimmed;
  }

  String bannerUnitIdForPlatform() {
    if (Platform.isAndroid) {
      return _sanitizeUnitIdForBuild(bannerAndroidUnitId);
    }
    if (Platform.isIOS) {
      return _sanitizeUnitIdForBuild(bannerIosUnitId);
    }
    return '';
  }

  String interstitialUnitIdForPlatform() {
    if (Platform.isAndroid) {
      return _sanitizeUnitIdForBuild(interstitialAndroidUnitId);
    }
    if (Platform.isIOS) {
      return _sanitizeUnitIdForBuild(interstitialIosUnitId);
    }
    return '';
  }
}
