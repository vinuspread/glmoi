import '../../data/models/bad_words_model.dart';

class BadWordsMatch {
  final BadWordRule rule;
  final String display;

  const BadWordsMatch({required this.rule, required this.display});
}

class BadWordsMatcher {
  const BadWordsMatcher();

  static String normalize({required String input, required bool keepDigits}) {
    // Goal: catch obfuscations like "씨.발", "씨~발", "씨1발".
    // Strategy: remove whitespace/symbols, optionally remove digits.
    final lower = input.toLowerCase();

    final sb = StringBuffer();
    for (final rune in lower.runes) {
      final c = String.fromCharCode(rune);
      if (_isZeroWidth(c)) continue;

      if (_isHangulSyllable(rune) || _isLatinLetter(rune)) {
        sb.write(c);
        continue;
      }
      if (keepDigits && _isDigit(rune)) {
        sb.write(c);
        continue;
      }

      // Drop everything else: spaces, punctuation, symbols.
    }
    return sb.toString();
  }

  List<BadWordsMatch> findMatches(String rawText, BadWordsConfig config) {
    if (!config.isEnabled) return const [];

    final rules = config.rules.values.where((r) => r.isEnabled).toList();
    if (rules.isEmpty) return const [];

    final normalizedNoDigits = normalize(input: rawText, keepDigits: false);
    final normalizedWithDigits = normalize(input: rawText, keepDigits: true);

    final matches = <BadWordsMatch>[];
    for (final rule in rules) {
      final v = rule.value.trim();
      if (v.isEmpty) continue;

      if (rule.mode == BadWordRuleMode.plain) {
        final needsDigits = v.runes.any(_isDigit);
        final needle = normalize(input: v, keepDigits: needsDigits);
        final hay = needsDigits ? normalizedWithDigits : normalizedNoDigits;
        if (needle.isEmpty) continue;
        if (hay.contains(needle)) {
          matches.add(BadWordsMatch(rule: rule, display: v));
        }
        continue;
      }

      // regex
      final pattern = v;
      RegExp re;
      try {
        re = RegExp(pattern);
      } catch (_) {
        // Invalid patterns should be prevented by admin UI validation,
        // but we fail-safe by ignoring them.
        continue;
      }

      // Run regex on both raw + normalized-with-digits.
      if (re.hasMatch(rawText) || re.hasMatch(normalizedWithDigits)) {
        matches.add(BadWordsMatch(rule: rule, display: pattern));
      }
    }

    return matches;
  }
}

bool _isZeroWidth(String c) {
  return c == '\u200b' || c == '\u200c' || c == '\u200d' || c == '\ufeff';
}

bool _isHangulSyllable(int rune) {
  return rune >= 0xAC00 && rune <= 0xD7A3;
}

bool _isLatinLetter(int rune) {
  return (rune >= 0x61 && rune <= 0x7A) || (rune >= 0x41 && rune <= 0x5A);
}

bool _isDigit(int rune) {
  return rune >= 0x30 && rune <= 0x39;
}
