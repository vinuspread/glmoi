import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

interface AutoSendConfig {
  is_enabled: boolean;
  first_send_time: string; // "HH:mm" format
  second_send_time?: string; // "HH:mm" format (optional)
  updated_at: admin.firestore.Timestamp;
}

/**
 * 자동발송 설정 저장 (관리자 호출)
 */
export const saveAutoSendConfig = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Must be logged in');
  }

  // 관리자 권한 체크 (간단히 특정 이메일만 허용)
  const userEmail = request.auth?.token.email;
  if (userEmail !== 'vinus@vinus.co.kr') {
    throw new HttpsError('permission-denied', 'Admin only');
  }

  const { is_enabled, first_send_time, second_send_time } = request.data;

  if (typeof is_enabled !== 'boolean') {
    throw new HttpsError('invalid-argument', 'is_enabled must be boolean');
  }

  if (typeof first_send_time !== 'string' || !/^\d{2}:\d{2}$/.test(first_send_time)) {
    throw new HttpsError('invalid-argument', 'first_send_time must be HH:mm format');
  }

  if (second_send_time !== undefined && second_send_time !== null) {
    if (typeof second_send_time !== 'string' || !/^\d{2}:\d{2}$/.test(second_send_time)) {
      throw new HttpsError('invalid-argument', 'second_send_time must be HH:mm format');
    }
  }

  const config: AutoSendConfig = {
    is_enabled,
    first_send_time,
    second_send_time: second_send_time || null,
    updated_at: admin.firestore.Timestamp.now(),
  };

  const db = admin.firestore();
  await db.collection('config').doc('auto_send').set(config);

  logger.info('Auto-send config saved', config);

  return { success: true };
});

/**
 * 자동발송 설정 조회
 */
export const getAutoSendConfig = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Must be logged in');
  }

  const db = admin.firestore();
  const doc = await db.collection('config').doc('auto_send').get();

  if (!doc.exists) {
    return {
      is_enabled: false,
      first_send_time: '09:00',
      second_send_time: null,
    };
  }

  const data = doc.data() as AutoSendConfig;
  return {
    is_enabled: data.is_enabled,
    first_send_time: data.first_send_time,
    second_send_time: data.second_send_time || null,
  };
});

/**
 * 랜덤 콘텐츠 선택 (활성화된 공식 콘텐츠 중)
 */
async function selectRandomQuote(): Promise<any | null> {
  const db = admin.firestore();
  
  // 활성화된 공식 콘텐츠만 (글모이 제외)
  const snapshot = await db
    .collection('quotes')
    .where('app_id', '==', 'maumsori')
    .where('is_active', '==', true)
    .where('is_user_post', '==', false)
    .limit(100) // 최근 100개 중 랜덤
    .get();

  if (snapshot.empty) {
    logger.warn('No active quotes found');
    return null;
  }

  const quotes = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  const randomIndex = Math.floor(Math.random() * quotes.length);
  return quotes[randomIndex];
}

async function sendPushNotification(quote: any) {
  const messaging = admin.messaging();

  const contentPreview = (quote.content || '').substring(0, 100);
  const author = (quote.author || '').trim();
  const body = author ? `${contentPreview}\n\n- ${author} -` : contentPreview;

  const message = {
    notification: {
      title: '오늘의 좋은글',
      body,
    },
    data: {
      type: 'auto_send',
      quote_id: quote.id,
      quote_type: quote.type || 'quote',
      image_url: quote.image_url || '',
      content: quote.content || '',
      author: quote.author || '',
    },
    android: {
      priority: 'high' as const,
      notification: {
        channelId: 'glmoi_notifications',
      },
    },
    topic: 'all_users',
  };

  logger.info('========== FCM SEND START ==========');
  logger.info('Sending push notification', {
    quoteId: quote.id,
    quoteType: quote.type || 'quote',
    contentPreview: quote.content ? quote.content.substring(0, 100) : 'N/A',
    hasImageUrl: !!quote.image_url,
    topic: 'all_users',
  });

  try {
    const response = await messaging.send(message);
    logger.info('Push notification sent successfully', {
      messageId: response,
      quoteId: quote.id,
      timestamp: new Date().toISOString(),
    });
    logger.info('========== FCM SEND END (SUCCESS) ==========');
    return response;
  } catch (error) {
    logger.error('========== FCM SEND END (FAILED) ==========');
    logger.error('Failed to send push notification', {
      error,
      quoteId: quote.id,
      timestamp: new Date().toISOString(),
    });
    throw error;
  }
}

/**
 * 자동발송 수동 실행 (테스트용 callable)
 */
export const triggerAutoSendNow = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Must be logged in');
  }

  // 관리자 권한 체크
  const userEmail = request.auth?.token.email;
  if (userEmail !== 'vinus@vinus.co.kr') {
    throw new HttpsError('permission-denied', 'Admin only');
  }

  logger.info('Manual auto-send triggered by admin', { email: userEmail });

  const db = admin.firestore();
  const configDoc = await db.collection('config').doc('auto_send').get();

  if (!configDoc.exists) {
    throw new HttpsError('failed-precondition', 'Auto-send config not found');
  }

  const config = configDoc.data() as AutoSendConfig;

  if (!config.is_enabled) {
    throw new HttpsError('failed-precondition', 'Auto-send is disabled');
  }

  // 랜덤 콘텐츠 선택
  const quote = await selectRandomQuote();
  if (!quote) {
    throw new HttpsError('not-found', 'No active quotes found');
  }

  // 푸시 알림 발송
  const messageId = await sendPushNotification(quote);

  // 발송 기록 저장
  const now = new Date();
  const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  
  await db.collection('auto_send_logs').add({
    quote_id: quote.id,
    sent_at: admin.firestore.Timestamp.now(),
    sent_time: currentTime,
    quote_content: quote.content.substring(0, 200),
    manual: true,
    triggered_by: userEmail,
  });

  logger.info('Manual auto-send completed', { quoteId: quote.id, messageId });

  return {
    success: true,
    quote_id: String(quote.id),
    message_id: String(messageId),
    content_preview: String(quote.content).substring(0, 100),
  };
});

/**
 * 자동발송 실행 (Cloud Scheduler 호출)
 * 매 분 실행되며, 설정된 시간과 일치하면 발송
 */
export const executeAutoSend = onSchedule(
  {
    schedule: 'every 1 minutes',
    timeZone: 'Asia/Seoul',
  },
  async (event) => {
    logger.info('========================================');
    logger.info('Auto-send scheduler triggered');
    logger.info('Timestamp:', new Date().toISOString());

    const db = admin.firestore();
    const configDoc = await db.collection('config').doc('auto_send').get();

    if (!configDoc.exists) {
      logger.warn('Auto-send config not found in Firestore, skipping');
      logger.info('========================================');
      return;
    }

    const config = configDoc.data() as AutoSendConfig;
    logger.info('Config loaded', {
      is_enabled: config.is_enabled,
      first_send_time: config.first_send_time,
      second_send_time: config.second_send_time || 'N/A',
    });

    if (!config.is_enabled) {
      logger.info('Auto-send is disabled in config, skipping');
      logger.info('========================================');
      return;
    }

    // new Date()는 UTC이므로 Intl.DateTimeFormat으로 KST 변환 필요
    const now = new Date();
    const kstFormatter = new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Asia/Seoul',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
    const currentTime = kstFormatter.format(now);

    // 발송 시간과 일치하는지 확인
    const shouldSend =
      currentTime === config.first_send_time ||
      (config.second_send_time && currentTime === config.second_send_time);

    logger.info('Time check (KST)', {
      currentTime,
      firstSendTime: config.first_send_time,
      secondSendTime: config.second_send_time || 'N/A',
      shouldSend,
    });

    if (!shouldSend) {
      logger.info('Current time does not match configured send times, skipping');
      logger.info('========================================');
      return;
    }

    logger.info('Time matched! Executing auto-send', { currentTime });

    // 랜덤 콘텐츠 선택
    const quote = await selectRandomQuote();
    if (!quote) {
      logger.error('No active quote found for sending, aborting');
      logger.info('========================================');
      return;
    }

    logger.info('Quote selected', {
      quoteId: quote.id,
      type: quote.type,
      contentPreview: quote.content ? quote.content.substring(0, 100) : 'N/A',
    });

    // 푸시 알림 발송
    await sendPushNotification(quote);

    // 발송 기록 저장
    const logId = await db.collection('auto_send_logs').add({
      quote_id: quote.id,
      sent_at: admin.firestore.Timestamp.now(),
      sent_time: currentTime,
      quote_content: quote.content.substring(0, 200),
      manual: false,
    });

    logger.info('Auto-send completed successfully', {
      quoteId: quote.id,
      logId: logId.id,
      timestamp: new Date().toISOString(),
    });
    logger.info('========================================');
  }
);
