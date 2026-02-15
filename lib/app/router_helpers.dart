import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/quotes/domain/quote.dart';
import '../features/quotes/presentation/detail/quote_detail_screen.dart';

/// Screen that fetches a quote by ID and displays it
/// Used for FCM deep linking
class QuoteDetailByIdScreen extends ConsumerWidget {
  final String quoteId;
  final String? quoteType;

  const QuoteDetailByIdScreen({
    super.key,
    required this.quoteId,
    this.quoteType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Quote?>(
      future: _fetchQuote(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('오류가 발생했습니다\n${snapshot.error}'),
            ),
          );
        }

        final quote = snapshot.data;
        if (quote == null) {
          return const Scaffold(
            body: Center(child: Text('콘텐츠를 찾을 수 없습니다')),
          );
        }

        return QuoteDetailScreen(quote: quote);
      },
    );
  }

  Future<Quote?> _fetchQuote() async {
    try {
      debugPrint('[QuoteDetailByIdScreen] ========== FETCH START ==========');
      debugPrint('[QuoteDetailByIdScreen] Quote ID: $quoteId');
      debugPrint('[QuoteDetailByIdScreen] Quote Type: $quoteType');

      final doc = await FirebaseFirestore.instance
          .collection('quotes')
          .doc(quoteId)
          .get();

      debugPrint(
          '[QuoteDetailByIdScreen] Firestore response - exists: ${doc.exists}');

      if (!doc.exists) {
        debugPrint(
            '[QuoteDetailByIdScreen] ERROR: Quote not found in Firestore');
        debugPrint(
            '[QuoteDetailByIdScreen] ========== FETCH END (NOT FOUND) ==========');
        return null;
      }

      final quote = Quote.fromFirestore(doc);
      final contentLength = quote.content.length;
      final contentPreview = contentLength > 50
          ? '${quote.content.substring(0, 50)}...'
          : quote.content;
      debugPrint('[QuoteDetailByIdScreen] Quote loaded successfully');
      debugPrint('[QuoteDetailByIdScreen] - Type: ${quote.type}');
      debugPrint('[QuoteDetailByIdScreen] - Content: $contentPreview');
      debugPrint('[QuoteDetailByIdScreen] - Author: ${quote.author}');
      debugPrint('[QuoteDetailByIdScreen] - Content length: $contentLength');
      debugPrint(
          '[QuoteDetailByIdScreen] ========== FETCH END (SUCCESS) ==========');
      return quote;
    } catch (e, stackTrace) {
      debugPrint('[QuoteDetailByIdScreen] ========== FETCH ERROR ==========');
      debugPrint('[QuoteDetailByIdScreen] Error: $e');
      debugPrint('[QuoteDetailByIdScreen] StackTrace: $stackTrace');
      debugPrint(
          '[QuoteDetailByIdScreen] ========== FETCH END (ERROR) ==========');
      rethrow;
    }
  }
}
