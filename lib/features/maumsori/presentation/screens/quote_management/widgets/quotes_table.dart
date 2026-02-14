import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

import '../../../../data/models/quote_model.dart';
import 'quote_table_row.dart';
import 'quotes_table_header.dart';

class QuotesTable extends StatelessWidget {
  final List<QuoteModel> quotes;
  final VoidCallback Function(QuoteModel quote) onEditFor;
  final VoidCallback Function(QuoteModel quote) onDeleteFor;

  const QuotesTable({
    super.key,
    required this.quotes,
    required this.onEditFor,
    required this.onDeleteFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const QuotesTableHeader(),
          if (quotes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('등록된 명언이 없습니다. 새로운 명언을 추가해 보세요!')),
            )
          else
            ...quotes.map(
              (quote) => QuoteTableRow(
                quote: quote,
                onEdit: onEditFor(quote),
                onDelete: onDeleteFor(quote),
              ),
            ),
        ],
      ),
    );
  }
}
