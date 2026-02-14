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
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        child: Stack(
          children: [
            if (showImage)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: quote.imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  // NOTE: Avoid forcing cache width/height here.
                  // Some image backends can decode to an exact (w,h) and make the
                  // image look squished. Let BoxFit.cover do a center crop.
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppTheme.surfaceAlt,
                  ),
                ),
              )
            else
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF2EDE4),
                        Color(0xFFE8E0D4),
                      ],
                    ),
                  ),
                ),
              ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x1A000000),
                      Color(0x66000000),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  quote.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleMedium?.copyWith(
                    color: showImage ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intentionally hide the "유저 글" label.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: CachedNetworkImage(
                          imageUrl: quote.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              (76 * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          memCacheHeight:
                              (76 * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: AppTheme.surfaceAlt),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            fontWeight: FontWeight.w700,
                            height: 1.55,
                          ),
                        ),
                        if (quote.author.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            quote.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(AppTheme.radius20),
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
