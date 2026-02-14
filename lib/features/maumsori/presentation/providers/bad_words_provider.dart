import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/bad_words_model.dart';
import '../../data/repositories/bad_words_repository.dart';

final badWordsConfigProvider = StreamProvider<BadWordsConfig>((ref) {
  final repo = ref.watch(badWordsRepositoryProvider);
  return repo.watchConfig();
});

final badWordsControllerProvider = Provider((ref) {
  return BadWordsController(ref);
});

class BadWordsController {
  final Ref _ref;

  BadWordsController(this._ref);

  Future<void> ensureInitialized() async {
    await _ref.read(badWordsRepositoryProvider).ensureInitializedWithDefaults();
  }

  Future<void> addPlainWord(String value) async {
    await _ref.read(badWordsRepositoryProvider).addPlainWord(value);
  }

  Future<void> addRegex(String pattern) async {
    await _ref.read(badWordsRepositoryProvider).addRegex(pattern);
  }

  Future<void> deleteRule(String ruleId) async {
    await _ref.read(badWordsRepositoryProvider).deleteRule(ruleId);
  }

  Future<void> setRuleEnabled(String ruleId, bool enabled) async {
    await _ref.read(badWordsRepositoryProvider).setRuleEnabled(ruleId, enabled);
  }
}
