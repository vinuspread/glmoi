import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const REGION = 'asia-northeast3';

type TestScenario =
  | 'like'
  | 'react_comfort'
  | 'react_empathize'
  | 'react_good'
  | 'react_touched'
  | 'react_fan'
  | 'share'
  | 'view_3'
  | 'view_50'
  | 'view_100'
  | 'view_300'
  | 'view_500'
  | 'view_800'
  | 'view_1000';

const SCENARIO_NOTIFICATION: Record<TestScenario, { title: string; body: string }> = {
  like: { title: '글모이', body: '테스터님이 회원님의 글을 좋아해요' },
  react_comfort: { title: '글모이', body: "테스터님이 '위로받았어요'로 반응했어요" },
  react_empathize: { title: '글모이', body: "테스터님이 '공감해요'로 반응했어요" },
  react_good: { title: '글모이', body: "테스터님이 '좋아요'로 반응했어요" },
  react_touched: { title: '글모이', body: "테스터님이 '감동받았어요'로 반응했어요" },
  react_fan: { title: '글모이', body: "테스터님이 '팬이에요'로 반응했어요" },
  share: { title: '글모이', body: '테스터님이 회원님의 글을 공유했어요' },
  view_3: { title: '글모이', body: '회원님의 글을 3명이 읽었어요' },
  view_50: { title: '글모이', body: '회원님의 글을 50명이 읽었어요' },
  view_100: { title: '글모이', body: '회원님의 글을 100명이 읽었어요' },
  view_300: { title: '글모이', body: '회원님의 글을 300명이 읽었어요' },
  view_500: { title: '글모이', body: '회원님의 글을 500명이 읽었어요' },
  view_800: { title: '글모이', body: '회원님의 글을 800명이 읽었어요' },
  view_1000: { title: '글모이', body: '회원님의 글을 1000명이 읽었어요' },
};

function isValidScenario(v: unknown): v is TestScenario {
  return typeof v === 'string' && v in SCENARIO_NOTIFICATION;
}

export const sendTestNotification = onCall({ region: REGION }, async (request) => {
  const targetUid = request.data?.targetUid;
  const scenario = request.data?.scenario;

  if (typeof targetUid !== 'string' || targetUid.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'targetUid is required');
  }
  if (!isValidScenario(scenario)) {
    throw new HttpsError('invalid-argument', 'invalid scenario');
  }

  const userSnap = await getFirestore().collection('users').doc(targetUid).get();
  if (!userSnap.exists) {
    throw new HttpsError('not-found', 'user not found');
  }

  const fcmToken = userSnap.data()?.fcm_token as string | undefined;
  if (!fcmToken) {
    throw new HttpsError('failed-precondition', 'user has no fcm_token');
  }

  const quoteSnap = await getFirestore()
    .collection('quotes')
    .where('user_uid', '==', targetUid)
    .where('is_active', '==', true)
    .limit(1)
    .get();

  let quoteId = 'unknown';
  let quoteType = 'malmoi';
  if (!quoteSnap.empty) {
    quoteId = quoteSnap.docs[0].id;
    quoteType = (quoteSnap.docs[0].data().type as string | undefined) ?? 'malmoi';
  }

  const notification = SCENARIO_NOTIFICATION[scenario];
  await getMessaging().send({
    token: fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: { quote_id: quoteId, quote_type: quoteType },
    android: {
      notification: {
        channelId: 'glmoi_notifications',
      },
    },
  });

  return { ok: true, quoteId };
});
