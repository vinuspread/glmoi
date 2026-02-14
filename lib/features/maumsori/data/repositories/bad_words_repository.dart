import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bad_words_model.dart';

final badWordsRepositoryProvider = Provider((ref) => BadWordsRepository());

class BadWordsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore.collection('admin_settings').doc('bad_words');
  }

  Stream<BadWordsConfig> watchConfig() {
    return _docRef().snapshots().map((doc) => BadWordsConfig.fromDoc(doc));
  }

  Future<BadWordsConfig> getConfig() async {
    final doc = await _docRef().get();
    return BadWordsConfig.fromDoc(doc);
  }

  Future<void> ensureInitializedWithDefaults() async {
    final ref = _docRef();
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) return;

    final now = FieldValue.serverTimestamp();
    final seed = <String, Map<String, dynamic>>{};
    for (final w in _defaultSeedWords) {
      final id = _newRuleId();
      seed[id] = {
        'mode': 'plain',
        'value': w,
        'enabled': true,
        'createdAt': now,
        'updatedAt': now,
      };
    }

    await ref.set({
      'schema_version': 1,
      'enabled': true,
      'updatedAt': now,
      'rules': seed,
    });
  }

  Future<void> addPlainWord(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await _addRule(mode: BadWordRuleMode.plain, value: trimmed);
  }

  Future<void> addRegex(String pattern) async {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) return;
    await _addRule(mode: BadWordRuleMode.regex, value: trimmed);
  }

  Future<void> _addRule({
    required BadWordRuleMode mode,
    required String value,
  }) async {
    final ref = _docRef();
    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final config = BadWordsConfig.fromDoc(snap);
      final alreadyExists = config.rules.values.any(
        (r) => r.value.trim() == value.trim(),
      );
      if (alreadyExists) {
        return;
      }

      final id = _newRuleId();
      tx.set(ref, {
        'schema_version': 1,
        'enabled': true,
        'updatedAt': now,
        'rules': {
          id: {
            'mode': badWordRuleModeToString(mode),
            'value': value,
            'enabled': true,
            'createdAt': now,
            'updatedAt': now,
          },
        },
      }, SetOptions(merge: true));
    });
  }

  Future<void> deleteRule(String ruleId) async {
    if (ruleId.trim().isEmpty) return;
    await _docRef().update({
      'updatedAt': FieldValue.serverTimestamp(),
      'rules.$ruleId': FieldValue.delete(),
    });
  }

  Future<void> setRuleEnabled(String ruleId, bool enabled) async {
    if (ruleId.trim().isEmpty) return;
    await _docRef().update({
      'updatedAt': FieldValue.serverTimestamp(),
      'rules.$ruleId.enabled': enabled,
      'rules.$ruleId.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _newRuleId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 20).toRadixString(16).padLeft(5, '0');
    return 'bw_${now}_$rand';
  }
}

const _defaultSeedWords = <String>[
  '씨발',
  '개새끼',
  '병신',
  '좆',
  '씌발',
  '좌빨',
  '수꼴',
  '대깨',
  '토착왜구',
  '사이비',
  '개독',
  '대출',
  '카지노',
  '토토',
  '주식 리딩방',
  '밴드 가입',
  '010',
  '노인네',
  '틀딱',
  '꼰대',
];
