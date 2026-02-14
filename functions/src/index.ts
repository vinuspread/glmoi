import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { findBadWordsMatches, loadBadWordsConfigCached } from './badWords';
import { optimizeImageOnUpload } from './imageOptimize';
import { fillImageAssetDerivedUrls } from './imageAssetDerivatives';
import { kakaoCustomToken } from './kakaoAuth';
import { incrementShareCount, likeQuoteOnce, reactToQuoteOnce, reportMalmoiOnce } from './interactions';
import { moderateUserMalmoiBadWords } from './quoteModeration';
import { createMalmoiPost, deleteMalmoiPost, updateMalmoiPost } from './malmoi';

admin.initializeApp();

// Re-export storage trigger.
export { optimizeImageOnUpload };

export { fillImageAssetDerivedUrls };

// Auth
export { kakaoCustomToken };

// Interactions
export { likeQuoteOnce, incrementShareCount, reportMalmoiOnce, reactToQuoteOnce };

export { moderateUserMalmoiBadWords };
export { createMalmoiPost, updateMalmoiPost, deleteMalmoiPost };

export const badWordsValidate = onCall(async (request) => {
  const text = (request.data?.text as string | undefined) ?? '';
  if (typeof text !== 'string') {
    throw new HttpsError('invalid-argument', 'text must be a string');
  }

  const config = await loadBadWordsConfigCached();
  const matches = findBadWordsMatches(text, config);
  if (matches.length > 0) {
    throw new HttpsError('failed-precondition', 'bad words detected', {
      matches,
    });
  }

  return { ok: true };
});
