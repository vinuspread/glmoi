import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import '../../../domain/quote.dart';

class QuoteListTile extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;

  const QuoteListTile({
    super.key,
    required this.quote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final showImage = quote.imageUrl != null && quote.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8), // Smaller radius for list
                child: SizedBox(
                  width: 60, // Smaller image for list
                  height: 60,
                  child: CachedNetworkImage(
                    imageUrl: quote.imageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: (60 * MediaQuery.devicePixelRatioOf(context)).round(),
                    memCacheHeight: (60 * MediaQuery.devicePixelRatioOf(context)).round(),
                    errorWidget: (_, __, ___) => const ColoredBox(color: AppTheme.surfaceAlt),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((quote.authorName ?? quote.author).trim().isNotEmpty)
                        Expanded(
                          child: Text(
                            '- ${quote.authorName ?? quote.author} -',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                        
                      // Stats Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like
                          const Icon(Icons.favorite_border, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${quote.likeCount}',
                            style: t.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          
                          // Share
                          const Icon(Icons.share_outlined, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${quote.shareCount}',
                            style: t.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
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
