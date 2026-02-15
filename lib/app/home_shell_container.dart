import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glmoi/core/ads/banner_ad_widget.dart';

import '../features/home/presentation/home_shell_view.dart';

class HomeShellContainer extends ConsumerStatefulWidget {
  const HomeShellContainer({super.key});

  @override
  ConsumerState<HomeShellContainer> createState() => _HomeShellContainerState();
}

class _HomeShellContainerState extends ConsumerState<HomeShellContainer> {
  var _index = 0;

  // FCM initialization moved to app.dart - no need for duplicate init here

  @override
  Widget build(BuildContext context) {
    return HomeShellView(
      index: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      bottomAd: const BottomBannerAd(),
    );
  }
}
