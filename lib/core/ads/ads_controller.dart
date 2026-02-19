import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_config_provider.dart';
import 'ads_providers.dart';

final adsControllerProvider = Provider<AdsController>((ref) {
  return AdsController(ref);
});

class AdsController {
  final Ref _ref;
  AdsController(this._ref);

  Future<void> onOpenDetail() async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref
        .read(adServiceProvider)
        .maybeShowInterstitialForNavigation(config);
  }

  Future<void> onPostCreated() async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref.read(adServiceProvider).maybeShowInterstitialForPost(config);
  }

  Future<void> onShareCompleted() async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref.read(adServiceProvider).maybeShowInterstitialForShare(config);
  }

  Future<void> onAppExit() async {
    final config = _ref.read(adConfigProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (config == null) return;

    await _ref.read(adServiceProvider).maybeShowInterstitialForExit(config);
  }
}
