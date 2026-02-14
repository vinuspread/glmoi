import 'package:flutter/material.dart';
import 'package:glmoi/core/theme/app_theme.dart';

class TextCurationCard extends StatelessWidget {
  final String content;
  final String author;
  final VoidCallback onTap;

  const TextCurationCard({
    super.key,
    required this.content,
    required this.author,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Decorative quote icon (subtle)
            const Icon(
              Icons.format_quote_rounded,
              size: 24,
              color: Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 12),

            // Content (Max 2 lines)
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontSize: 22,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Author / Date (subtle)
            Text(
              author,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
