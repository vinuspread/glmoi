import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getSenderDisplayName, sendPushToUser } from './notifications';

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
  const userLikedRef = db()
    .collection('users')
    .doc(uid)
    .collection('liked_quotes')
    .doc(quoteId);
  const userRef = db().collection('users').doc(uid);

  const result = await db().runTransaction(async (tx) => {
    const quoteSnap = await tx.get(quoteRef);
    if (!quoteSnap.exists) {
      throw new HttpsError('not-found', 'quote not found');
    }

    const likeSnap = await tx.get(likeRef);
    if (likeSnap.exists) {
      return { alreadyLiked: true, authorUid: undefined, quoteType: undefined };
    }

    const quoteData = quoteSnap.data() || {};

    tx.set(likeRef, {
      uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    
    tx.set(userLikedRef, {
      quote_id: quoteId,
      app_id: quoteData.app_id || 'maumsori',
      type: quoteData.type || 'quote',
      content: quoteData.content || '',
      author: quoteData.author || '',
      author_name: quoteData.author_name || quoteData.author || '',
      author_photo_url: quoteData.author_photo_url || null,
      image_url: quoteData.image_url || null,
      liked_at: FieldValue.serverTimestamp(),
    });

    tx.update(quoteRef, {
      like_count: FieldValue.increment(1),
    });

    tx.set(
      userRef,
      {
        liked_quotes_count: FieldValue.increment(1),
      },
      { merge: true }
    );

    return { alreadyLiked: false, authorUid: quoteData.user_uid as string | undefined, quoteType: quoteData.type as string | undefined };
  });

  if (!result.alreadyLiked && result.authorUid) {
    const senderName = await getSenderDisplayName(uid);
    await sendPushToUser(
      result.authorUid,
      uid,
      { title: '글모이', body: `${senderName}님이 회원님의 글을 좋아해요` },
      { quote_id: quoteId, quote_type: result.quoteType ?? 'quote' }
    );
  }

  return { ok: true, ...result };
});

export const incrementShareCount = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const quoteId = requireString(request.data?.quoteId, 'quoteId');

  const quoteSnap = await db().collection('quotes').doc(quoteId).get();
  if (!quoteSnap.exists) {
    throw new HttpsError('not-found', 'quote not found');
  }
  const quoteData = quoteSnap.data() || {};

  await db().collection('quotes').doc(quoteId).update({
    share_count: FieldValue.increment(1),
  });

  const authorUid = quoteData.user_uid as string | undefined;
  if (authorUid) {
    const senderName = await getSenderDisplayName(uid);
    await sendPushToUser(
      authorUid,
      uid,
      { title: '글모이', body: `${senderName}님이 회원님의 글을 공유했어요` },
      { quote_id: quoteId, quote_type: quoteData.type ?? 'quote' }
    );
  }

  return { ok: true };
});

const SAVED_QUOTE_ALLOWED_FIELDS = [
  'app_id',
  'type',
  'content',
  'author',
  'author_name',
  'author_photo_url',
  'image_url',
] as const;

function sanitizeQuoteData(raw: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const key of SAVED_QUOTE_ALLOWED_FIELDS) {
    if (key in raw) {
      result[key] = raw[key] ?? null;
    }
  }
  return result;
}

export const toggleSaveQuote = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const quoteId = requireString(request.data?.quoteId, 'quoteId');

  const savedRef = db()
    .collection('users')
    .doc(uid)
    .collection('saved_quotes')
    .doc(quoteId);

  const result = await db().runTransaction(async (tx) => {
    const snap = await tx.get(savedRef);

    if (snap.exists) {
      tx.delete(savedRef);
      tx.set(
        db().collection('users').doc(uid),
        {
          saved_quotes_count: FieldValue.increment(-1),
        },
        { merge: true }
      );
      return { saved: false };
    } else {
      const rawQuoteData = (request.data?.quoteData ?? {}) as Record<string, unknown>;
      const safeQuoteData = sanitizeQuoteData(rawQuoteData);
      tx.set(savedRef, {
        quote_id: quoteId,
        ...safeQuoteData,
        saved_at: FieldValue.serverTimestamp(),
      });
      tx.set(
        db().collection('users').doc(uid),
        {
          saved_quotes_count: FieldValue.increment(1),
        },
        { merge: true }
      );
      return { saved: true };
    }
  });

  return { ok: true, ...result };
});

const REACTION_LABELS: Record<string, string> = {
  comfort: '위로받았어요',
  empathize: '공감해요',
  good: '좋아요',
  touched: '감동받았어요',
  fan: '팬이에요',
};

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
      return { alreadyReacted: true, reactionType: prev ?? null, authorUid: null };
    }

    const quoteData = quoteSnap.data() || {};
    const authorUid = quoteData.user_uid as string | undefined;

    tx.set(reactionRef, {
      uid,
      user_id: uid,
      reaction_type: reactionType,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(quoteRef, {
      [`reaction_counts.${reactionType}`]: FieldValue.increment(1),
    });

    if (authorUid && typeof authorUid === 'string') {
      const authorRef = db().collection('users').doc(authorUid);
      tx.set(
        authorRef,
        {
          [`received_reactions.${reactionType}`]: FieldValue.increment(1),
        },
        { merge: true }
      );
    }

    return { alreadyReacted: false, reactionType, authorUid };
  });

  if (!result.alreadyReacted && result.authorUid) {
    const senderName = await getSenderDisplayName(uid);
    const label = REACTION_LABELS[reactionType] ?? reactionType;
    await sendPushToUser(
      result.authorUid,
      uid,
      { title: '글모이', body: `${senderName}님이 '${label}'로 반응했어요` },
      { quote_id: quoteId, quote_type: 'malmoi' }
    );
  }

  return { ok: true, ...result };
});
