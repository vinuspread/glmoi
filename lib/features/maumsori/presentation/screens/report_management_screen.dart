import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import '../providers/quote_provider.dart';
import '../widgets/maumsori_sidebar.dart';
import '../../data/models/quote_model.dart';
import '../../data/repositories/quote_repository.dart';
import 'package:intl/intl.dart';

class ReportManagementScreen extends ConsumerWidget {
  const ReportManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportedPostsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/reports'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: reportsAsync.when(
                      data: (reports) =>
                          _buildReportList(context, ref, reports),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('오류: $error')),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.report_outlined,
            size: 28,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
          Text(
            '신고 관리',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(
    BuildContext context,
    WidgetRef ref,
    List<QuoteModel> reports,
  ) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '신고된 글이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            ...reports.map((report) => _buildReportRow(context, ref, report)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // dot 컬럼 공간 (16px)
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              '글 정보',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '원작자',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '신고 사유',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '신고 수',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '신고 일자',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(
    BuildContext context,
    WidgetRef ref,
    QuoteModel report,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final reportDate = report.lastReportAt != null
        ? dateFormat.format(report.lastReportAt!)
        : dateFormat.format(report.createdAt);

    final isUnread = !report.isReportRead;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.red.shade50.withOpacity(0.4) : null,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // 미확인 표시 dot
          SizedBox(
            width: 12,
            child: isUnread
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                _showContentDialog(context, ref, report);
              },
              child: Text(
                report.content.length > 50
                    ? '${report.content.substring(0, 50)}...'
                    : report.content,
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  decoration: TextDecoration.underline,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                final displayName = report.authorName ?? report.author;
                _navigateToMember(
                  context,
                  report.userUid ?? '',
                  displayName.isNotEmpty ? displayName : '알 수 없음',
                );
              },
              child: Text(
                () {
                  final name = report.authorName ?? report.author;
                  return name.isNotEmpty ? name : '알 수 없음';
                }(),
                style: const TextStyle(
                  color: AppTheme.primaryPurple,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Expanded(flex: 2, child: _buildReportReasons(report.reportReasons)),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${report.reportCount}건',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(reportDate, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportReasons(Map<String, int> reasons) {
    if (reasons.isEmpty) return const Text('-');

    final reasonNames = {
      'spam_ad': '스팸/광고',
      'hate': '혐오 발언',
      'sexual': '성적인 콘텐츠',
      'privacy': '개인정보 노출',
      'etc': '기타',
    };

    final sortedReasons = reasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedReasons.take(2).map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '${reasonNames[entry.key] ?? entry.key} (${entry.value})',
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  void _showContentDialog(
    BuildContext context,
    WidgetRef ref,
    QuoteModel report,
  ) {
    // 미확인 상태면 읽음 처리
    if (!report.isReportRead) {
      ref.read(quoteRepositoryProvider).markReportRead(report.id);
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고된 글 내용'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.content,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '작성자: ${report.authorName ?? report.author}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '작성일: ${DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '신고 수: ${report.reportCount}건',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _navigateToMember(BuildContext context, String uid, String displayName) {
    context.go('/maumsori/members?uid=$uid&name=$displayName');
  }
}
