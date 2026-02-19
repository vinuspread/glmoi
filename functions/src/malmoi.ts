import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { findBadWordsMatches, loadBadWordsConfigCached } from './badWords';

const REGION = 'asia-northeast3';

type MalmoiLength = 'short' | 'long';

function parseLength(raw: unknown): MalmoiLength {
  if (raw === 'short' || raw === 'long') return raw;
  throw new HttpsError('invalid-argument', 'malmoi_length must be short|long');
}

function parseString(raw: unknown, name: string, opts?: { max?: number; allowEmpty?: boolean }): string {
  const max = opts?.max ?? 2000;
  const allowEmpty = opts?.allowEmpty ?? false;
  if (typeof raw !== 'string') {
    throw new HttpsError('invalid-argument', `${name} must be a string`);
  }
  const v = raw.trim();
  if (!allowEmpty && v.length === 0) {
    throw new HttpsError('invalid-argument', `${name} is required`);
  }
  if (v.length > max) {
    throw new HttpsError('invalid-argument', `${name} is too long`);
  }
  return v;
}

async function assertCategoryAllowed(category: string): Promise<void> {
  const snap = await getFirestore().collection('config').doc('app_config').get();
  const data = snap.data() || {};
  const categories = Array.isArray(data.categories) ? data.categories : [];
  if (!categories.includes(category)) {
    throw new HttpsError('invalid-argument', 'invalid category');
  }
}

async function assertNoBadWords(text: string): Promise<void> {
  const config = await loadBadWordsConfigCached();
  const matches = findBadWordsMatches(text, config);
  if (matches.length > 0) {
    throw new HttpsError('failed-precondition', 'bad words detected', { matches });
  }
}

export const createMalmoiPost = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    invoker: 'public', // Grant allUsers roles/run.invoker
  },
  async (request) => {
    console.log('[createMalmoiPost] Called', {
      hasAuth: !!request.auth,
      uid: request.auth?.uid,
      email: request.auth?.token?.email,
    });
    
    if (!request.auth) {
      console.error('[createMalmoiPost] No auth context!');
      throw new HttpsError('unauthenticated', 'login required');
    }

    const content = parseString(request.data?.content, 'content', { max: 2000 });
    const category = parseString(request.data?.category, 'category', { max: 20 });
    const malmoiLength = parseLength(request.data?.malmoi_length);
    const imageUrl = parseString(request.data?.image_url ?? '', 'image_url', { max: 500, allowEmpty: true });
    const author = parseString(request.data?.author ?? '', 'author', { max: 50, allowEmpty: true });

    await assertCategoryAllowed(category);
    await assertNoBadWords(content);

    const uid = request.auth.uid;
    const db = getFirestore();

    // Get user profile for author_name and author_photo_url
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data() || {};
    const authorName = (userData.display_name as string) || author || '';
    const authorPhotoUrl = (userData.photo_url as string) || null;

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
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
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

    await db.collection('users').doc(uid).set(
      {
        my_quotes_count: FieldValue.increment(1),
      },
      { merge: true }
    );

    return { ok: true, id: ref.id };
  },
);

export const updateMalmoiPost = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'login required');
    }

    const quoteId = parseString(request.data?.quote_id, 'quote_id', { max: 200 });
    const content = parseString(request.data?.content, 'content', { max: 2000 });

    await assertNoBadWords(content);

    const uid = request.auth.uid;
    const docRef = getFirestore().collection('quotes').doc(quoteId);
    const snap = await docRef.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'quote not found');
    }
    const data = snap.data() as any;
    if (data?.app_id !== 'maumsori' || data?.type !== 'malmoi' || data?.is_user_post !== true) {
      throw new HttpsError('failed-precondition', 'not a malmoi user post');
    }
    const ownerOk =
      (typeof data?.user_uid === 'string' && data.user_uid === uid)
      || (data?.user_provider === 'firebase' && data?.user_id === uid);
    if (!ownerOk) {
      throw new HttpsError('permission-denied', 'not owner');
    }

    await docRef.set({ content, updatedAt: FieldValue.serverTimestamp() }, { merge: true });

    return { ok: true };
  },
);

export const deleteMalmoiPost = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'login required');
    }

    const quoteId = parseString(request.data?.quote_id, 'quote_id', { max: 200 });

    const uid = request.auth.uid;
    const db = getFirestore();
    const docRef = db.collection('quotes').doc(quoteId);
    const snap = await docRef.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'quote not found');
    }
    const data = snap.data() as any;
    if (data?.app_id !== 'maumsori' || data?.type !== 'malmoi' || data?.is_user_post !== true) {
      throw new HttpsError('failed-precondition', 'not a malmoi user post');
    }
    const ownerOk =
      (typeof data?.user_uid === 'string' && data.user_uid === uid)
      || (data?.user_provider === 'firebase' && data?.user_id === uid);
    if (!ownerOk) {
      throw new HttpsError('permission-denied', 'not owner');
    }

    await docRef.delete();

    await db.collection('users').doc(uid).set(
      {
        my_quotes_count: FieldValue.increment(-1),
      },
      { merge: true }
    );

    return { ok: true };
  },
);
