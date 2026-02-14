import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdService {
  static bool _initialized = false;

  InterstitialAd? _interstitial;
  String _interstitialUnitId = '';
  var _loadingInterstitial = false;
  var _navCount = 0;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
    _loadingInterstitial = false;
  }

  Future<void> _loadInterstitial(String unitId) async {
    if (unitId.trim().isEmpty) return;
    if (_loadingInterstitial) return;
    if (_interstitial != null && _interstitialUnitId == unitId) return;

    _loadingInterstitial = true;
    _interstitialUnitId = unitId;

    await ensureInitialized();

    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial?.dispose();
          _interstitial = ad;
          _loadingInterstitial = false;

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
        },
      ),
    );
  }

  Future<void> prefetchFromConfig(AdConfig config) async {
    if (!config.isInterstitialEnabled) return;
    final unitId = config.interstitialUnitIdForPlatform();
    await _loadInterstitial(unitId);
  }

  Future<void> maybeShowInterstitialForNavigation(AdConfig config) async {
    if (!config.isInterstitialEnabled) return;

    final freq = config.interstitialFrequency;
    if (freq <= 0) return;

    final unitId = config.interstitialUnitIdForPlatform();
    if (unitId.isEmpty) return;

    _navCount += 1;

    // Ensure an ad is being prepared.
    await _loadInterstitial(unitId);

    final shouldShow = _navCount % freq == 0;
    if (!shouldShow) return;

    final ad = _interstitial;
    if (ad == null) return;

    _interstitial = null;
    ad.show();
  }
}
