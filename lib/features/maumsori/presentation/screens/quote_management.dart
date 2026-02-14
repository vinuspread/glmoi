import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import '../providers/quote_provider.dart';
import '../../data/models/quote_model.dart';
import 'quote_management/widgets/quote_editor_dialog.dart';
import 'quote_management/widgets/quote_management_header.dart';
import 'quote_management/widgets/quote_management_sidebar.dart';
import 'quote_management/widgets/quote_stat_card.dart';
import 'quote_management/widgets/quotes_table.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

class QuoteManagement extends ConsumerWidget {
  const QuoteManagement({super.key});

  void _showQuoteDialog(
    BuildContext context,
    WidgetRef ref, {
    QuoteModel? quote,
  }) {
    final contentController = TextEditingController(text: quote?.content);
    final authorController = TextEditingController(text: quote?.author);
    final categoryController = TextEditingController(
      text: quote?.category ?? '힐링',
    );

    showDialog(
      context: context,
      builder: (context) => QuoteEditorDialog(
        isEdit: quote != null,
        contentController: contentController,
        authorController: authorController,
        categoryController: categoryController,
        onSave: () async {
          final controller = ref.read(quoteControllerProvider);
          if (quote == null) {
            await controller.addQuote(
              type: ContentType.quote,
              content: contentController.text,
              author: authorController.text,
              category: categoryController.text,
            );
            return;
          }

          await controller.updateQuote(
            quote.copyWith(
              content: contentController.text,
              author: authorController.text,
              category: categoryController.text,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(quoteListProvider(ContentType.quote));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            // Sub Sidebar (App Context)
            const QuoteManagementSidebar(),
            const VerticalDivider(width: 1, color: AppTheme.border),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Inner Header
                  quotesAsync.when(
                    data: (quotes) => QuoteManagementHeader(
                      totalCount: quotes.length,
                      onAdd: () => _showQuoteDialog(context, ref),
                    ),
                    loading: () => QuoteManagementHeader(
                      totalCount: null,
                      onAdd: () => _showQuoteDialog(context, ref),
                    ),
                    error: (_, __) => QuoteManagementHeader(
                      totalCount: null,
                      onAdd: () => _showQuoteDialog(context, ref),
                    ),
                  ),
                  // Body content
                  Expanded(
                    child: quotesAsync.when(
                      data: (quotes) => SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                QuoteStatCard(
                                  label: 'Total Uploads',
                                  value: quotes.length.toString(),
                                  icon: Icons.upload_file,
                                ),
                                const SizedBox(width: 24),
                                const QuoteStatCard(
                                  label: 'Today Active',
                                  value: '12',
                                  icon: Icons.trending_up,
                                ),
                                const SizedBox(width: 24),
                                const QuoteStatCard(
                                  label: 'Categories',
                                  value: '5',
                                  icon: Icons.category_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            const Text(
                              'Recent Quotes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            QuotesTable(
                              quotes: quotes,
                              onEditFor: (quote) =>
                                  () => _showQuoteDialog(
                                    context,
                                    ref,
                                    quote: quote,
                                  ),
                              onDeleteFor: (quote) =>
                                  () => ref
                                      .read(quoteControllerProvider)
                                      .deleteQuote(quote.id),
                            ),
                          ],
                        ),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다: $err')),
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
}
