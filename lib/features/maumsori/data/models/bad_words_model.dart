import 'package:cloud_firestore/cloud_firestore.dart';

enum BadWordRuleMode { plain, regex }

BadWordRuleMode badWordRuleModeFromString(String? raw) {
  switch (raw) {
    case 'regex':
      return BadWordRuleMode.regex;
    case 'plain':
    default:
      return BadWordRuleMode.plain;
  }
}

String badWordRuleModeToString(BadWordRuleMode mode) {
  switch (mode) {
    case BadWordRuleMode.plain:
      return 'plain';
    case BadWordRuleMode.regex:
      return 'regex';
  }
}

class BadWordRule {
  final String id;
  final BadWordRuleMode mode;
  final String value;
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BadWordRule({
    required this.id,
    required this.mode,
    required this.value,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BadWordRule.fromMap(String id, Map<String, dynamic> map) {
    return BadWordRule(
      id: id,
      mode: badWordRuleModeFromString(map['mode'] as String?),
      value: (map['value'] as String?) ?? '',
      isEnabled: (map['enabled'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForWrite() {
    return {
      'mode': badWordRuleModeToString(mode),
      'value': value,
      'enabled': isEnabled,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BadWordsConfig {
  final bool isEnabled;
  final int schemaVersion;
  final DateTime? updatedAt;
  final Map<String, BadWordRule> rules;

  const BadWordsConfig({
    required this.isEnabled,
    required this.schemaVersion,
    required this.updatedAt,
    required this.rules,
  });

  factory BadWordsConfig.empty() {
    return const BadWordsConfig(
      isEnabled: true,
      schemaVersion: 1,
      updatedAt: null,
      rules: {},
    );
  }

  factory BadWordsConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return BadWordsConfig.empty();

    final rawRules = data['rules'];
    final rules = <String, BadWordRule>{};
    if (rawRules is Map) {
      for (final entry in rawRules.entries) {
        final id = entry.key;
        final v = entry.value;
        if (id is! String) continue;
        if (v is Map<String, dynamic>) {
          rules[id] = BadWordRule.fromMap(id, v);
        } else if (v is Map) {
          rules[id] = BadWordRule.fromMap(
            id,
            v.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    }

    return BadWordsConfig(
      isEnabled: (data['enabled'] as bool?) ?? true,
      schemaVersion: (data['schema_version'] as num?)?.toInt() ?? 1,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      rules: rules,
    );
  }

  List<BadWordRule> sortedRules() {
    final list = rules.values.toList();
    list.sort((a, b) {
      final aa = a.createdAt;
      final bb = b.createdAt;
      if (aa == null && bb == null) return a.value.compareTo(b.value);
      if (aa == null) return 1;
      if (bb == null) return -1;
      return aa.compareTo(bb);
    });
    return list;
  }
}
