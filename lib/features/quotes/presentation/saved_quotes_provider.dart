import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_quotes_repository.dart';

/// 담은 글 목록 Provider
final savedQuotesProvider = StreamProvider<List<SavedQuoteSnapshot>>((ref) {
  final repo = ref.watch(savedQuotesRepositoryProvider);
  return repo.watchSavedQuotes();
});

/// 특정 글이 담겨있는지 확인하는 Provider
final isSavedProvider = StreamProvider.family<bool, String>((ref, quoteId) {
  final repo = ref.watch(savedQuotesRepositoryProvider);
  return repo.isSaved(quoteId);
});

/// 담기 액션을 처리하는 Controller
final savedQuotesControllerProvider = Provider((ref) {
  return SavedQuotesController(ref);
});

class SavedQuotesController {
  final Ref _ref;

  SavedQuotesController(this._ref);

  Future<bool> toggleSave(dynamic quote) async {
    final repo = _ref.read(savedQuotesRepositoryProvider);
    return await repo.toggleSaveQuote(quote);
  }
}
