import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/banner_ad_widget.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/share/kakao_talk_share_service.dart';
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
                  _actionsVisible = true;
                });
                _scheduleAutoHideActions();
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      if (showReactions)
                        _TopReactionButton(
                          quote: quote,
                          myReaction: myReaction,
                          onReact: (reaction) async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }
                            try {
                              final result = await FirebaseFunctions.instance
                                  .httpsCallable('reactToQuoteOnce')
                                  .call({
                                'quoteId': quote.id,
                                'reaction': reactionTypeToFirestore(reaction),
                              });
                              final alreadyReacted =
                                  result.data['alreadyReacted'] == true;
                              if (!context.mounted) return;
                              if (alreadyReacted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('이미 반응한 글입니다.')),
                                );
                              } else {
                                // Update local state
                                setState(() {
                                  final updated = quote.copyWith(
                                    reactionCounts: {
                                      ...quote.reactionCounts,
                                      reactionTypeToFirestore(reaction):
                                          (quote.reactionCounts[
                                                      reactionTypeToFirestore(
                                                          reaction)] ??
                                                  0) +
                                              1,
                                    },
                                  );
                                  _quotes[_index] = updated;
                                });
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('반응 실패: $e')),
                              );
                            }
                          },
                        ),
                      if (showReactions) const SizedBox(width: 8),
                      if (isOwner)
                        IconButton(
                          tooltip: '수정',
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
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                        ),
                      if (isOwner)
                        IconButton(
                          tooltip: '삭제',
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
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFCA5A5),
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
                          onLike: () async {
                            if (!isLoggedIn) {
                              context.push('/login');
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final alreadyLiked = await ref
                                  .read(_interactionsRepoProvider)
                                  .likeQuoteOnce(quoteId: quote.id);
                              ref
                                  .read(likedQuotesProvider.notifier)
                                  .markLiked(quote.id);
                              if (!context.mounted) return;
                              if (alreadyLiked) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('이미 좋아요한 글입니다.')),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
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
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final saved = await ref
                                  .read(savedQuotesControllerProvider)
                                  .toggleSave(quote);
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(saved ? '담았습니다' : '담기 취소'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
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
                            final messenger = ScaffoldMessenger.of(context);
                            final author = quote.author.trim();
                            final text = author.isEmpty
                                ? quote.content
                                : '${quote.content}\n\n- $author -';
                            try {
                              await KakaoTalkShareService.share(
                                KakaoTalkShareContent(text: text),
                              );
                              await ref
                                  .read(_interactionsRepoProvider)
                                  .incrementShareCount(quoteId: quote.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('공유 실패: $e')),
                              );
                            }
                          },
                          onReport: (!isOwner && quote.type == QuoteType.malmoi)
                              ? () async {
                                  if (!isLoggedIn) {
                                    context.push('/login');
                                    return;
                                  }

                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final reasonCode =
                                      await _pickReportReason(context);
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
                                }
                              : null,
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

  const _TopPillButton({
    required this.label,
    required this.onPressed,
    this.textColor = Colors.white,
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
            color: const Color(0x1FFFFFFF),
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
  final Future<void> Function(ReactionType reaction) onReact;

  const _TopReactionButton({
    super.key,
    required this.quote,
    required this.myReaction,
    required this.onReact,
  });

  @override
  State<_TopReactionButton> createState() => _TopReactionButtonState();
}

class _TopReactionButtonState extends State<_TopReactionButton> {
  bool _showBubble = false;

  static const _items = <(ReactionType type, String label, String asset)>[
    (ReactionType.comfort, '위로받았어요', 'assets/icons/reactions/comfort.svg'),
    (ReactionType.empathize, '공감해요', 'assets/icons/reactions/empathize.svg'),
    (ReactionType.good, '멋진글이예요', 'assets/icons/reactions/good.svg'),
    (ReactionType.touched, '감동했어요', 'assets/icons/reactions/touched.svg'),
    (ReactionType.fan, '팬이예요', 'assets/icons/reactions/fan.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final totalReactions = widget.quote.reactionCounts.values
        .fold<int>(0, (sum, count) => sum + count);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main button (top pill style)
        _TopPillButton(
          label: '반응 $totalReactions',
          textColor: widget.myReaction != null ? AppTheme.accent : Colors.white,
          onPressed: () {
            setState(() => _showBubble = !_showBubble);
          },
        ),

        // Floating reaction bubble menu (vertical stack)
        if (_showBubble) ...[
          // Backdrop to close
          Positioned(
            top: 52,
            right: 0,
            child: GestureDetector(
              onTap: () => setState(() => _showBubble = false),
              child: Container(
                width: 200,
                height: 300,
                color: Colors.transparent,
              ),
            ),
          ),

          // Menu
          Positioned(
            top: 52,
            right: 0,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.topRight,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          setState(() => _showBubble = false);
                          await widget.onReact(_items[i].$1);
                        },
                      ),
                      if (i < _items.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0x1AFFFFFF),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
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
              SvgPicture.asset(
                asset,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  selected ? AppTheme.accent : Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppTheme.accent : Colors.white,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.accent : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
