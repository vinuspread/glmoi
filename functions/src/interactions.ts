import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

const REGION = 'asia-northeast3';

function db() {
  // NOTE: admin.initializeApp() is called in src/index.ts.
  // Avoid calling getFirestore() at module load time.
  return getFirestore();
}

function requireUid(request: any): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  return uid;
}

function requireString(v: unknown, name: string): string {
  if (typeof v !== 'string' || v.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${name} is required`);
  }
  return v.trim();
}

export type ReportReasonCode = 'spam_ad' | 'hate' | 'sexual' | 'privacy' | 'etc';

export type ReactionType =
  | 'comfort'
  | 'empathize'
  | 'good'
  | 'touched'
  | 'fan';

function parseReactionType(raw: unknown): ReactionType {
  const v = requireString(raw, 'reactionType');
  switch (v) {
    case 'comfort':
    case 'empathize':
    case 'good':
    case 'touched':
    case 'fan':
      return v;
    default:
      throw new HttpsError('invalid-argument', 'invalid reactionType');
  }
}

function parseReasonCode(raw: unknown): ReportReasonCode {
  const v = requireString(raw, 'reasonCode');
  switch (v) {
    case 'spam_ad':
    case 'hate':
    case 'sexual':
    case 'privacy':
    case 'etc':
      return v;
    default:
      throw new HttpsError('invalid-argument', 'invalid reasonCode');
  }
}

export const likeQuoteOnce = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const quoteId = requireString(request.data?.quoteId, 'quoteId');

  const quoteRef = db().collection('quotes').doc(quoteId);
  const likeRef = quoteRef.collection('likes').doc(uid);

  const result = await db().runTransaction(async (tx) => {
    const quoteSnap = await tx.get(quoteRef);
    if (!quoteSnap.exists) {
      throw new HttpsError('not-found', 'quote not found');
    }

    const likeSnap = await tx.get(likeRef);
    if (likeSnap.exists) {
      return { alreadyLiked: true };
    }

    tx.set(likeRef, {
      uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(quoteRef, {
      like_count: FieldValue.increment(1),
    });

    return { alreadyLiked: false };
  });

  return { ok: true, ...result };
});

export const incrementShareCount = onCall({ region: REGION }, async (request) => {
  requireUid(request);
  const quoteId = requireString(request.data?.quoteId, 'quoteId');

  await db().collection('quotes').doc(quoteId).update({
    share_count: FieldValue.increment(1),
  });

  return { ok: true };
});

export const reportMalmoiOnce = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const quoteId = requireString(request.data?.quoteId, 'quoteId');
  const reasonCode = parseReasonCode(request.data?.reasonCode);

  const quoteRef = db().collection('quotes').doc(quoteId);
  const reportRef = quoteRef.collection('reports').doc(uid);

  const result = await db().runTransaction(async (tx) => {
    const quoteSnap = await tx.get(quoteRef);
    if (!quoteSnap.exists) {
      throw new HttpsError('not-found', 'quote not found');
    }
    const quote = quoteSnap.data() || {};
    if (quote.type !== 'malmoi') {
      throw new HttpsError('failed-precondition', 'report is only for malmoi');
    }

    const reportSnap = await tx.get(reportRef);
    if (reportSnap.exists) {
      return { alreadyReported: true };
    }

    tx.set(reportRef, {
      uid,
      reason_code: reasonCode,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(quoteRef, {
      report_count: FieldValue.increment(1),
      [`report_reasons.${reasonCode}`]: FieldValue.increment(1),
      last_report_reason_code: reasonCode,
      last_report_at: FieldValue.serverTimestamp(),
    });

    return { alreadyReported: false };
  });

  return { ok: true, ...result };
});

export const reactToQuoteOnce = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const quoteId = requireString(request.data?.quoteId, 'quoteId');
  const reactionType = parseReactionType(request.data?.reactionType);

  const quoteRef = db().collection('quotes').doc(quoteId);
  const reactionRef = quoteRef.collection('reactions').doc(uid);

  const result = await db().runTransaction(async (tx) => {
    const quoteSnap = await tx.get(quoteRef);
    if (!quoteSnap.exists) {
      throw new HttpsError('not-found', 'quote not found');
    }

    const reactionSnap = await tx.get(reactionRef);
    if (reactionSnap.exists) {
      const prev = (reactionSnap.data() || {}).reaction_type;
      return { alreadyReacted: true, reactionType: prev ?? null };
    }

    tx.set(reactionRef, {
      uid,
      reaction_type: reactionType,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(quoteRef, {
      [`reaction_counts.${reactionType}`]: FieldValue.increment(1),
    });

    return { alreadyReacted: false, reactionType };
  });

  return { ok: true, ...result };
});
