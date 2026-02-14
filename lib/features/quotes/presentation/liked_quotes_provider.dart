import 'package:flutter_riverpod/flutter_riverpod.dart';

final likedQuotesProvider =
    StateNotifierProvider<LikedQuotesController, Set<String>>((ref) {
  return LikedQuotesController();
});

class LikedQuotesController extends StateNotifier<Set<String>> {
  LikedQuotesController() : super(const {});

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
}
