import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/quote_model.dart';

class ContentTableRow extends StatelessWidget {
  final QuoteModel quote;
  final ContentType type;
  final VoidCallback onToggleActive;
  final VoidCallback onPreviewTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveToThought;

  const ContentTableRow({
    super.key,
    required this.quote,
    required this.type,
    required this.onToggleActive,
    required this.onPreviewTap,
    required this.onEdit,
    required this.onDelete,
    this.onMoveToThought,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Active Status
          SizedBox(
            width: 60,
            child: Switch(
              value: quote.isActive,
              onChanged: (_) => onToggleActive(),
              activeColor: AppTheme.primaryPurple,
            ),
          ),
          if (type != ContentType.quote)
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quote.category,
                  style: const TextStyle(
                    color: AppTheme.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(width: 24),
          // Thumbnail + content
          SizedBox(
            width: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (quote.imageUrl == null)
                  ? Container(color: AppTheme.background)
                  : Image.network(
                      quote.imageUrl!,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.background),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onPreviewTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  quote.content,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Author
          Expanded(
            child: Text(
              quote.author.isEmpty ? '미상' : quote.author,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          // Metrics
          SizedBox(
            width: 100,
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quote.likeCount}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.share_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quote.shareCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          // Created Date
          SizedBox(
            width: 100,
            child: Text(
              DateFormat('yyyy.MM.dd').format(quote.createdAt),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: onMoveToThought != null ? 140 : 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onMoveToThought != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    onPressed: onMoveToThought,
                    color: AppTheme.primaryPurple,
                    tooltip: '좋은생각으로 이동',
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  color: AppTheme.textSecondary,
                  tooltip: '수정',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: Colors.redAccent.withOpacity(0.7),
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
