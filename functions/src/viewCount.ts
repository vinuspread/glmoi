import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { sendPushToUser } from './notifications';

const REGION = 'asia-northeast3';
const VIEW_MILESTONES = [3, 50, 100, 300, 500, 800, 1000];

export const incrementViewCount = onCall({ region: REGION }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');

  const quoteId = request.data?.quoteId;
  if (typeof quoteId !== 'string' || quoteId.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'quoteId is required');
  }

  const quoteRef = getFirestore().collection('quotes').doc(quoteId);

  const { newCount, authorUid, quoteType } = await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(quoteRef);
    if (!snap.exists) throw new HttpsError('not-found', 'quote not found');

    const data = snap.data() || {};
    const prev = (data.view_count as number | undefined) ?? 0;
    const next = prev + 1;

    tx.update(quoteRef, { view_count: FieldValue.increment(1) });

    return {
      newCount: next,
      authorUid: data.user_uid as string | undefined,
      quoteType: (data.type as string | undefined) ?? 'quote',
    };
  });

  if (authorUid && VIEW_MILESTONES.includes(newCount)) {
    await sendPushToUser(
      authorUid,
      uid,
      { title: '글모이', body: `회원님의 글을 ${newCount}명이 읽었어요` },
      { quote_id: quoteId, quote_type: quoteType }
    );
  }

  return { ok: true, viewCount: newCount };
});
