import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_quotes_repository.dart';

/// 로컬 담기 상태 관리 (optimistic update용) — likedQuotesProvider와 동일 패턴
final savedQuotesNotifierProvider =
    StateNotifierProvider<SavedQuotesNotifier, Set<String>>((ref) {
  final repo = ref.watch(savedQuotesRepositoryProvider);
  return SavedQuotesNotifier(repo);
});

class SavedQuotesNotifier extends StateNotifier<Set<String>> {
  final SavedQuotesRepository _repository;
  bool _initialized = false;

  SavedQuotesNotifier(this._repository) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    _initialized = true;
    final ids = await _repository.getSavedQuoteIds();
    state = ids;
  }

  bool isSaved(String quoteId) => state.contains(quoteId);

  void markSaved(String quoteId) {
    if (state.contains(quoteId)) return;
    state = Set<String>.from(state)..add(quoteId);
  }

  void unmarkSaved(String quoteId) {
    if (!state.contains(quoteId)) return;
    state = Set<String>.from(state)..remove(quoteId);
  }

  Future<void> refresh() async {
    _initialized = false;
    await _load();
  }
}

/// 특정 글이 담겨있는지 확인하는 Provider (로컬 상태 기반 — optimistic update 지원)
final isSavedProvider = Provider.family<bool, String>((ref, quoteId) {
  return ref.watch(
    savedQuotesNotifierProvider.select((s) => s.contains(quoteId)),
  );
});

/// 담은 글 목록 Provider (Firestore stream — saved_quotes 화면용)
final savedQuotesProvider = StreamProvider<List<SavedQuoteSnapshot>>((ref) {
  final repo = ref.watch(savedQuotesRepositoryProvider);
  return repo.watchSavedQuotes();
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
