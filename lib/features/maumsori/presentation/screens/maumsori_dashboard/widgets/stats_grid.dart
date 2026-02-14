import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  final VoidCallback onTapAllContent;
  final VoidCallback onTapThoughts;
  final VoidCallback onTapImages;
  final VoidCallback onTapPending;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
    required this.onTapAllContent,
    required this.onTapThoughts,
    required this.onTapImages,
    required this.onTapPending,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      // Slightly taller cards to avoid overflow at smaller widths.
      childAspectRatio: 1.25,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: Icons.format_quote,
          label: '전체 콘텐츠',
          value: '${stats['totalQuotes']}',
          color: AppTheme.primaryPurple,
          onTap: onTapAllContent,
        ),
        _StatCard(
          icon: Icons.article_outlined,
          label: '좋은생각',
          value: '${stats['totalThoughts']}',
          color: Colors.blue,
          onTap: onTapThoughts,
        ),
        _StatCard(
          icon: Icons.image_outlined,
          label: '이미지 자산',
          value: '${stats['totalImages']}',
          color: Colors.green,
          onTap: onTapImages,
        ),
        _StatCard(
          icon: Icons.rate_review_outlined,
          label: '검수 대기',
          value: '${stats['pendingUserPosts']}',
          color: Colors.orange,
          isAlert: (stats['pendingUserPosts'] ?? 0) > 0,
          onTap: onTapPending,
        ),
      ],
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
