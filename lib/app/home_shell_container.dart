import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:glmoi/core/ads/banner_ad_widget.dart';
import 'package:glmoi/core/ads/ads_controller.dart';
import 'package:glmoi/core/ads/ad_config.dart';
import 'package:glmoi/core/ads/ad_config_provider.dart';
import 'package:glmoi/core/ads/ads_providers.dart';

import '../features/home/presentation/home_shell_view.dart';

class HomeShellContainer extends ConsumerStatefulWidget {
  const HomeShellContainer({super.key});

  @override
  ConsumerState<HomeShellContainer> createState() => _HomeShellContainerState();
}

class _HomeShellContainerState extends ConsumerState<HomeShellContainer> {
  var _index = 0;
  ProviderSubscription<AsyncValue<AdConfig>>? _adConfigSub;

  // FCM initialization moved to app.dart - no need for duplicate init here

  @override
  void initState() {
    super.initState();
    _adConfigSub = ref.listenManual<AsyncValue<AdConfig>>(
      adConfigProvider,
      (prev, next) {
        next.whenData((config) async {
          await ref.read(adServiceProvider).prefetchFromConfig(config);
        });
      },
    );
  }

  @override
  void dispose() {
    _adConfigSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(adsControllerProvider).onAppExit();
        await SystemNavigator.pop();
      },
      child: HomeShellView(
        index: _index,
        onIndexChanged: (i) => setState(() => _index = i),
        bottomAd: const BottomBannerAd(),
      ),
    );
  }
}
