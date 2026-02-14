import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

const REGION = 'asia-northeast3';

type KakaoMeResponse = {
  id?: number;
};

async function fetchKakaoUserId(accessToken: string): Promise<string> {
  let res: Response;
  try {
    res = await fetch('https://kapi.kakao.com/v2/user/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });
  } catch {
    throw new HttpsError('unavailable', 'failed to call Kakao API');
  }

  if (!res.ok) {
    throw new HttpsError('unauthenticated', 'invalid Kakao access token');
  }

  const data = (await res.json()) as KakaoMeResponse;
  const id = data?.id;
  if (typeof id !== 'number') {
    throw new HttpsError('internal', 'Kakao response missing user id');
  }
  return String(id);
}

export const kakaoCustomToken = onCall({ region: REGION }, async (request) => {
  const accessToken = (request.data?.accessToken as string | undefined) ?? '';
  if (typeof accessToken !== 'string' || accessToken.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'accessToken is required');
  }

  const kakaoUserId = await fetchKakaoUserId(accessToken.trim());
  const uid = `kakao:${kakaoUserId}`;

  const customToken = await admin.auth().createCustomToken(uid, {
    provider: 'kakao',
    kakao_user_id: kakaoUserId,
  });

  return {
    uid,
    customToken,
  };
});
