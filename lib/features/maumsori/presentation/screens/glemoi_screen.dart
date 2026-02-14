import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import '../providers/quote_provider.dart';
import '../widgets/maumsori_sidebar.dart';
import '../../data/models/quote_model.dart';
import 'glemoi/widgets/glemoi_empty_state.dart';
import 'glemoi/widgets/glemoi_header.dart';
import 'glemoi/widgets/glemoi_tab_bar.dart';
import 'glemoi/widgets/post_card.dart';
import 'glemoi/widgets/post_delete_confirm_dialog.dart';
import 'glemoi/widgets/post_list_container.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

class GlemoiScreen extends ConsumerStatefulWidget {
  const GlemoiScreen({super.key});

  @override
  ConsumerState<GlemoiScreen> createState() => _GlemoiScreenState();
}

class _GlemoiScreenState extends ConsumerState<GlemoiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
            const MaumSoriSidebar(activeRoute: '/maumsori/glemoi'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  const GlemoiHeader(),
                  GlemoiTabBar(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPendingList(),
                        _buildApprovedList(),
                        _buildReportedList(),
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

  Widget _buildPendingList() {
    final postsAsync = ref.watch(userPostsProvider(false)); // 미승인 게시글

    return postsAsync.when(
      data: (posts) => _buildPostList(posts, isPending: true),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('오류: $err')),
    );
  }

  Widget _buildApprovedList() {
    final postsAsync = ref.watch(userPostsProvider(true)); // 승인된 게시글

    return postsAsync.when(
      data: (posts) => _buildPostList(posts, isPending: false),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('오류: $err')),
    );
  }

  Widget _buildReportedList() {
    final postsAsync = ref.watch(reportedPostsProvider);

    return postsAsync.when(
      data: (posts) => _buildPostList(posts, isReported: true),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('오류: $err')),
    );
  }

  Widget _buildPostList(
    List<QuoteModel> posts, {
    bool isPending = false,
    bool isReported = false,
  }) {
    if (posts.isEmpty) {
      final message = isPending
          ? '검수 대기 중인 글이 없습니다'
          : (isReported ? '신고된 글이 없습니다' : '승인된 글이 없습니다');
      return GlemoiEmptyState(message: message);
    }

    return PostListContainer(
      totalCount: posts.length,
      children: posts
          .map(
            (post) => PostCard(
              post: post,
              isPending: isPending,
              isReported: isReported,
              onApprove: () => _approvePost(post),
              onReject: () => _rejectPost(post),
              onPromote: () => _promotePost(post),
              onDelete: () => _deletePost(post),
            ),
          )
          .toList(),
    );
  }

  Future<void> _approvePost(QuoteModel post) async {
    await ref.read(quoteControllerProvider).approvePost(post);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 승인되었습니다')));
    }
  }

  Future<void> _rejectPost(QuoteModel post) async {
    await ref.read(quoteControllerProvider).rejectPost(post);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 거부되었습니다')));
    }
  }

  Future<void> _promotePost(QuoteModel post) async {
    await ref.read(quoteControllerProvider).promoteUserPost(post.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공식 콘텐츠로 격상되었습니다')));
    }
  }

  Future<void> _deletePost(QuoteModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => PostDeleteConfirmDialog(onConfirm: () {}),
    );

    if (confirm == true) {
      await ref.read(quoteControllerProvider).deleteQuote(post.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다')));
      }
    }
  }
}
