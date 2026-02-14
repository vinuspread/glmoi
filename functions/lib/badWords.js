"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadBadWordsConfigCached = loadBadWordsConfigCached;
exports.normalize = normalize;
exports.findBadWordsMatches = findBadWordsMatches;
const firestore_1 = require("firebase-admin/firestore");
let cache = null;
async function loadBadWordsConfigCached(ttlMs = 60_000) {
    const now = Date.now();
    if (cache && now - cache.fetchedAtMs < ttlMs)
        return cache.config;
    const snap = await (0, firestore_1.getFirestore)().collection('admin_settings').doc('bad_words').get();
    const data = snap.data() || {};
    const enabled = data.enabled ?? true;
    const rawRules = data.rules ?? {};
    const rules = [];
    for (const [id, v] of Object.entries(rawRules)) {
        if (!v || typeof v !== 'object')
            continue;
        const mode = v.mode === 'regex' ? 'regex' : 'plain';
        const value = typeof v.value === 'string' ? v.value : '';
        if (!value.trim())
            continue;
        const ruleEnabled = v.enabled ?? true;
        rules.push({ id, mode, value, enabled: ruleEnabled });
    }
    const config = { enabled, rules };
    cache = { fetchedAtMs: now, config };
    return config;
}
function normalize(input, keepDigits) {
    // NFKC to collapse odd unicode forms.
    const lower = input.normalize('NFKC').toLowerCase();
    let out = '';
    for (const ch of lower) {
        const code = ch.charCodeAt(0);
        // Zero-width
        if (ch === '\u200b' || ch === '\u200c' || ch === '\u200d' || ch === '\ufeff')
            continue;
        const isHangul = code >= 0xac00 && code <= 0xd7a3;
        const isLatin = (code >= 0x61 && code <= 0x7a) || (code >= 0x41 && code <= 0x5a);
        const isDigit = code >= 0x30 && code <= 0x39;
        if (isHangul || isLatin || (keepDigits && isDigit)) {
            out += ch;
        }
    }
    return out;
}
function findBadWordsMatches(rawText, config) {
    if (!config.enabled)
        return [];
    const rules = config.rules.filter((r) => r.enabled);
    if (rules.length === 0)
        return [];
    const normalizedNoDigits = normalize(rawText, false);
    const normalizedWithDigits = normalize(rawText, true);
    const matches = [];
    for (const r of rules) {
        const v = r.value.trim();
        if (!v)
            continue;
        if (r.mode === 'plain') {
            const needsDigits = /\d/.test(v);
            const needle = normalize(v, needsDigits);
            const hay = needsDigits ? normalizedWithDigits : normalizedNoDigits;
            if (!needle)
                continue;
            if (hay.includes(needle)) {
                matches.push({ ruleId: r.id, mode: r.mode, value: r.value });
            }
            continue;
        }
        // Regex - admin-entered patterns can be dangerous if overly complex.
        // Keep patterns reasonably short.
        if (v.length > 300)
            continue;
        let re;
        try {
            re = new RegExp(v);
        }
        catch {
            continue;
        }
        if (re.test(rawText) || re.test(normalizedWithDigits)) {
            matches.push({ ruleId: r.id, mode: r.mode, value: r.value });
        }
    }
    return matches;
}
