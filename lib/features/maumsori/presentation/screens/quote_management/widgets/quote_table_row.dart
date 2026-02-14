import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/quote_model.dart';

class QuoteTableRow extends StatelessWidget {
  final QuoteModel quote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuoteTableRow({
    super.key,
    required this.quote,
    required this.onEdit,
    required this.onDelete,
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
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              quote.content,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              quote.author.isEmpty ? '미상' : quote.author,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('yyyy.MM.dd').format(quote.createdAt),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  color: AppTheme.textSecondary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: Colors.redAccent.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
