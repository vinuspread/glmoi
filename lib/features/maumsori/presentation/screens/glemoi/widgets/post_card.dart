import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/quote_model.dart';

class PostCard extends StatelessWidget {
  final QuoteModel post;
  final bool isPending;
  final bool isReported;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onPromote;
  final VoidCallback onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.isPending,
    required this.isReported,
    required this.onApprove,
    required this.onReject,
    required this.onPromote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String labelForReasonCode(String code) {
      switch (code) {
        case 'spam_ad':
          return '스팸/광고';
        case 'hate':
          return '욕설/혐오';
        case 'sexual':
          return '음란/선정';
        case 'privacy':
          return '개인정보';
        case 'etc':
          return '기타';
        default:
          return code;
      }
    }

    final reportReasons = post.reportReasons;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReported && post.reportCount > 0
              ? Colors.red.withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: post.type == ContentType.quote
                      ? AppTheme.accentLight
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.type == ContentType.quote ? '한줄명언' : '좋은생각',
                  style: TextStyle(
                    color: post.type == ContentType.quote
                        ? AppTheme.primaryPurple
                        : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.category,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (isReported && post.reportCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.report_outlined,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '신고 ${post.reportCount}건',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(post.createdAt),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5)),
          if (isReported &&
              post.reportCount > 0 &&
              reportReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reportReasons.entries
                  .where((e) => e.value > 0)
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.red.withOpacity(0.15)),
                      ),
                      child: Text(
                        '${labelForReasonCode(e.key)} ${e.value}건',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (post.author.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '- ${post.author}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isPending) ...[
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('승인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('거부'),
                ),
              ],
              if (!isPending && !isReported) ...[
                ElevatedButton.icon(
                  onPressed: onPromote,
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('공식 콘텐츠 격상'),
                ),
              ],
              if (isReported) ...[
                ElevatedButton(onPressed: onApprove, child: const Text('유지')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: onReject, child: const Text('숨김')),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: '삭제',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
