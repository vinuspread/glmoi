import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class MaumSoriSidebar extends StatelessWidget {
  final String activeRoute;

  const MaumSoriSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '마음소리 Admin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarSection(context, '콘텐츠', [
            _SidebarItem(
              icon: Icons.dashboard_outlined,
              label: '대시보드',
              route: '/maumsori/dashboard',
              isActive: activeRoute == '/maumsori/dashboard',
            ),
            _SidebarItem(
              icon: Icons.list_alt,
              label: '글 목록',
              route: '/maumsori/content',
              isActive: activeRoute == '/maumsori/content',
            ),
            _SidebarItem(
              icon: Icons.edit_note,
              label: '글 작성',
              route: '/maumsori/compose',
              isActive: activeRoute == '/maumsori/compose',
            ),
            _SidebarItem(
              icon: Icons.image_outlined,
              label: '이미지 풀',
              route: '/maumsori/images',
              isActive: activeRoute == '/maumsori/images',
            ),
          ]),
          const SizedBox(height: 24),
          _buildSidebarSection(context, '관리', [
            _SidebarItem(
              icon: Icons.manage_accounts_outlined,
              label: '회원 관리',
              route: '/maumsori/members',
              isActive: activeRoute == '/maumsori/members',
            ),
            _SidebarItem(
              icon: Icons.report_outlined,
              label: '신고 관리',
              route: '/maumsori/reports',
              isActive: activeRoute == '/maumsori/reports',
            ),
            _SidebarItem(
              icon: Icons.schedule_send,
              label: '자동발송',
              route: '/maumsori/auto-send',
              isActive: activeRoute == '/maumsori/auto-send',
            ),
            _SidebarItem(
              icon: Icons.ads_click,
              label: '광고 관리',
              route: '/maumsori/ads',
              isActive: activeRoute == '/maumsori/ads',
            ),
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: '설정',
              route: '/maumsori/settings',
              isActive: activeRoute == '/maumsori/settings',
            ),
            // _SidebarItem(
            //   icon: Icons.notifications_outlined,
            //   label: '알림 테스트',
            //   route: '/maumsori/push-test',
            //   isActive: activeRoute == '/maumsori/push-test',
            // ),
          ]),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('대시보드로'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? AppTheme.primaryPurple
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryPurple
                        : AppTheme.textSecondary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
