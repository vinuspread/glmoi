import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import 'package:app_admin/core/auth/auth_service.dart';

class RootDashboard extends ConsumerWidget {
  const RootDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = Firebase.app().options.projectId;

    return Scaffold(
      body: AdminBackground(
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppTheme.sidebarDark,
                border: Border(right: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_mosaic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SidebarItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    isActive: true,
                  ),
                  _SidebarItem(icon: Icons.apps_rounded, label: 'All Projects'),
                  _SidebarItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                  ),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        projectId,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: AppTheme.border),
                  _SidebarItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () async {
                      try {
                        await ref.read(authProvider.notifier).logout();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout failed: $e')),
                        );
                        return;
                      }

                      if (!context.mounted) return;
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, size: 20),
                                hintText: 'Search',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Row(
                          children: [
                            Text(
                              'MaumSori Admin',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryPurple,
                              radius: 18,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Board',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _FilterChip(label: 'All Apps', isActive: true),
                              _FilterChip(label: 'Operating'),
                              _FilterChip(label: 'Development'),
                              const Spacer(),
                              const Text(
                                'Sort by: ',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const Text(
                                'Newest',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _AppHorizontalCard(
                            id: 'maumsori',
                            name: '마음소리',
                            description: '시니어 대상 힐링 명언 및 콘텐츠 큐레이션 앱',
                            icon: Icons.favorite,
                            tags: ['Operating', 'Flutter'],
                            metrics: '1.2k Users',
                          ),
                          const SizedBox(height: 12),
                          _AppHorizontalCard(
                            id: 'game_room',
                            name: '게임룸 Admin',
                            description: '미니게임 합산 플레이 데이터 및 사용자 관리',
                            icon: Icons.videogame_asset,
                            tags: ['Development', 'Unity'],
                            metrics: '0.5k Users',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Future<void> Function()? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap == null ? null : () async => await onTap!(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppTheme.primaryPurple : AppTheme.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppTheme.primaryPurple : AppTheme.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AppHorizontalCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<String> tags;
  final String metrics;

  const _AppHorizontalCard({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tags,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    void handleTap() {
      if (id == 'maumsori') {
        context.go('/maumsori');
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('준비 중인 앱입니다.')));
    }

    return InkWell(
      onTap: handleTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryPurple, size: 32),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...tags.map(
                        (tag) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metrics,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
