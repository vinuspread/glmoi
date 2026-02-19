"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteMalmoiPost = exports.updateMalmoiPost = exports.createMalmoiPost = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const badWords_1 = require("./badWords");
const REGION = 'asia-northeast3';
function parseLength(raw) {
    if (raw === 'short' || raw === 'long')
        return raw;
    throw new https_1.HttpsError('invalid-argument', 'malmoi_length must be short|long');
}
function parseString(raw, name, opts) {
    const max = opts?.max ?? 2000;
    const allowEmpty = opts?.allowEmpty ?? false;
    if (typeof raw !== 'string') {
        throw new https_1.HttpsError('invalid-argument', `${name} must be a string`);
    }
    const v = raw.trim();
    if (!allowEmpty && v.length === 0) {
        throw new https_1.HttpsError('invalid-argument', `${name} is required`);
    }
    if (v.length > max) {
        throw new https_1.HttpsError('invalid-argument', `${name} is too long`);
    }
    return v;
}
async function assertCategoryAllowed(category) {
    const snap = await (0, firestore_1.getFirestore)().collection('config').doc('app_config').get();
    const data = snap.data() || {};
    const categories = Array.isArray(data.categories) ? data.categories : [];
    if (!categories.includes(category)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid category');
    }
}
async function assertNoBadWords(text) {
    const config = await (0, badWords_1.loadBadWordsConfigCached)();
    const matches = (0, badWords_1.findBadWordsMatches)(text, config);
    if (matches.length > 0) {
        throw new https_1.HttpsError('failed-precondition', 'bad words detected', { matches });
    }
}
exports.createMalmoiPost = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    invoker: 'public', // Grant allUsers roles/run.invoker
}, async (request) => {
    console.log('[createMalmoiPost] Called', {
        hasAuth: !!request.auth,
        uid: request.auth?.uid,
        email: request.auth?.token?.email,
    });
    if (!request.auth) {
        console.error('[createMalmoiPost] No auth context!');
        throw new https_1.HttpsError('unauthenticated', 'login required');
    }
    const content = parseString(request.data?.content, 'content', { max: 2000 });
    const category = parseString(request.data?.category, 'category', { max: 20 });
    const malmoiLength = parseLength(request.data?.malmoi_length);
    const imageUrl = parseString(request.data?.image_url ?? '', 'image_url', { max: 500, allowEmpty: true });
    const author = parseString(request.data?.author ?? '', 'author', { max: 50, allowEmpty: true });
    await assertCategoryAllowed(category);
    await assertNoBadWords(content);
    const uid = request.auth.uid;
    const db = (0, firestore_1.getFirestore)();
    // Get user profile for author_name and author_photo_url
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data() || {};
    const authorName = userData.display_name || author || '';
    const authorPhotoUrl = userData.photo_url || null;
    const ref = await db.collection('quotes').add({
        app_id: 'maumsori',
        type: 'malmoi',
        malmoi_length: malmoiLength,
        content,
        author,
        author_name: authorName,
        author_photo_url: authorPhotoUrl,
        category,
        image_url: imageUrl.length ? imageUrl : null,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        is_active: true,
        is_user_post: true,
        is_approved: true,
        report_count: 0,
        like_count: 0,
        share_count: 0,
        user_uid: uid,
        user_provider: 'firebase',
        user_id: uid,
    });
    await db.collection('users').doc(uid).set({
        my_quotes_count: firestore_1.FieldValue.increment(1),
    }, { merge: true });
    return { ok: true, id: ref.id };
});
exports.updateMalmoiPost = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    invoker: 'public',
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'login required');
    }
    const quoteId = parseString(request.data?.quote_id, 'quote_id', { max: 200 });
    const content = parseString(request.data?.content, 'content', { max: 2000 });
    await assertNoBadWords(content);
    const uid = request.auth.uid;
    const docRef = (0, firestore_1.getFirestore)().collection('quotes').doc(quoteId);
    const snap = await docRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError('not-found', 'quote not found');
    }
    const data = snap.data();
    if (data?.app_id !== 'maumsori' || data?.type !== 'malmoi' || data?.is_user_post !== true) {
        throw new https_1.HttpsError('failed-precondition', 'not a malmoi user post');
    }
    const ownerOk = (typeof data?.user_uid === 'string' && data.user_uid === uid)
        || (data?.user_provider === 'firebase' && data?.user_id === uid);
    if (!ownerOk) {
        throw new https_1.HttpsError('permission-denied', 'not owner');
    }
    await docRef.set({ content, updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
    return { ok: true };
});
exports.deleteMalmoiPost = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    invoker: 'public',
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'login required');
    }
    const quoteId = parseString(request.data?.quote_id, 'quote_id', { max: 200 });
    const uid = request.auth.uid;
    const db = (0, firestore_1.getFirestore)();
    const docRef = db.collection('quotes').doc(quoteId);
    const snap = await docRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError('not-found', 'quote not found');
    }
    const data = snap.data();
    if (data?.app_id !== 'maumsori' || data?.type !== 'malmoi' || data?.is_user_post !== true) {
        throw new https_1.HttpsError('failed-precondition', 'not a malmoi user post');
    }
    const ownerOk = (typeof data?.user_uid === 'string' && data.user_uid === uid)
        || (data?.user_provider === 'firebase' && data?.user_id === uid);
    if (!ownerOk) {
        throw new https_1.HttpsError('permission-denied', 'not owner');
    }
    await docRef.delete();
    await db.collection('users').doc(uid).set({
        my_quotes_count: firestore_1.FieldValue.increment(-1),
    }, { merge: true });
    return { ok: true };
});
