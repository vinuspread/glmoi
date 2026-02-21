"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.incrementViewCount = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const notifications_1 = require("./notifications");
const REGION = 'asia-northeast3';
const VIEW_MILESTONES = [3, 50, 100, 300, 500, 800, 1000];
exports.incrementViewCount = (0, https_1.onCall)({ region: REGION }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'login required');
    const quoteId = request.data?.quoteId;
    if (typeof quoteId !== 'string' || quoteId.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'quoteId is required');
    }
    const quoteRef = (0, firestore_1.getFirestore)().collection('quotes').doc(quoteId);
    const { newCount, authorUid, quoteType } = await (0, firestore_1.getFirestore)().runTransaction(async (tx) => {
        const snap = await tx.get(quoteRef);
        if (!snap.exists)
            throw new https_1.HttpsError('not-found', 'quote not found');
        const data = snap.data() || {};
        const prev = data.view_count ?? 0;
        const next = prev + 1;
        tx.update(quoteRef, { view_count: firestore_1.FieldValue.increment(1) });
        return {
            newCount: next,
            authorUid: data.user_uid,
            quoteType: data.type ?? 'quote',
        };
    });
    if (authorUid && VIEW_MILESTONES.includes(newCount)) {
        await (0, notifications_1.sendPushToUser)(authorUid, uid, { title: '글모이', body: `회원님의 글을 ${newCount}명이 읽었어요` }, { quote_id: quoteId, quote_type: quoteType });
    }
    return { ok: true, viewCount: newCount };
});
