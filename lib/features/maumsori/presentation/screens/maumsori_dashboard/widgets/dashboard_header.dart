import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '대시보드',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                _QuickLinkButton(
                  label: 'Firebase',
                  icon: Icons.whatshot,
                  color: Colors.orange,
                  onTap: () =>
                      _launchUrl('https://console.firebase.google.com'),
                ),
                const SizedBox(width: 8),
                _QuickLinkButton(
                  label: 'AdMob',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                  onTap: () => _launchUrl(
                    'https://admob.google.com/v2/home?sac=true&authuser=1',
                  ),
                ),
                const SizedBox(width: 8),
                _QuickLinkButton(
                  label: 'Analytics',
                  icon: Icons.analytics,
                  color: Colors.blue,
                  onTap: () => _launchUrl('https://analytics.google.com'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLinkButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
