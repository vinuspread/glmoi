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
        actions: [
          const FeedTrailingButton(),
          if (type == QuoteType.malmoi)
            IconButton(
              tooltip: '내 글',
              onPressed: () {
                if (!isLoggedIn) {
                  context.push('/login',
                      extra: const LoginRedirect.go('/malmoi/mine'));
                  return;
                }
                context.push('/malmoi/mine');
              },
              icon: const Icon(Icons.person_outline),
            ),
        ],
      ),
      floatingActionButton: type == QuoteType.malmoi
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!isLoggedIn) {
                  context.push('/login',
                      extra: const LoginRedirect.go('/malmoi/write'));
                  return;
                }
                context.push('/malmoi/write');
              },
              icon: const Icon(Icons.edit),
              label: const Text('글 작성'),
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

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFAF7F2),
                  Color(0xFFF7F2EA),
                ],
              ),
            ),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final q = quotes[i];
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
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('로드 실패: $e')),
      ),
    );
  }
}
