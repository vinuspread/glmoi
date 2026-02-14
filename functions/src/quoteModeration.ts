import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { FieldValue, getFirestore } from 'firebase-admin/firestore';

import { findBadWordsMatches, loadBadWordsConfigCached } from './badWords';

const REGION = 'asia-northeast3';

export const moderateUserMalmoiBadWords = onDocumentWritten(
  {
    document: 'quotes/{docId}',
    region: REGION,
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;

    const before = event.data?.before;
    const beforeData = before?.exists ? (before.data() as any) : null;
    const data = after.data() as any;

    if (data?.type !== 'malmoi') return;
    if (data?.is_user_post !== true) return;
    if (data?.is_active !== true) return;

    const content = typeof data?.content === 'string' ? data.content : '';
    if (!content.trim()) return;

    const beforeContent =
      typeof beforeData?.content === 'string' ? beforeData.content : null;
    if (beforeContent !== null && beforeContent === content) return;

    const config = await loadBadWordsConfigCached();
    const matches = findBadWordsMatches(content, config);
    if (matches.length === 0) return;

    await getFirestore().collection('quotes').doc(after.id).set(
      {
        is_active: false,
        moderation_status: 'rejected',
        moderation_reason: 'bad_words',
        moderation_bad_words_matches: matches,
        moderation_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);
