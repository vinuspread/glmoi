import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feed_header_buttons.dart';
import '../../auth/domain/login_redirect.dart';
import '../../quotes/data/quotes_repository.dart';
import '../../quotes/presentation/feed/widgets/quote_feed_card.dart';
import '../../quotes/presentation/detail/quote_detail_args.dart';

final _quotesRepoProvider = Provider((ref) => QuotesRepository());

final myMalmoiPostsProvider = StreamProvider((ref) {
  return ref.watch(_quotesRepoProvider).watchMyMalmoiPosts();
});

class MalmoiMyPostsScreen extends ConsumerWidget {
  const MalmoiMyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final isLoggedIn = ref.watch(authProvider);
    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('내 글')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: AppTheme.cardDecoration(elevated: true),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 40, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text('로그인이 필요합니다.', style: t.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '내가 작성한 글을 모아보고 수정/삭제할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => context.push(
                        '/login',
                        extra: const LoginRedirect.go('/malmoi/mine'),
                      ),
                      child: const Text('로그인하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final postsAsync = ref.watch(myMalmoiPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 글'),
        actions: const [
          FeedTrailingButton(),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.note_add_outlined,
                      size: 44, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text('작성한 글이 없습니다.', style: t.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/malmoi/write'),
                    icon: const Icon(Icons.edit),
                    label: const Text('글 작성'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final q = posts[i];
              return QuoteFeedCard(
                quote: q,
                onOpenDetail: () async {
                  context.push(
                    '/detail',
                    extra: QuoteDetailArgs(quotes: posts, initialIndex: i),
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
