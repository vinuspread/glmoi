"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.moderateUserMalmoiBadWords = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const badWords_1 = require("./badWords");
const REGION = 'asia-northeast3';
exports.moderateUserMalmoiBadWords = (0, firestore_1.onDocumentWritten)({
    document: 'quotes/{docId}',
    region: REGION,
    timeoutSeconds: 60,
    memory: '256MiB',
}, async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists)
        return;
    const before = event.data?.before;
    const beforeData = before?.exists ? before.data() : null;
    const data = after.data();
    if (data?.type !== 'malmoi')
        return;
    if (data?.is_user_post !== true)
        return;
    if (data?.is_active !== true)
        return;
    const content = typeof data?.content === 'string' ? data.content : '';
    if (!content.trim())
        return;
    const beforeContent = typeof beforeData?.content === 'string' ? beforeData.content : null;
    if (beforeContent !== null && beforeContent === content)
        return;
    const config = await (0, badWords_1.loadBadWordsConfigCached)();
    const matches = (0, badWords_1.findBadWordsMatches)(content, config);
    if (matches.length === 0)
        return;
    await (0, firestore_2.getFirestore)().collection('quotes').doc(after.id).set({
        is_active: false,
        moderation_status: 'rejected',
        moderation_reason: 'bad_words',
        moderation_bad_words_matches: matches,
        moderation_at: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
});
