import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ads_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../quotes/domain/quote.dart';
import '../../../quotes/presentation/liked_quotes_list_provider.dart';
import '../../../quotes/presentation/feed/widgets/quote_feed_card.dart';

class LikedQuotesScreen extends ConsumerWidget {
  const LikedQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedQuotesAsync = ref.watch(likedQuotesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('좋아요 누른 글'),
        centerTitle: true,
      ),
      body: likedQuotesAsync.when(
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '좋아요 누른 글이 없습니다.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshots.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final snapshot = snapshots[index];
              final quote = Quote(
                id: snapshot.quoteId,
                appId: snapshot.appId,
                type: _parseQuoteType(snapshot.type),
                malmoiLength: MalmoiLength.short,
                content: snapshot.content,
                author: snapshot.author,
                authorName: snapshot.authorName,
                authorPhotoUrl: snapshot.authorPhotoUrl,
                imageUrl: snapshot.imageUrl,
                createdAt: snapshot.likedAt ?? DateTime.now(),
                isUserPost: false,
                likeCount: 0,
                shareCount: 0,
                reportCount: 0,
                reactionCounts: const {},
                userUid: null,
                userProvider: null,
                userId: null,
              );

              return QuoteFeedCard(
                quote: quote,
                onOpenDetail: () async {
                  await ref.read(adsControllerProvider).onOpenDetail();
                  if (!context.mounted) return;
                  context.push('/detail', extra: quote);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '좋아요 누른 글을 불러오지 못했습니다.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  QuoteType _parseQuoteType(String typeString) {
    switch (typeString) {
      case 'quote':
        return QuoteType.quote;
      case 'thought':
        return QuoteType.thought;
      case 'malmoi':
        return QuoteType.malmoi;
      default:
        return QuoteType.quote;
    }
  }
}
