import { getFirestore } from 'firebase-admin/firestore';

export type BadWordRuleMode = 'plain' | 'regex';

export type BadWordRule = {
  id: string;
  mode: BadWordRuleMode;
  value: string;
  enabled: boolean;
};

export type BadWordsConfig = {
  enabled: boolean;
  rules: BadWordRule[];
};

type Cached = {
  fetchedAtMs: number;
  config: BadWordsConfig;
};

let cache: Cached | null = null;

export async function loadBadWordsConfigCached(ttlMs = 60_000): Promise<BadWordsConfig> {
  const now = Date.now();
  if (cache && now - cache.fetchedAtMs < ttlMs) return cache.config;

  const snap = await getFirestore().collection('admin_settings').doc('bad_words').get();
  const data = snap.data() || {};
  const enabled = (data.enabled as boolean | undefined) ?? true;

  const rawRules = (data.rules as Record<string, any> | undefined) ?? {};
  const rules: BadWordRule[] = [];
  for (const [id, v] of Object.entries(rawRules)) {
    if (!v || typeof v !== 'object') continue;
    const mode = (v.mode as string | undefined) === 'regex' ? 'regex' : 'plain';
    const value = typeof v.value === 'string' ? v.value : '';
    if (!value.trim()) continue;
    const ruleEnabled = (v.enabled as boolean | undefined) ?? true;
    rules.push({ id, mode, value, enabled: ruleEnabled });
  }

  const config: BadWordsConfig = { enabled, rules };
  cache = { fetchedAtMs: now, config };
  return config;
}

export function normalize(input: string, keepDigits: boolean): string {
  // NFKC to collapse odd unicode forms.
  const lower = input.normalize('NFKC').toLowerCase();
  let out = '';
  for (const ch of lower) {
    const code = ch.charCodeAt(0);

    // Zero-width
    if (ch === '\u200b' || ch === '\u200c' || ch === '\u200d' || ch === '\ufeff') continue;

    const isHangul = code >= 0xac00 && code <= 0xd7a3;
    const isLatin = (code >= 0x61 && code <= 0x7a) || (code >= 0x41 && code <= 0x5a);
    const isDigit = code >= 0x30 && code <= 0x39;
    if (isHangul || isLatin || (keepDigits && isDigit)) {
      out += ch;
    }
  }
  return out;
}

export function findBadWordsMatches(
  rawText: string,
  config: BadWordsConfig,
): { ruleId: string; mode: BadWordRuleMode; value: string }[] {
  if (!config.enabled) return [];
  const rules = config.rules.filter((r) => r.enabled);
  if (rules.length === 0) return [];

  const normalizedNoDigits = normalize(rawText, false);
  const normalizedWithDigits = normalize(rawText, true);

  const matches: { ruleId: string; mode: BadWordRuleMode; value: string }[] = [];

  for (const r of rules) {
    const v = r.value.trim();
    if (!v) continue;

    if (r.mode === 'plain') {
      const needsDigits = /\d/.test(v);
      const needle = normalize(v, needsDigits);
      const hay = needsDigits ? normalizedWithDigits : normalizedNoDigits;
      if (!needle) continue;
      if (hay.includes(needle)) {
        matches.push({ ruleId: r.id, mode: r.mode, value: r.value });
      }
      continue;
    }

    // Regex - admin-entered patterns can be dangerous if overly complex.
    // Keep patterns reasonably short.
    if (v.length > 300) continue;
    let re: RegExp;
    try {
      re = new RegExp(v);
    } catch {
      continue;
    }
    if (re.test(rawText) || re.test(normalizedWithDigits)) {
      matches.push({ ruleId: r.id, mode: r.mode, value: r.value });
    }
  }

  return matches;
}
