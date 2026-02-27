import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_config_provider.dart';
import 'ad_countdown_overlay.dart';
import 'ads_providers.dart';

final adsControllerProvider = Provider<AdsController>((ref) {
  return AdsController(ref);
});

class AdsController {
  final Ref _ref;
  AdsController(this._ref);

  Future<void> onOpenDetail(BuildContext? context) async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref.read(adServiceProvider).maybeShowInterstitialForNavigation(
          config,
          beforeShow: context != null && context.mounted
              ? () => showAdCountdownOverlay(context)
              : null,
        );
  }

  Future<void> onPostCreated(BuildContext? context) async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref.read(adServiceProvider).maybeShowInterstitialForPost(
          config,
          beforeShow: context != null && context.mounted
              ? () => showAdCountdownOverlay(context)
              : null,
        );
  }

  Future<void> onShareCompleted(BuildContext? context) async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref.read(adServiceProvider).maybeShowInterstitialForShare(
          config,
          beforeShow: context != null && context.mounted
              ? () => showAdCountdownOverlay(context)
              : null,
        );
  }

  Future<bool> onAppExit() async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return false;

    // 앱 종료 시에는 overlay 없이 바로 표시
    return _ref.read(adServiceProvider).maybeShowInterstitialForExit(config);
  }
}
