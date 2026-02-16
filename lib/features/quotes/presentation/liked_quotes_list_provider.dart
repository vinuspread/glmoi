import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/liked_quotes_repository.dart';

final likedQuotesListProvider = StreamProvider<List<LikedQuoteSnapshot>>((ref) {
  final repo = ref.watch(likedQuotesRepositoryProvider);
  return repo.watchLikedQuotes();
});
