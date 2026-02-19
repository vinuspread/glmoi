import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ads/ads_controller.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/quote.dart';

class QuoteFeedCard extends ConsumerWidget {
  final Quote quote;
  final Future<void> Function()? onOpenDetail;

  const QuoteFeedCard({
    super.key,
    required this.quote,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final showImage = quote.imageUrl != null && quote.imageUrl!.isNotEmpty;

    Widget buildQuoteCard() {
      // "한줄명언" list item: rounded image-backed box + 2-line text.
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius24), // Consistent radius
        child: Stack(
          children: [
            if (showImage)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: quote.imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppTheme.surfaceAlt,
                  ),
                ),
              )
            else
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt, // Fallback solid color
                  ),
                ),
              ),
            
            // Stronger gradient for better text readability

            
            // Semi-transparent black overlay for readability
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), // More padding
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  quote.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.headlineSmall?.copyWith( // Larger text style
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    shadows: [
                      const Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildDefaultCard() {
      return Container(
        decoration: AppTheme.cardDecoration(elevated: false),
        child: Padding(
          padding: const EdgeInsets.all(24), // Increased internal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                      child: SizedBox(
                        width: 80, // Slightly larger image thumbnail
                        height: 80,
                        child: CachedNetworkImage(
                          imageUrl: quote.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              (80 * MediaQuery.devicePixelRatioOf(context)).round(),
                          memCacheHeight:
                              (80 * MediaQuery.devicePixelRatioOf(context)).round(),
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: AppTheme.surfaceAlt),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // More spacing
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodyLarge?.copyWith(
                            fontSize: 18, // Ensure 18px
                            fontWeight: FontWeight.w600, // Slightly stronger weight
                            height: 1.6,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if ((quote.authorName ?? quote.author)
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 12), // More spacing
                          Text(
                            '- ${quote.authorName ?? quote.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius24),
      onTap: () async {
        if (onOpenDetail != null) {
          await onOpenDetail!();
          return;
        }
        await ref.read(adsControllerProvider).onOpenDetail();
        if (!context.mounted) return;
        context.push('/detail', extra: quote);
      },
      child:
          quote.type == QuoteType.quote ? buildQuoteCard() : buildDefaultCard(),
    );
  }
}
