import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import '../widgets/maumsori_sidebar.dart';
import '../providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'maumsori_dashboard/widgets/dashboard_header.dart';
import 'maumsori_dashboard/widgets/permission_denied_card.dart';
import 'maumsori_dashboard/widgets/stats_grid.dart';
import 'maumsori_dashboard/widgets/activity_stats_section.dart';
import 'maumsori_dashboard/widgets/system_status_card.dart';
import 'maumsori_dashboard/widgets/admob_stats_card.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

class MaumSoriDashboardScreen extends ConsumerWidget {
  const MaumSoriDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityStatsAsync = ref.watch(activityStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/dashboard'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardHeader(),
                    statsAsync.when(
                      data: (stats) => DashboardStatsGrid(
                        stats: stats,
                        onTapAllContent: () => context.go('/maumsori/content'),
                        onTapThoughts: () => context.go('/maumsori/content'),
                        onTapImages: () => context.go('/maumsori/images'),
                        onTapPending: () => context.go('/maumsori/glemoi'),
                        onTapReports: () => context.go('/maumsori/reports'),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) {
                        if (err is FirebaseException &&
                            err.code == 'permission-denied') {
                          final userEmail =
                              FirebaseAuth.instance.currentUser?.email ??
                              '(unknown)';
                          final projectId = Firebase.app().options.projectId;
                          return PermissionDeniedCard(
                            userEmail: userEmail,
                            projectId: projectId,
                          );
                        }
                        return Center(
                          child: SelectableText(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    activityStatsAsync.when(
                      data: (activityStats) =>
                          ActivityStatsSection(stats: activityStats),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          Center(child: Text('활동 통계 로드 실패: $err')),
                    ),
                    const SizedBox(height: 48),
                    const AdMobStatsCard(),
                    const SizedBox(height: 48),
                    const SystemStatusCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
