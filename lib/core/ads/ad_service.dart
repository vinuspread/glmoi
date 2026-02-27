import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

import 'ad_config.dart';

class AdService {
  static bool _initialized = false;
  static const int navigationPreNoticeLeadSlides = 3;

  InterstitialAd? _interstitial;
  String _interstitialUnitId = '';
  var _loadingInterstitial = false;
  var _navCount = 0;
  var _postCount = 0;
  var _shareCount = 0;
  final ValueNotifier<int?> _navigationPreAdRemainingNotifier =
      ValueNotifier<int?>(null);

  ValueListenable<int?> get navigationPreAdRemainingListenable =>
      _navigationPreAdRemainingNotifier;

  void _log(String message) {
    debugPrint('[Ads][Interstitial] $message');
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
    _loadingInterstitial = false;
    _navigationPreAdRemainingNotifier.dispose();
  }

  Future<void> _loadInterstitial(String unitId) async {
    if (unitId.trim().isEmpty) {
      _log('skip load: empty unit id');
      return;
    }
    if (_loadingInterstitial) return;
    if (_interstitial != null && _interstitialUnitId == unitId) return;

    _loadingInterstitial = true;
    _interstitialUnitId = unitId;
    _log('loading interstitial (unitId=$unitId)');

    await ensureInitialized();

    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial?.dispose();
          _interstitial = ad;
          _loadingInterstitial = false;
          _log('interstitial loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (_interstitial == ad) {
                _interstitial = null;
              }
              // Prefetch next.
              _loadInterstitial(_interstitialUnitId);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (_interstitial == ad) {
                _interstitial = null;
              }
              _loadInterstitial(_interstitialUnitId);
            },
          );
        },
        onAdFailedToLoad: (err) {
          _loadingInterstitial = false;
          _log(
            'interstitial failed to load '
            '(code=${err.code}, domain=${err.domain}, message=${err.message})',
          );
          final responseId = err.responseInfo?.responseId;
          if (responseId != null && responseId.isNotEmpty) {
            _log('responseId=$responseId');
          }
        },
      ),
    );
  }

  Future<void> prefetchFromConfig(AdConfig config) async {
    if (!config.isInterstitialEnabled) return;
    final unitId = config.interstitialUnitIdForPlatform();
    await _loadInterstitial(unitId);
  }

  Future<void> maybeShowInterstitialForNavigation(
    AdConfig config, {
    Future<void> Function()? beforeShow,
  }) async {
    if (!config.isInterstitialEnabled) {
      _navigationPreAdRemainingNotifier.value = null;
      return;
    }
    if (!config.triggerOnNavigation) {
      _navigationPreAdRemainingNotifier.value = null;
      return;
    }

    final freq = config.navigationFrequency;
    if (freq <= 0) {
      _navigationPreAdRemainingNotifier.value = null;
      return;
    }

    final unitId = config.interstitialUnitIdForPlatform();
    if (unitId.isEmpty) {
      _navigationPreAdRemainingNotifier.value = null;
      return;
    }

    _navCount += 1;

    final remainder = _navCount % freq;
    final shouldShow = remainder == 0;
    final remainingSlides = shouldShow ? 0 : (freq - remainder);

    if (remainingSlides > 0 &&
        remainingSlides <= navigationPreNoticeLeadSlides) {
      _navigationPreAdRemainingNotifier.value = remainingSlides;
    } else {
      _navigationPreAdRemainingNotifier.value = null;
    }

    // Ensure an ad is being prepared.
    await _loadInterstitial(unitId);

    if (!shouldShow) return;

    _navigationPreAdRemainingNotifier.value = null;

    final ad = _interstitial;
    if (ad == null) return;

    _interstitial = null;
    await beforeShow?.call();
    ad.show();
  }

  Future<void> maybeShowInterstitialForPost(
    AdConfig config, {
    Future<void> Function()? beforeShow,
  }) async {
    if (!config.isInterstitialEnabled) return;
    if (!config.triggerOnPost) return;

    final freq = config.postFrequency;
    if (freq <= 0) return;

    final unitId = config.interstitialUnitIdForPlatform();
    if (unitId.isEmpty) return;

    _postCount += 1;

    await _loadInterstitial(unitId);

    final shouldShow = _postCount % freq == 0;
    if (!shouldShow) return;

    final ad = _interstitial;
    if (ad == null) return;

    _interstitial = null;
    await beforeShow?.call();
    ad.show();
  }

  Future<void> maybeShowInterstitialForShare(
    AdConfig config, {
    Future<void> Function()? beforeShow,
  }) async {
    if (!config.isInterstitialEnabled) return;
    if (!config.triggerOnShare) return;

    final freq = config.shareFrequency;
    if (freq <= 0) return;

    final unitId = config.interstitialUnitIdForPlatform();
    if (unitId.isEmpty) return;

    _shareCount += 1;

    await _loadInterstitial(unitId);

    final shouldShow = _shareCount % freq == 0;
    if (!shouldShow) return;

    final ad = _interstitial;
    if (ad == null) return;

    _interstitial = null;
    await beforeShow?.call();
    ad.show();
  }

  Future<bool> maybeShowInterstitialForExit(AdConfig config) async {
    if (!config.isInterstitialEnabled) {
      _log('exit show skipped: interstitial disabled');
      return false;
    }
    if (!config.triggerOnExit) {
      _log('exit show skipped: triggerOnExit disabled');
      return false;
    }

    final unitId = config.interstitialUnitIdForPlatform();
    if (unitId.isEmpty) {
      _log('exit show skipped: empty unit id');
      return false;
    }

    await _loadInterstitial(unitId);

    final ad = _interstitial;
    if (ad == null) {
      _log('exit show skipped: no ready interstitial instance');
      return false;
    }

    _interstitial = null;
    final dismissed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _log('interstitial dismissed');
        ad.dispose();
        if (_interstitial == ad) {
          _interstitial = null;
        }
        _loadInterstitial(_interstitialUnitId);
        if (!dismissed.isCompleted) {
          dismissed.complete();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _log(
          'interstitial failed to show '
          '(code=${err.code}, domain=${err.domain}, message=${err.message})',
        );
        ad.dispose();
        if (_interstitial == ad) {
          _interstitial = null;
        }
        _loadInterstitial(_interstitialUnitId);
        if (!dismissed.isCompleted) {
          dismissed.complete();
        }
      },
    );

    ad.show();
    _log('interstitial show requested');
    await dismissed.future
        .timeout(const Duration(seconds: 12), onTimeout: () {});
    return true;
  }
}
