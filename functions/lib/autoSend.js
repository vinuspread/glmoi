"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.executeAutoSend = exports.triggerAutoSendNow = exports.getAutoSendConfig = exports.saveAutoSendConfig = void 0;
const admin = __importStar(require("firebase-admin"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
/**
 * 자동발송 설정 저장 (관리자 호출)
 */
exports.saveAutoSendConfig = (0, https_1.onCall)(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError('unauthenticated', 'Must be logged in');
    }
    // 관리자 권한 체크 (간단히 특정 이메일만 허용)
    const userEmail = request.auth?.token.email;
    if (userEmail !== 'vinus@vinus.co.kr') {
        throw new https_1.HttpsError('permission-denied', 'Admin only');
    }
    const { is_enabled, first_send_time, second_send_time } = request.data;
    if (typeof is_enabled !== 'boolean') {
        throw new https_1.HttpsError('invalid-argument', 'is_enabled must be boolean');
    }
    if (typeof first_send_time !== 'string' || !/^\d{2}:\d{2}$/.test(first_send_time)) {
        throw new https_1.HttpsError('invalid-argument', 'first_send_time must be HH:mm format');
    }
    if (second_send_time !== undefined && second_send_time !== null) {
        if (typeof second_send_time !== 'string' || !/^\d{2}:\d{2}$/.test(second_send_time)) {
            throw new https_1.HttpsError('invalid-argument', 'second_send_time must be HH:mm format');
        }
    }
    const config = {
        is_enabled,
        first_send_time,
        second_send_time: second_send_time || null,
        updated_at: admin.firestore.Timestamp.now(),
    };
    const db = admin.firestore();
    await db.collection('config').doc('auto_send').set(config);
    v2_1.logger.info('Auto-send config saved', config);
    return { success: true };
});
/**
 * 자동발송 설정 조회
 */
exports.getAutoSendConfig = (0, https_1.onCall)(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError('unauthenticated', 'Must be logged in');
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
    const data = doc.data();
    return {
        is_enabled: data.is_enabled,
        first_send_time: data.first_send_time,
        second_send_time: data.second_send_time || null,
    };
});
/**
 * 랜덤 콘텐츠 선택 (활성화된 공식 콘텐츠 중)
 */
async function selectRandomQuote() {
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
        v2_1.logger.warn('No active quotes found');
        return null;
    }
    const quotes = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    const randomIndex = Math.floor(Math.random() * quotes.length);
    return quotes[randomIndex];
}
/**
 * FCM 토픽으로 푸시 알림 발송
 */
async function sendPushNotification(quote) {
    const messaging = admin.messaging();
    const message = {
        data: {
            type: 'auto_send',
            quote_id: quote.id,
            quote_type: quote.type || 'quote',
            image_url: quote.image_url || '',
            content: quote.content || '',
            author: quote.author || '',
        },
        android: {
            priority: 'high',
        },
        topic: 'all_users',
    };
    v2_1.logger.info('========== FCM SEND START ==========');
    v2_1.logger.info('Sending push notification', {
        quoteId: quote.id,
        quoteType: quote.type || 'quote',
        contentPreview: quote.content ? quote.content.substring(0, 100) : 'N/A',
        hasImageUrl: !!quote.image_url,
        topic: 'all_users',
    });
    try {
        const response = await messaging.send(message);
        v2_1.logger.info('Push notification sent successfully', {
            messageId: response,
            quoteId: quote.id,
            timestamp: new Date().toISOString(),
        });
        v2_1.logger.info('========== FCM SEND END (SUCCESS) ==========');
        return response;
    }
    catch (error) {
        v2_1.logger.error('========== FCM SEND END (FAILED) ==========');
        v2_1.logger.error('Failed to send push notification', {
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
exports.triggerAutoSendNow = (0, https_1.onCall)(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError('unauthenticated', 'Must be logged in');
    }
    // 관리자 권한 체크
    const userEmail = request.auth?.token.email;
    if (userEmail !== 'vinus@vinus.co.kr') {
        throw new https_1.HttpsError('permission-denied', 'Admin only');
    }
    v2_1.logger.info('Manual auto-send triggered by admin', { email: userEmail });
    const db = admin.firestore();
    const configDoc = await db.collection('config').doc('auto_send').get();
    if (!configDoc.exists) {
        throw new https_1.HttpsError('failed-precondition', 'Auto-send config not found');
    }
    const config = configDoc.data();
    if (!config.is_enabled) {
        throw new https_1.HttpsError('failed-precondition', 'Auto-send is disabled');
    }
    // 랜덤 콘텐츠 선택
    const quote = await selectRandomQuote();
    if (!quote) {
        throw new https_1.HttpsError('not-found', 'No active quotes found');
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
    v2_1.logger.info('Manual auto-send completed', { quoteId: quote.id, messageId });
    return {
        success: true,
        quote_id: String(quote.id),
        message_id: String(messageId),
        content_preview: String(quote.content).substring(0, 100),
    };
});
/**
 * 자동발송 실행 (Cloud Scheduler 호출)
 * 매시간 실행되며, 설정된 시간과 일치하면 발송
 */
exports.executeAutoSend = (0, scheduler_1.onSchedule)({
    schedule: 'every 1 hours', // 매시간 실행
    timeZone: 'Asia/Seoul',
}, async (event) => {
    v2_1.logger.info('========================================');
    v2_1.logger.info('Auto-send scheduler triggered');
    v2_1.logger.info('Timestamp:', new Date().toISOString());
    const db = admin.firestore();
    const configDoc = await db.collection('config').doc('auto_send').get();
    if (!configDoc.exists) {
        v2_1.logger.warn('Auto-send config not found in Firestore, skipping');
        v2_1.logger.info('========================================');
        return;
    }
    const config = configDoc.data();
    v2_1.logger.info('Config loaded', {
        is_enabled: config.is_enabled,
        first_send_time: config.first_send_time,
        second_send_time: config.second_send_time || 'N/A',
    });
    if (!config.is_enabled) {
        v2_1.logger.info('Auto-send is disabled in config, skipping');
        v2_1.logger.info('========================================');
        return;
    }
    // 현재 시간 (HH:mm)
    const now = new Date();
    const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    // 발송 시간과 일치하는지 확인
    const shouldSend = currentTime === config.first_send_time ||
        (config.second_send_time && currentTime === config.second_send_time);
    v2_1.logger.info('Time check', {
        currentTime,
        firstSendTime: config.first_send_time,
        secondSendTime: config.second_send_time || 'N/A',
        shouldSend,
    });
    if (!shouldSend) {
        v2_1.logger.info('Current time does not match configured send times, skipping');
        v2_1.logger.info('========================================');
        return;
    }
    v2_1.logger.info('Time matched! Executing auto-send', { currentTime });
    // 랜덤 콘텐츠 선택
    const quote = await selectRandomQuote();
    if (!quote) {
        v2_1.logger.error('No active quote found for sending, aborting');
        v2_1.logger.info('========================================');
        return;
    }
    v2_1.logger.info('Quote selected', {
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
    v2_1.logger.info('Auto-send completed successfully', {
        quoteId: quote.id,
        logId: logId.id,
        timestamp: new Date().toISOString(),
    });
    v2_1.logger.info('========================================');
});
