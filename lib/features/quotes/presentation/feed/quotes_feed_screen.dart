import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ads/ads_controller.dart';
import '../../../../core/widgets/feed_header_buttons.dart';
import '../../../auth/domain/login_redirect.dart';
import '../../data/quotes_repository.dart';
import '../../domain/quote.dart';
import '../detail/quote_detail_args.dart';
import 'widgets/quote_feed_card.dart';
import 'widgets/quote_list_tile.dart';

final _quotesRepoProvider = Provider((ref) => QuotesRepository());

final quotesFeedProvider = StreamProvider.family<List<Quote>, QuoteType>((
  ref,
  type,
) {
  return ref.watch(_quotesRepoProvider).watchQuotes(type: type);
});

class QuotesFeedScreen extends ConsumerWidget {
  final QuoteType type;
  final String title;

  const QuotesFeedScreen({super.key, required this.type, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(quotesFeedProvider(type));
    final isLoggedIn = ref.watch(authProvider);
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const FeedLeadingButton(),
        leadingWidth: 100,
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: const [
          FeedTrailingButton(),
        ],
      ),
      floatingActionButton: type == QuoteType.malmoi
          ? FloatingActionButton(
              onPressed: () {
                if (!isLoggedIn) {
                  context.push('/login',
                      extra: const LoginRedirect.go('/malmoi/write'));
                  return;
                }
                context.push('/malmoi/write');
              },
              child: const Icon(Icons.edit),
              shape: const CircleBorder(),
            )
          : null,
      body: quotesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 44, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      '콘텐츠가 없습니다.',
                      style: t.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '잠시 후 다시 확인해주세요.',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final isListMode = type == QuoteType.thought || type == QuoteType.malmoi;

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: isListMode 
                ? EdgeInsets.zero 
                : const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => isListMode
                ? const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5))
                : const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final q = quotes[i];
              
              if (isListMode) {
                return QuoteListTile(
                  quote: q,
                  onTap: () async {
                    await ref.read(adsControllerProvider).onOpenDetail();
                    if (!context.mounted) return;
                    context.push(
                      '/detail',
                      extra: QuoteDetailArgs(quotes: quotes, initialIndex: i),
                    );
                  },
                );
              }

              return QuoteFeedCard(
                quote: q,
                onOpenDetail: () async {
                  await ref.read(adsControllerProvider).onOpenDetail();
                  if (!context.mounted) return;
                  context.push(
                    '/detail',
                    extra: QuoteDetailArgs(quotes: quotes, initialIndex: i),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('로드 실패: $e')),
      ),
    );
  }
}
