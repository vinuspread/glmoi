import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../providers/quote_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/maumsori_sidebar.dart';
import '../../data/models/quote_model.dart';
import 'content_list/widgets/content_table_header.dart';
import 'content_list/widgets/content_table_row.dart';
import 'content_list/widgets/content_delete_dialog.dart';
import 'content_list/widgets/content_empty_state.dart';
import 'content_list/widgets/content_list_page_header.dart';
import 'content_list/widgets/content_list_toolbar.dart';
import 'content_list/widgets/quote_preview_dialog.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

class ContentListScreen extends ConsumerStatefulWidget {
  const ContentListScreen({super.key});

  @override
  ConsumerState<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends ConsumerState<ContentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            // Sidebar
            const MaumSoriSidebar(activeRoute: '/maumsori/content'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Header
                  ContentListPageHeader(
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                  ),
                  // Tabs
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: '한줄명언'),
                        Tab(text: '좋은생각'),
                        Tab(text: '글모이'),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildContentList(ContentType.quote),
                        _buildContentList(ContentType.thought),
                        _buildContentList(ContentType.malmoi),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(ContentType type) {
    // 글모이 탭은 공식 + 사용자 제출 글 모두 표시
    final quotesAsync = type == ContentType.malmoi
        ? ref.watch(malmoiAllProvider)
        : ref.watch(quoteListProvider(type));
    final appConfigAsync = ref.watch(appConfigProvider);

    return quotesAsync.when(
      data: (quotes) {
        // Apply search filter
        final filteredQuotes = quotes.where((quote) {
          if (_searchQuery.isEmpty) return true;
          return quote.content.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              quote.author.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredQuotes.isEmpty) {
          return ContentEmptyState(isSearching: _searchQuery.isNotEmpty);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentListToolbar(
                totalCount: filteredQuotes.length,
                onCreate: () {
                  context.go(
                    '/maumsori/compose?type=${contentTypeToFirestore(type)}',
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    ContentTableHeader(type: type),
                    ...filteredQuotes.map(
                      (quote) => ContentTableRow(
                        quote: quote,
                        type: type,
                        onToggleActive: () {
                          ref.read(quoteControllerProvider).toggleActive(quote);
                        },
                        onPreviewTap: () {
                          _showPreviewDialog(
                            quote,
                            defaultFontSize:
                                appConfigAsync.value?.composerFontSize ?? 24,
                            defaultLineHeight:
                                appConfigAsync.value?.composerLineHeight ?? 1.6,
                            defaultDimStrength:
                                appConfigAsync.value?.composerDimStrength ??
                                0.4,
                          );
                        },
                        onEdit: () {
                          context.go('/maumsori/content/${quote.id}/edit');
                        },
                        onDelete: () {
                          _showDeleteDialog(quote);
                        },
                        onMoveToThought:
                            type == ContentType.malmoi &&
                                quote.type == ContentType.malmoi
                            ? () => _showMoveToThoughtDialog(quote)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('오류: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  void _showPreviewDialog(
    QuoteModel quote, {
    required int defaultFontSize,
    required double defaultLineHeight,
    required double defaultDimStrength,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuotePreviewDialog(
        quote: quote,
        defaultFontSize: defaultFontSize,
        defaultLineHeight: defaultLineHeight,
        defaultDimStrength: defaultDimStrength,
      ),
    );
  }

  void _showDeleteDialog(QuoteModel quote) {
    showDialog(
      context: context,
      builder: (context) => ContentDeleteDialog(
        onConfirm: () {
          ref.read(quoteControllerProvider).deleteQuote(quote.id);
        },
      ),
    );
  }

  void _showMoveToThoughtDialog(QuoteModel quote) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('좋은생각으로 이동'),
        content: Text(
          '이 글모이를 좋은생각으로 이동하시겠습니까?\n\n글 내용: ${quote.content.length > 50 ? '${quote.content.substring(0, 50)}...' : quote.content}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '이동',
              style: TextStyle(color: AppTheme.primaryPurple),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // 디버깅: 이동 전 정보 출력
          if (kDebugMode) {
            print('=== 글 이동 시작 ===');
            print('ID: ${quote.id}');
            print('현재 타입: ${quote.type}');
            print('is_user_post: ${quote.isUserPost}');
          }

          await ref
              .read(quoteControllerProvider)
              .changeContentType(quote.id, ContentType.thought);

          if (kDebugMode) {
            print('=== 글 이동 완료 ===');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('좋은생각으로 이동 완료 (ID: ${quote.id})'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (error) {
          if (kDebugMode) {
            print('=== 글 이동 실패 ===');
            print('에러: $error');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이동 실패: $error'),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }
}
