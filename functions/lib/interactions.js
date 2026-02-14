"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reactToQuoteOnce = exports.reportMalmoiOnce = exports.incrementShareCount = exports.likeQuoteOnce = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const REGION = 'asia-northeast3';
function db() {
    // NOTE: admin.initializeApp() is called in src/index.ts.
    // Avoid calling getFirestore() at module load time.
    return (0, firestore_1.getFirestore)();
}
function requireUid(request) {
    const uid = request.auth?.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'login required');
    return uid;
}
function requireString(v, name) {
    if (typeof v !== 'string' || v.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', `${name} is required`);
    }
    return v.trim();
}
function parseReactionType(raw) {
    const v = requireString(raw, 'reactionType');
    switch (v) {
        case 'comfort':
        case 'empathize':
        case 'good':
        case 'touched':
        case 'fan':
            return v;
        default:
            throw new https_1.HttpsError('invalid-argument', 'invalid reactionType');
    }
}
function parseReasonCode(raw) {
    const v = requireString(raw, 'reasonCode');
    switch (v) {
        case 'spam_ad':
        case 'hate':
        case 'sexual':
        case 'privacy':
        case 'etc':
            return v;
        default:
            throw new https_1.HttpsError('invalid-argument', 'invalid reasonCode');
    }
}
exports.likeQuoteOnce = (0, https_1.onCall)({ region: REGION }, async (request) => {
    const uid = requireUid(request);
    const quoteId = requireString(request.data?.quoteId, 'quoteId');
    const quoteRef = db().collection('quotes').doc(quoteId);
    const likeRef = quoteRef.collection('likes').doc(uid);
    const result = await db().runTransaction(async (tx) => {
        const quoteSnap = await tx.get(quoteRef);
        if (!quoteSnap.exists) {
            throw new https_1.HttpsError('not-found', 'quote not found');
        }
        const likeSnap = await tx.get(likeRef);
        if (likeSnap.exists) {
            return { alreadyLiked: true };
        }
        tx.set(likeRef, {
            uid,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        tx.update(quoteRef, {
            like_count: firestore_1.FieldValue.increment(1),
        });
        return { alreadyLiked: false };
    });
    return { ok: true, ...result };
});
exports.incrementShareCount = (0, https_1.onCall)({ region: REGION }, async (request) => {
    requireUid(request);
    const quoteId = requireString(request.data?.quoteId, 'quoteId');
    await db().collection('quotes').doc(quoteId).update({
        share_count: firestore_1.FieldValue.increment(1),
    });
    return { ok: true };
});
exports.reportMalmoiOnce = (0, https_1.onCall)({ region: REGION }, async (request) => {
    const uid = requireUid(request);
    const quoteId = requireString(request.data?.quoteId, 'quoteId');
    const reasonCode = parseReasonCode(request.data?.reasonCode);
    const quoteRef = db().collection('quotes').doc(quoteId);
    const reportRef = quoteRef.collection('reports').doc(uid);
    const result = await db().runTransaction(async (tx) => {
        const quoteSnap = await tx.get(quoteRef);
        if (!quoteSnap.exists) {
            throw new https_1.HttpsError('not-found', 'quote not found');
        }
        const quote = quoteSnap.data() || {};
        if (quote.type !== 'malmoi') {
            throw new https_1.HttpsError('failed-precondition', 'report is only for malmoi');
        }
        const reportSnap = await tx.get(reportRef);
        if (reportSnap.exists) {
            return { alreadyReported: true };
        }
        tx.set(reportRef, {
            uid,
            reason_code: reasonCode,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        tx.update(quoteRef, {
            report_count: firestore_1.FieldValue.increment(1),
            [`report_reasons.${reasonCode}`]: firestore_1.FieldValue.increment(1),
            last_report_reason_code: reasonCode,
            last_report_at: firestore_1.FieldValue.serverTimestamp(),
        });
        return { alreadyReported: false };
    });
    return { ok: true, ...result };
});
exports.reactToQuoteOnce = (0, https_1.onCall)({ region: REGION }, async (request) => {
    const uid = requireUid(request);
    const quoteId = requireString(request.data?.quoteId, 'quoteId');
    const reactionType = parseReactionType(request.data?.reactionType);
    const quoteRef = db().collection('quotes').doc(quoteId);
    const reactionRef = quoteRef.collection('reactions').doc(uid);
    const result = await db().runTransaction(async (tx) => {
        const quoteSnap = await tx.get(quoteRef);
        if (!quoteSnap.exists) {
            throw new https_1.HttpsError('not-found', 'quote not found');
        }
        const reactionSnap = await tx.get(reactionRef);
        if (reactionSnap.exists) {
            const prev = (reactionSnap.data() || {}).reaction_type;
            return { alreadyReacted: true, reactionType: prev ?? null };
        }
        tx.set(reactionRef, {
            uid,
            reaction_type: reactionType,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        tx.update(quoteRef, {
            [`reaction_counts.${reactionType}`]: firestore_1.FieldValue.increment(1),
        });
        return { alreadyReacted: false, reactionType };
    });
    return { ok: true, ...result };
});
