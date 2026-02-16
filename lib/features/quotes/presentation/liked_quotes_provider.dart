import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/liked_quotes_repository.dart';

final likedQuotesProvider =
    StateNotifierProvider<LikedQuotesController, Set<String>>((ref) {
  final repo = ref.watch(likedQuotesRepositoryProvider);
  return LikedQuotesController(repo);
});

class LikedQuotesController extends StateNotifier<Set<String>> {
  final LikedQuotesRepository _repository;
  bool _initialized = false;

  LikedQuotesController(this._repository) : super(const {}) {
    _loadLikedQuotes();
  }

  Future<void> _loadLikedQuotes() async {
    if (_initialized) return;
    _initialized = true;

    final likedIds = await _repository.getLikedQuoteIds();
    state = likedIds;
  }

  bool isLiked(String quoteId) => state.contains(quoteId);

  void markLiked(String quoteId) {
    if (state.contains(quoteId)) return;
    final next = Set<String>.from(state)..add(quoteId);
    state = next;
  }

  void unmarkLiked(String quoteId) {
    if (!state.contains(quoteId)) return;
    final next = Set<String>.from(state)..remove(quoteId);
    state = next;
  }

  Future<void> refresh() async {
    _initialized = false;
    await _loadLikedQuotes();
  }
}
