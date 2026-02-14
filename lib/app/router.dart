import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/intro/presentation/intro_gate.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/email_signup_screen.dart';
import '../features/auth/domain/login_redirect.dart';
import 'home_shell_container.dart';
import '../features/malmoi/presentation/malmoi_edit_screen.dart';
import '../features/malmoi/presentation/malmoi_my_posts_screen.dart';
import '../features/malmoi/presentation/malmoi_write_screen.dart';
import '../features/quotes/presentation/detail/quote_detail_args.dart';
import '../features/quotes/presentation/detail/quote_detail_pager_screen.dart';
import '../features/quotes/presentation/detail/quote_detail_screen.dart';
import '../features/quotes/domain/quote.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/profile/presentation/screens/mypage_screen.dart';
import '../features/profile/presentation/screens/saved_quotes_screen.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final navKey = ref.watch(rootNavigatorKeyProvider);
  return GoRouter(
    navigatorKey: navKey,
    initialLocation: '/intro',
    routes: [
      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroGate(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra;
          final redirect = extra is LoginRedirect ? extra : null;
          return LoginScreen(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extra = state.extra;
          final redirect = extra is LoginRedirect ? extra : null;
          return EmailSignUpScreen(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellContainer(),
      ),
      GoRoute(
        path: '/malmoi/write',
        builder: (context, state) => const MalmoiWriteScreen(),
      ),
      GoRoute(
        path: '/malmoi/mine',
        builder: (context, state) => const MalmoiMyPostsScreen(),
      ),
      GoRoute(
        path: '/malmoi/edit',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Quote) {
            return MalmoiEditScreen(quote: extra);
          }
          return const _RouteErrorScreen(message: 'Missing quote');
        },
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is QuoteDetailArgs) {
            return QuoteDetailPagerScreen(args: extra);
          }
          if (extra is Quote) {
            // Fallback when list context is not provided.
            return QuoteDetailScreen(quote: extra);
          }
          return const _RouteErrorScreen(message: 'Missing quote');
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/mypage',
        builder: (context, state) => const MyPageScreen(),
      ),
      GoRoute(
        path: '/saved-quotes',
        builder: (context, state) => const SavedQuotesScreen(),
      ),
    ],
  );
});

class _RouteErrorScreen extends StatelessWidget {
  final String message;
  const _RouteErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(message)),
    );
  }
}
