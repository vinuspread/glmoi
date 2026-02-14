import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/intro_seen_provider.dart';
import 'intro_screen.dart';
import '../../../app/home_shell_container.dart';

class IntroGate extends ConsumerWidget {
  const IntroGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seenAsync = ref.watch(introSeenProvider);
    return seenAsync.when(
      data: (seen) => seen ? const HomeShellContainer() : const IntroScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Failed to load intro state: $e')),
      ),
    );
  }
}
