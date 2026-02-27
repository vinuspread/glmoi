import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_config_provider.dart';
import 'ads_providers.dart';

class BottomBannerAd extends ConsumerStatefulWidget {
  const BottomBannerAd({super.key});

  @override
  ConsumerState<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends ConsumerState<BottomBannerAd> {
  BannerAd? _ad;
  var _loaded = false;
  String _unitId = '';
  ProviderSubscription<AsyncValue<AdConfig>>? _configSub;
  Timer? _retryTimer;

  void _log(String message) {
    debugPrint('[Ads][Banner] $message');
  }

  @override
  void initState() {
    super.initState();

    _configSub = ref.listenManual<AsyncValue<AdConfig>>(
      adConfigProvider,
      (prev, next) {
        next.whenData((config) {
          final unitId = config.bannerUnitIdForPlatform();
          final enabled = config.isBannerEnabled && unitId.isNotEmpty;
          if (!enabled) {
            _log(
              'disabled or missing unit id '
              '(isBannerEnabled=${config.isBannerEnabled}, unitIdEmpty=${unitId.isEmpty})',
            );
            _disposeAd();
            return;
          }
          if (unitId != _unitId) {
            _createAndLoad(unitId);
          }
        });
      },
    );
  }

  void _disposeAd() {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _unitId = '';
    if (mounted) setState(() {});
  }

  Future<void> _createAndLoad(String unitId) async {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _unitId = unitId;
    if (mounted) setState(() {});

    _log('loading banner ad (unitId=$unitId)');

    await ref.read(adServiceProvider).ensureInitialized();
    if (!mounted) return;

    final ad = BannerAd(
      adUnitId: unitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          _log('banner ad loaded successfully');
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          _log(
            'banner ad failed to load '
            '(code=${err.code}, domain=${err.domain}, message=${err.message})',
          );
          final responseId = err.responseInfo?.responseId;
          if (responseId != null && responseId.isNotEmpty) {
            _log('responseId=$responseId');
          }
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _loaded = false;
          });

          // Retry later to avoid permanent "no ad" state.
          _retryTimer?.cancel();
          _retryTimer = Timer(const Duration(seconds: 20), () {
            if (!mounted) return;
            if (_unitId.isEmpty) return;
            _createAndLoad(_unitId);
          });
        },
      ),
    );

    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _configSub?.close();
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(adConfigProvider);
    return configAsync.when(
      data: (config) {
        final unitId = config.bannerUnitIdForPlatform();
        final enabled = config.isBannerEnabled;
        // Always reserve the banner area when enabled, even while loading.
        if (!enabled) return const SizedBox.shrink();

        final height = (_ad?.size.height ?? AdSize.banner.height).toDouble();

        // Config is enabled but missing unit id -> reserve space only.
        if (unitId.isEmpty) {
          return SizedBox(
            width: double.infinity,
            height: height,
          );
        }

        // If config arrived before listener ran.
        if (unitId != _unitId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _createAndLoad(unitId);
          });
        }
        if (!_loaded || _ad == null) {
          return SizedBox(
            width: double.infinity,
            height: height,
          );
        }
        return Container(
          color: Colors.transparent,
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          child: AdWidget(ad: _ad!),
        );
      },
      loading: () => SizedBox(
        width: double.infinity,
        height: AdSize.banner.height.toDouble(),
      ),
      error: (_, __) => SizedBox(
        width: double.infinity,
        height: AdSize.banner.height.toDouble(),
      ),
    );
  }
}
