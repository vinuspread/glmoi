import '../../domain/quote.dart';

class QuoteDetailArgs {
  final List<Quote> quotes;
  final int initialIndex;

  const QuoteDetailArgs({
    required this.quotes,
    required this.initialIndex,
  });
}
