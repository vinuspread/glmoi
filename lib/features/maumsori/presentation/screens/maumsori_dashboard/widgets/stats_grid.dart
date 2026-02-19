import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  final VoidCallback onTapAllContent;
  final VoidCallback onTapThoughts;
  final VoidCallback onTapImages;
  final VoidCallback onTapPending;
  final VoidCallback onTapReports;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
    required this.onTapAllContent,
    required this.onTapThoughts,
    required this.onTapImages,
    required this.onTapPending,
    required this.onTapReports,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: Icons.format_quote,
          label: '전체 콘텐츠',
          value: '${stats['totalContent']}',
          color: AppTheme.primaryPurple,
          onTap: onTapAllContent,
        ),
        _StatCard(
          icon: Icons.auto_awesome,
          label: '한줄명언',
          value: '${stats['totalQuotes']}',
          color: Colors.blue,
          onTap: onTapAllContent,
        ),
        _StatCard(
          icon: Icons.article_outlined,
          label: '좋은생각',
          value: '${stats['totalThoughts']}',
          color: Colors.teal,
          onTap: onTapThoughts,
        ),
        _StatCard(
          icon: Icons.edit_note,
          label: '글모이',
          value: '${stats['totalMalmoi']}',
          color: Colors.purple,
          onTap: onTapPending,
        ),
        _StatCard(
          icon: Icons.image_outlined,
          label: '배경이미지',
          value: '${stats['totalImages']}',
          color: Colors.green,
          onTap: onTapImages,
        ),
        _ReportStatCard(
          unreadCount: stats['unreadReportCount'] ?? 0,
          totalCount: stats['reportedCount'] ?? 0,
          onTap: onTapReports,
        ),
      ],
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final VoidCallback onTap;

  const _ReportStatCard({
    required this.unreadCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread ? Colors.red.withOpacity(0.5) : AppTheme.border,
            width: hasUnread ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.report_outlined,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // 미확인/전체 표시
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$unreadCount',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: hasUnread ? Colors.red : Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: ' / $totalCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '신고 (미확인/전체)',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final bool isAlert;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAlert ? Colors.red.withOpacity(0.5) : AppTheme.border,
            width: isAlert ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
