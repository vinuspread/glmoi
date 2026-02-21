import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ads_controller.dart';
import '../../../../core/ads/banner_ad_widget.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/share/kakao_talk_share_service.dart';
import '../../../../core/share/share_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/interactions_repository.dart';
import '../../data/quotes_repository.dart';
import '../liked_quotes_provider.dart';
import '../saved_quotes_provider.dart';
import '../../domain/quote.dart';
import '../../../reactions/domain/reaction_type.dart';
import '../../../reactions/presentation/providers/my_reaction_provider.dart';
import 'quote_detail_args.dart';
import 'quote_detail_screen.dart';

final _interactionsRepoProvider = Provider((ref) => InteractionsRepository());
final _quotesRepoProvider = Provider((ref) => QuotesRepository());

class QuoteDetailPagerScreen extends ConsumerStatefulWidget {
  final QuoteDetailArgs args;

  const QuoteDetailPagerScreen({super.key, required this.args});

  @override
  ConsumerState<QuoteDetailPagerScreen> createState() =>
      _QuoteDetailPagerScreenState();
}

class _QuoteDetailPagerScreenState
    extends ConsumerState<QuoteDetailPagerScreen> {
  static const _bannerHeight = 50.0;
  static const _defaultBottomOverlayPadding = 148.0;
  static const _reportReasons = <(String code, String label)>[
    ('spam_ad', '스팸/광고'),
    ('hate', '욕설/혐오'),
    ('sexual', '음란/선정'),
    ('privacy', '개인정보'),
    ('etc', '기타'),
  ];

  late final PageController _controller;
  late final List<Quote> _quotes;
  late int _index;
  Timer? _hideActionsTimer;
  var _actionsVisible = true;

  @override
  void initState() {
    super.initState();
    _quotes = List<Quote>.of(widget.args.quotes);
    _index = widget.args.initialIndex.clamp(0, _quotes.length - 1);
    _controller = PageController(initialPage: _index);
    _scheduleAutoHideActions();
  }

  @override
  void dispose() {
    _hideActionsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoHideActions() {
    _hideActionsTimer?.cancel();
    _hideActionsTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _actionsVisible = false);
    });
  }

  void _revealActions() {
    if (!_actionsVisible) {
      setState(() => _actionsVisible = true);
    }
    _scheduleAutoHideActions();
  }

  void _showReactionAnimation(String assetPath) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ReactionAnimationOverlay(
        assetPath: assetPath,
        onComplete: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  Quote get _current => _quotes[_index];

  Future<String?> _pickReportReason(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  '신고 사유를 선택하세요',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final r in _reportReasons)
                ListTile(
                  title: Text(r.$2),
                  onTap: () => Navigator.pop(context, r.$1),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = _current;
    final isLoggedIn = ref.watch(authProvider);
    final isLiked = ref.watch(
      likedQuotesProvider.select((s) => s.contains(quote.id)),
    );
    final isSaved = ref.watch(isSavedProvider(quote.id)).value ?? false;

    final showReactions = quote.type == QuoteType.malmoi;
    final myReaction = showReactions
        ? ref.watch(myReactionProvider(quote.id)).valueOrNull
        : null;

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final thoughtBottomOverlayPadding = safeBottom + _bannerHeight + 16;

    final currentUid = ref.watch(authUidProvider).valueOrNull;
    final isOwner = currentUid != null &&
        quote.type == QuoteType.malmoi &&
        quote.isUserPost &&
        ((quote.userUid != null && quote.userUid == currentUid) ||
            (quote.userProvider == 'firebase' && quote.userId == currentUid));

    final hasImage = quote.imageUrl != null && quote.imageUrl!.isNotEmpty;
    // Adaptive colors
    final pillBgColor =
        hasImage ? const Color(0x4DFFFFFF) : const Color(0x14000000);
    final pillIconColor = hasImage ? Colors.white : AppTheme.textPrimary;

    debugPrint(
        '[QuoteDetailPager] quote.id=${quote.id}, type=${quote.type}, showReactions=$showReactions, myReaction=$myReaction');

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _revealActions,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _quotes.length,
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              onPageChanged: (i) {
                setState(() {
                  _index = i;
                });
                // 슬라이드로 다음/이전 글 이동 시도 화면이동 횟수 광고 트리거
                ref.read(adsControllerProvider).onOpenDetail();
              },
              itemBuilder: (context, index) {
                final q = _quotes[index];
                final bottomOverlayPadding = q.type == QuoteType.thought
                    ? thoughtBottomOverlayPadding
                    : _defaultBottomOverlayPadding;

                final child = QuoteDetailScreen(
                  quote: q,
                  showChrome: false,
                  bottomOverlayPadding: bottomOverlayPadding,
                );

                // Add a subtle, natural motion to page flicking.
                return AnimatedBuilder(
                  animation: _controller,
                  child: child,
                  builder: (context, child) {
                    final page = _controller.hasClients
                        ? (_controller.page ?? _index.toDouble())
                        : _index.toDouble();
                    final delta = (page - index).abs().clamp(0.0, 1.0);

                    // 1.0 when centered, down to ~0.0 when one page away.
                    final focus = Curves.easeOutCubic.transform(1 - delta);

                    final scale = 0.965 + (0.035 * focus);
                    final translateY = 18 * (1 - focus);
                    final opacity = 0.90 + (0.10 * focus);

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, translateY),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Fixed top controls (pinned)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      _TopPillButton(
                        label: '닫기',
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: pillBgColor,
                        textColor: pillIconColor,
                      ),
                      const Spacer(),
                      if (!isOwner && quote.type == QuoteType.malmoi)
                        _TopPillButton(
                          label: '신고',
                          backgroundColor: pillBgColor,
                          textColor: pillIconColor,
                          onPressed: () async {
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            final reasonCode = await _pickReportReason(context);
                            if (reasonCode == null) return;
                            if (!context.mounted) return;

                            try {
                              final alreadyReported = await ref
                                  .read(_interactionsRepoProvider)
                                  .reportMalmoiOnce(
                                    quoteId: quote.id,
                                    reasonCode: reasonCode,
                                  );
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    alreadyReported
                                        ? '이미 신고한 글입니다.'
                                        : '신고가 접수되었습니다.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('신고 실패: $e')),
                              );
                            }
                          },
                        ),
                      if (!isOwner && quote.type == QuoteType.malmoi)
                        const SizedBox(width: 8),
                      if (showReactions)
                        _TopReactionButton(
                          quote: quote,
                          myReaction: myReaction,
                          backgroundColor: pillBgColor,
                          textColor: pillIconColor,
                          onReact: (reaction, assetPath) async {
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }

                            if (myReaction != null) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이미 공감을 남겼어요.'),
                                ),
                              );
                              return;
                            }

                            _showReactionAnimation(assetPath);

                            // Optimistic UI update
                            final key = reactionTypeToFirestore(reaction);
                            final prevCount = quote.reactionCounts[key] ?? 0;
                            setState(() {
                              _quotes[_index] = quote.copyWith(
                                reactionCounts: {
                                  ...quote.reactionCounts,
                                  key: prevCount + 1,
                                },
                              );
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final (already, _) = await ref
                                  .read(reactionsRepositoryProvider)
                                  .reactToQuoteOnce(
                                    quoteId: quote.id,
                                    reactionType: reaction,
                                  );
                              if (!context.mounted) return;
                              if (already) {
                                // Rollback
                                setState(() {
                                  _quotes[_index] = quote.copyWith(
                                    reactionCounts: {
                                      ...quote.reactionCounts,
                                      key: prevCount,
                                    },
                                  );
                                });
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('이미 공감을 남겼어요.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Rollback on error
                              if (context.mounted) {
                                setState(() {
                                  _quotes[_index] = quote.copyWith(
                                    reactionCounts: {
                                      ...quote.reactionCounts,
                                      key: prevCount,
                                    },
                                  );
                                });
                                messenger.showSnackBar(
                                  SnackBar(content: Text('공감 실패: $e')),
                                );
                              }
                            }
                          },
                        ),
                      if (showReactions) const SizedBox(width: 8),
                      if (isOwner)
                        _TopPillButton(
                          label: '수정',
                          backgroundColor: pillBgColor,
                          textColor: pillIconColor,
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final updatedContent = await context.push<String>(
                              '/malmoi/edit',
                              extra: quote,
                            );
                            if (updatedContent == null) return;
                            if (!context.mounted) return;
                            setState(() {
                              _quotes[_index] = _quotes[_index]
                                  .copyWith(content: updatedContent);
                            });
                            messenger.showSnackBar(
                              const SnackBar(content: Text('수정되었습니다.')),
                            );
                          },
                        ),
                      if (isOwner)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _TopPillButton(
                            label: '삭제',
                            backgroundColor: pillBgColor,
                            textColor: const Color(0xFFFCA5A5),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('삭제할까요?'),
                                    content: const Text('삭제하면 복구할 수 없습니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('취소'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('삭제'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (ok != true) return;
                              try {
                                await ref
                                    .read(_quotesRepoProvider)
                                    .deleteMalmoiPost(quoteId: quote.id);
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('삭제되었습니다.')),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('삭제 실패: $e')),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed bottom action bar (pinned)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: _actionsVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: IgnorePointer(
                        ignoring: !_actionsVisible,
                        child: QuoteDetailActionBar(
                          isLiked: isLiked,
                          isSaved: isSaved,
                          likeCount: quote.likeCount,
                          shareCount: quote.shareCount,
                          isLightMode: !hasImage,
                          onLike: () async {
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }

                            if (isLiked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이미 좋아요한 글입니다.'),
                                ),
                              );
                              return;
                            }

                            ref
                                .read(likedQuotesProvider.notifier)
                                .markLiked(quote.id);
                            setState(() {
                              _quotes[_index] = quote.copyWith(
                                likeCount: quote.likeCount + 1,
                              );
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final alreadyLiked = await ref
                                  .read(_interactionsRepoProvider)
                                  .likeQuoteOnce(quoteId: quote.id);
                              if (!context.mounted) return;
                              if (alreadyLiked) {
                                ref
                                    .read(likedQuotesProvider.notifier)
                                    .unmarkLiked(quote.id);
                                setState(() {
                                  _quotes[_index] = quote.copyWith(
                                    likeCount: quote.likeCount - 1,
                                  );
                                });
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('이미 좋아요한 글입니다.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ref
                                  .read(likedQuotesProvider.notifier)
                                  .unmarkLiked(quote.id);
                              setState(() {
                                _quotes[_index] = quote.copyWith(
                                  likeCount: quote.likeCount - 1,
                                );
                              });
                              messenger.showSnackBar(
                                SnackBar(content: Text('좋아요 실패: $e')),
                              );
                            }
                          },
                          onSave: () async {
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }

                            final controller =
                                ref.read(savedQuotesControllerProvider);

                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final saved = await controller.toggleSave(quote);
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(saved ? '담았습니다' : '담기 취소'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              await controller.toggleSave(quote);
                              messenger.showSnackBar(
                                SnackBar(content: Text('담기 실패: $e')),
                              );
                            }
                          },
                          onShare: () async {
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }
                            final author =
                                (quote.authorName ?? quote.author).trim();
                            final plainText = author.isEmpty
                                ? quote.content
                                : '${quote.content}\n\n- $author -';

                            final shared = await showShareSheet(
                              context: context,
                              content: KakaoTalkShareContent(
                                text: plainText,
                                title: '좋은 글 모음',
                                description: quote.content,
                                imageUrl: quote.imageUrl,
                                likeCount: quote.likeCount,
                                shareCount: quote.shareCount,
                              ),
                              plainText: plainText,
                            );

                            if (!shared) return;
                            if (!context.mounted) return;

                            // Optimistic UI update after share
                            setState(() {
                              _quotes[_index] = quote.copyWith(
                                shareCount: quote.shareCount + 1,
                              );
                            });

                            await ref
                                .read(_interactionsRepoProvider)
                                .incrementShareCount(quoteId: quote.id);

                            // 공유 후 광고 트리거
                            await ref
                                .read(adsControllerProvider)
                                .onShareCompleted();
                          },
                        ),
                      ),
                    ),
                    const BottomBannerAd(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color? backgroundColor;

  const _TopPillButton({
    required this.label,
    required this.onPressed,
    this.textColor = Colors.white,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x2EFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopReactionButton extends StatefulWidget {
  final Quote quote;
  final ReactionType? myReaction;
  final Future<void> Function(ReactionType reaction, String assetPath) onReact;

  final Color? backgroundColor;
  final Color? textColor;

  const _TopReactionButton({
    required this.quote,
    required this.myReaction,
    required this.onReact,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<_TopReactionButton> createState() => _TopReactionButtonState();
}

class _TopReactionButtonState extends State<_TopReactionButton> {
  static const _items = <(ReactionType type, String label, String asset)>[
    (ReactionType.comfort, '위로받았어요', 'assets/icons/reactions/comfort.png'),
    (ReactionType.empathize, '공감해요', 'assets/icons/reactions/empathize.png'),
    (ReactionType.good, '멋진글이예요', 'assets/icons/reactions/good.png'),
    (ReactionType.touched, '감동했어요', 'assets/icons/reactions/touched.png'),
    (ReactionType.fan, '팬이예요', 'assets/icons/reactions/fan.png'),
  ];

  void _showReactionSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  '공감 남기기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0x1AFFFFFF)),
              for (int i = 0; i < _items.length; i++) ...[
                _ReactionBubbleItem(
                  label: _items[i].$2,
                  asset: _items[i].$3,
                  count: widget.quote.reactionCounts[
                          reactionTypeToFirestore(_items[i].$1)] ??
                      0,
                  selected: widget.myReaction == _items[i].$1,
                  disabled: widget.myReaction != null &&
                      widget.myReaction != _items[i].$1,
                  onTap: () async {
                    Navigator.pop(context);
                    await widget.onReact(_items[i].$1, _items[i].$3);
                  },
                ),
                if (i < _items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0x1AFFFFFF),
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalReactions = widget.quote.reactionCounts.values
        .fold<int>(0, (sum, count) => sum + count);

    return _TopPillButton(
      label: '공감 $totalReactions',
      textColor: widget.textColor ??
          (widget.myReaction != null ? const Color(0xFFFD2F79) : Colors.white),
      backgroundColor: widget.backgroundColor,
      onPressed: _showReactionSheet,
    );
  }
}

class _ReactionBubbleItem extends StatelessWidget {
  final String label;
  final String asset;
  final int count;
  final bool selected;
  final bool disabled;
  final Future<void> Function() onTap;

  const _ReactionBubbleItem({
    required this.label,
    required this.asset,
    required this.count,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : () => onTap(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                asset,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? const Color(0xFFFD2F79) : Colors.white,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFFFD2F79) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionAnimationOverlay extends StatefulWidget {
  final String assetPath;
  final VoidCallback onComplete;

  const _ReactionAnimationOverlay({
    required this.assetPath,
    required this.onComplete,
  });

  @override
  State<_ReactionAnimationOverlay> createState() =>
      _ReactionAnimationOverlayState();
}

class _ReactionAnimationOverlayState extends State<_ReactionAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Image.asset(
                    widget.assetPath,
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
