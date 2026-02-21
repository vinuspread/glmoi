import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/auth/auth_service.dart';
import 'package:app_admin/features/auth/presentation/screens/login_screen.dart';
import 'package:app_admin/features/dashboard/presentation/screens/root_dashboard.dart';
import 'package:app_admin/features/maumsori/presentation/screens/content_list_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/content_composer_screen.dart';

import 'package:app_admin/features/maumsori/presentation/screens/maumsori_dashboard_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/image_pool_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/ad_management_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/member_management_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/report_management_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/auto_send_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/settings_screen.dart';
import 'package:app_admin/features/maumsori/presentation/screens/push_test_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) {
      final bool isLoggedIn = authService.isLoggedIn;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const RootDashboard(),
      ),
      GoRoute(
        path: '/maumsori',
        name: 'maumsori',
        redirect: (context, state) {
          if (state.fullPath == '/maumsori') {
            return '/maumsori/dashboard';
          }
          return null;
        },

        routes: [
          GoRoute(
            path: 'dashboard',
            name: 'maumsori_dashboard',
            builder: (context, state) => const MaumSoriDashboardScreen(),
          ),
          GoRoute(
            path: 'content',
            name: 'maumsori_content',
            builder: (context, state) => const ContentListScreen(),
          ),
          GoRoute(
            path: 'compose',
            name: 'maumsori_compose',
            builder: (context, state) {
              final type = state.uri.queryParameters['type'];
              return ContentComposerScreen(initialTypeRaw: type);
            },
          ),
          GoRoute(
            path: 'content/:id/edit',
            name: 'maumsori_content_edit',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ContentComposerScreen(quoteId: id);
            },
          ),
          GoRoute(
            path: 'images',
            name: 'maumsori_images',
            builder: (context, state) => const ImagePoolScreen(),
          ),
          GoRoute(
            path: 'ads',
            name: 'maumsori_ads',
            builder: (context, state) => const AdManagementScreen(),
          ),
          GoRoute(
            path: 'members',
            name: 'maumsori_members',
            builder: (context, state) => const MemberManagementScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'maumsori_reports',
            builder: (context, state) => const ReportManagementScreen(),
          ),
          GoRoute(
            path: 'auto-send',
            name: 'maumsori_auto_send',
            builder: (context, state) => const AutoSendScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'maumsori_settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'push-test',
            name: 'maumsori_push_test',
            builder: (context, state) => const PushTestScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
