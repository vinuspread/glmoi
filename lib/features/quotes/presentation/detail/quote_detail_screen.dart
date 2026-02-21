import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ads_controller.dart';
import '../../../../core/ads/banner_ad_widget.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/share/kakao_talk_share_service.dart';
import '../../../../core/share/share_sheet.dart';
import '../../../auth/domain/login_redirect.dart';
import '../../data/interactions_repository.dart';
import '../../data/quotes_repository.dart';
import '../liked_quotes_provider.dart';
import '../saved_quotes_provider.dart';
import '../../domain/quote.dart';
import '../../../reactions/domain/reaction_type.dart';
import '../../../reactions/presentation/providers/my_reaction_provider.dart';
import '../widgets/content_text.dart';

final _interactionsRepoProvider = Provider((ref) => InteractionsRepository());
final _quotesRepoProvider = Provider((ref) => QuotesRepository());

class QuoteDetailScreen extends ConsumerStatefulWidget {
  final Quote quote;
  final bool showChrome;
  final double bottomOverlayPadding;

  const QuoteDetailScreen({
    super.key,
    required this.quote,
    this.showChrome = true,
    this.bottomOverlayPadding = 148,
  });

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  static const _reportReasons = <(String code, String label)>[
    ('spam_ad', '스팸/광고'),
    ('hate', '욕설/혐오'),
    ('sexual', '음란/선정'),
    ('privacy', '개인정보'),
    ('etc', '기타'),
  ];

  late Quote _quote;
  Timer? _hideActionsTimer;
  var _actionsVisible = true;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
    _scheduleAutoHideActions();
    _recordView();
  }

  void _recordView() {
    final uid = ref.read(authUidProvider).valueOrNull;
    if (uid == null) return;
    ref
        .read(_interactionsRepoProvider)
        .incrementViewCount(quoteId: widget.quote.id)
        .ignore();
  }

  @override
  void didUpdateWidget(covariant QuoteDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Keep internal state in sync with parent updates.
    // This matters for the detail pager: the parent swaps the Quote object
    // after edit, but this widget keeps `_quote` as local state.
    if (oldWidget.quote.id != widget.quote.id) {
      _quote = widget.quote;
      return;
    }

    final changed = oldWidget.quote.content != widget.quote.content ||
        oldWidget.quote.author != widget.quote.author ||
        oldWidget.quote.imageUrl != widget.quote.imageUrl ||
        oldWidget.quote.malmoiLength != widget.quote.malmoiLength ||
        oldWidget.quote.reactionCounts != widget.quote.reactionCounts;

    if (changed) {
      _quote = widget.quote;
    }
  }

  @override
  void dispose() {
    _hideActionsTimer?.cancel();
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
    final quote = _quote;
    final showReactions = quote.type == QuoteType.malmoi;

    // Debug log
    debugPrint(
        '[QuoteDetail] quote.id=${quote.id}, type=${quote.type}, showReactions=$showReactions');
    final isLiked = ref.watch(
      likedQuotesProvider.select((s) => s.contains(quote.id)),
    );
    final isSaved = ref.watch(isSavedProvider(quote.id));

    final myReaction = showReactions
        ? ref.watch(myReactionProvider(quote.id)).valueOrNull
        : null;

    final currentUid = ref.watch(authUidProvider).valueOrNull;
    final isOwner = currentUid != null &&
        quote.type == QuoteType.malmoi &&
        quote.isUserPost &&
        ((quote.userUid != null && quote.userUid == currentUid) ||
            (quote.userProvider == 'firebase' && quote.userId == currentUid));
    final isLong = quote.type == QuoteType.thought ||
        (quote.type == QuoteType.malmoi &&
            quote.malmoiLength == MalmoiLength.long);

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final bgCacheW = (screenSize.width * dpr).round();
    final bgCacheH = (screenSize.height * dpr).round();

    final bannerSafeBottomPadding =
        MediaQuery.paddingOf(context).bottom + 50 + 16;

    final hasImage = quote.imageUrl != null && quote.imageUrl!.isNotEmpty;
    // Adaptive colors based on background
    final textColor = hasImage ? Colors.white : AppTheme.textPrimary;
    final pillBgColor = hasImage
        ? const Color(0x4DFFFFFF)
        : const Color(0x14000000); // Darker pill on light bg
    final pillIconColor = hasImage ? Colors.white : AppTheme.textPrimary;

    if (!widget.showChrome) {
      // Used by the detail pager: render only the changing content.
      return Scaffold(
        backgroundColor:
            hasImage ? const Color(0xFF0B1220) : AppTheme.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) ...[
              CachedNetworkImage(
                imageUrl: quote.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: bgCacheW,
                memCacheHeight: bgCacheH,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0B1220)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x66000000),
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
            ],
            SafeArea(
              bottom: false,
              child: Padding(
                // Keep content away from fixed chrome (close button + action bar + banner ad)
                padding: const EdgeInsets.fromLTRB(0, 56, 0, 0),
                child: isLong
                    ? _LongFormContent(
                        quote: quote,
                        bottomPadding: quote.type == QuoteType.thought
                            ? widget.bottomOverlayPadding
                            : 24,
                        textColor: textColor,
                      )
                    : _ShortFormContent(quote: quote, textColor: textColor),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: hasImage ? const Color(0xFF0B1220) : AppTheme.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _revealActions,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) ...[
              CachedNetworkImage(
                imageUrl: quote.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: bgCacheW,
                memCacheHeight: bgCacheH,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0B1220)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x66000000),
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
            ],
            SafeArea(
              child: Column(
                children: [
                  Row(
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
                            final isLoggedIn = ref.read(authProvider);
                            if (!isLoggedIn) {
                              context.push('/login',
                                  extra: const LoginRedirect.pop());
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);

                            final reasonCode = await _pickReportReason(context);
                            if (reasonCode == null) return;
                            if (!mounted) return;

                            try {
                              final alreadyReported = await ref
                                  .read(_interactionsRepoProvider)
                                  .reportMalmoiOnce(
                                    quoteId: quote.id,
                                    reasonCode: reasonCode,
                                  );
                              if (!mounted) return;
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
                              if (!mounted) return;
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
                          onReact: (reaction) async {
                            final isLoggedIn = ref.read(authProvider);
                            if (!isLoggedIn) {
                              context.push('/login',
                                  extra: const LoginRedirect.pop());
                              return;
                            }

                            if (myReaction != null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이미 공감을 남겼어요.'),
                                ),
                              );
                              return;
                            }

                            // Optimistic UI update
                            final key = reactionTypeToFirestore(reaction);
                            final prevCount = _quote.reactionCounts[key] ?? 0;
                            setState(() {
                              _quote = _quote.copyWith(
                                reactionCounts: {
                                  ..._quote.reactionCounts,
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
                              if (!mounted) return;
                              if (already) {
                                // Rollback
                                setState(() {
                                  _quote = _quote.copyWith(
                                    reactionCounts: {
                                      ..._quote.reactionCounts,
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
                              if (!mounted) return;
                              // Rollback on error
                              setState(() {
                                _quote = _quote.copyWith(
                                  reactionCounts: {
                                    ..._quote.reactionCounts,
                                    key: prevCount,
                                  },
                                );
                              });
                              messenger.showSnackBar(
                                SnackBar(content: Text('공감 실패: $e')),
                              );
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
                              _quote = _quote.copyWith(content: updatedContent);
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
                      const SizedBox(width: 12),
                    ],
                  ),
                  Expanded(
                    child: isLong
                        ? _LongFormContent(
                            quote: quote,
                            bottomPadding: quote.type == QuoteType.thought
                                ? bannerSafeBottomPadding
                                : 24,
                            textColor: textColor,
                          )
                        : _ShortFormContent(quote: quote, textColor: textColor),
                  ),
                ],
              ),
            ),

            // Bottom overlays: action bar sits over content; banner is always pinned.
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
                            final isLoggedIn = ref.read(authProvider);
                            if (!isLoggedIn) {
                              context.push('/login',
                                  extra: const LoginRedirect.pop());
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
                              _quote = _quote.copyWith(
                                likeCount: _quote.likeCount + 1,
                              );
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final alreadyLiked = await ref
                                  .read(_interactionsRepoProvider)
                                  .likeQuoteOnce(quoteId: quote.id);
                              if (!mounted) return;
                              if (alreadyLiked) {
                                ref
                                    .read(likedQuotesProvider.notifier)
                                    .unmarkLiked(quote.id);
                                setState(() {
                                  _quote = _quote.copyWith(
                                    likeCount: _quote.likeCount - 1,
                                  );
                                });
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('이미 좋아요한 글입니다.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ref
                                  .read(likedQuotesProvider.notifier)
                                  .unmarkLiked(quote.id);
                              setState(() {
                                _quote = _quote.copyWith(
                                  likeCount: _quote.likeCount - 1,
                                );
                              });
                              messenger.showSnackBar(
                                SnackBar(content: Text('좋아요 실패: $e')),
                              );
                            }
                          },
                          onSave: () async {
                            final isLoggedIn = ref.read(authProvider);
                            if (!isLoggedIn) {
                              context.push('/login',
                                  extra: const LoginRedirect.pop());
                              return;
                            }

                            // Optimistic UI update
                            final notifier =
                                ref.read(savedQuotesNotifierProvider.notifier);
                            final wasSaved = isSaved;
                            if (wasSaved) {
                              notifier.unmarkSaved(quote.id);
                            } else {
                              notifier.markSaved(quote.id);
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final saved = await ref
                                  .read(savedQuotesControllerProvider)
                                  .toggleSave(quote);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(saved ? '담았습니다' : '담기 취소'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              // Rollback on error
                              if (wasSaved) {
                                notifier.markSaved(quote.id);
                              } else {
                                notifier.unmarkSaved(quote.id);
                              }
                              messenger.showSnackBar(
                                SnackBar(content: Text('담기 실패: $e')),
                              );
                            }
                          },
                          onShare: () async {
                            final isLoggedIn = ref.read(authProvider);
                            if (!isLoggedIn) {
                              context.push('/login',
                                  extra: const LoginRedirect.pop());
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
                            if (!mounted) return;

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

class QuoteDetailActionBar extends StatelessWidget {
  final bool isLiked;
  final bool isSaved;
  final int likeCount;
  final int shareCount;
  final bool isLightMode;
  final Future<void> Function() onLike;
  final Future<void> Function() onSave;
  final Future<void> Function() onShare;

  const QuoteDetailActionBar({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.likeCount,
    required this.shareCount,
    this.isLightMode = false,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    // Light mode: Text Primary / Dark mode: White
    final baseColor = isLightMode ? AppTheme.textPrimary : Colors.white;
    // Light mode: Border color / Dark mode: White translucent
    final borderColor = isLightMode ? AppTheme.border : const Color(0x33FFFFFF);
    // Light mode: White with shadow? Or just white. / Dark mode: translucent black
    final bgColor = isLightMode ? Colors.white : const Color(0xCC000000);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onLike(),
              style: OutlinedButton.styleFrom(
                backgroundColor: bgColor,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                '좋아요 $likeCount',
                style: TextStyle(
                  color: isLiked ? const Color(0xFFFD2F79) : baseColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onSave(),
              style: OutlinedButton.styleFrom(
                backgroundColor: bgColor,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                '담기',
                style: TextStyle(
                  color: isSaved ? const Color(0xFFFD2F79) : baseColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () => onShare(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFEE500),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                '공유 $shareCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _preventMidTokenWrapKeepNewlines(String input) {
  // Display-only transformation.
  // - Preserves user-entered newlines
  // - Prevents awkward mid-token line breaks for short tokens
  //   (including Hangul words like "인생이라는" breaking as "인\n생")
  // NOTE: This does not change what we store in Firestore.
  const joiner = '\u2060'; // Word Joiner (no-break)

  final ws = RegExp(r'\s+');
  final latinish = RegExp(
    r"[A-Za-z0-9][A-Za-z0-9._:/?#\[\]@!$&'()*+,;=%\-]{2,}",
  );
  final hasHangul = RegExp(r'[\uAC00-\uD7A3]');

  return input.splitMapJoin(
    ws,
    onMatch: (m) => m[0] ?? '', // keep whitespace/newlines as-is
    onNonMatch: (token) {
      // Don't force no-break on very long tokens (avoid overflow).
      if (token.length > 30) return token;
      if (!latinish.hasMatch(token) && !hasHangul.hasMatch(token)) {
        return token;
      }
      return token.split('').join(joiner);
    },
  );
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

class _ShortFormContent extends StatelessWidget {
  final Quote quote;
  final Color? textColor;

  const _ShortFormContent({required this.quote, this.textColor});

  @override
  Widget build(BuildContext context) {
    final author = (quote.authorName ?? quote.author).trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentText(
              _preventMidTokenWrapKeepNewlines(quote.content),
              textAlign: TextAlign.center,
              baseFontSize: 24,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.white,
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '- $author -',
                style: TextStyle(
                  color: (textColor ?? Colors.white).withValues(alpha: 200),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LongFormContent extends StatelessWidget {
  final Quote quote;
  final double bottomPadding;
  final Color? textColor;

  const _LongFormContent({
    required this.quote,
    this.bottomPadding = 24,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final author = (quote.authorName ?? quote.author).trim();
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ContentText(
              _preventMidTokenWrapKeepNewlines(quote.content),
              textAlign: TextAlign.left,
              baseFontSize: 22,
              height: 1.65,
              fontWeight: FontWeight.w400,
              color: textColor ?? Colors.white,
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '- $author -',
                style: TextStyle(
                  color: (textColor ?? Colors.white).withValues(alpha: 200),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopReactionButton extends StatefulWidget {
  final Quote quote;
  final ReactionType? myReaction;
  final Future<void> Function(ReactionType reaction) onReact;

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
    (ReactionType.comfort, '위로받았어요', 'assets/icons/reactions/comfort.svg'),
    (ReactionType.empathize, '공감해요', 'assets/icons/reactions/empathize.svg'),
    (ReactionType.good, '멋진글이예요', 'assets/icons/reactions/good.svg'),
    (ReactionType.touched, '감동했어요', 'assets/icons/reactions/touched.svg'),
    (ReactionType.fan, '팬이예요', 'assets/icons/reactions/fan.svg'),
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
              SvgPicture.asset(
                asset,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  selected ? const Color(0xFFFD2F79) : Colors.white,
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
                    color: selected ? const Color(0xFFFD2F79) : Colors.white,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFFFD2F79)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
