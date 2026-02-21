"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendPushToUser = sendPushToUser;
exports.getSenderDisplayName = getSenderDisplayName;
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
async function sendPushToUser(recipientUid, senderUid, notification, data) {
    if (recipientUid === senderUid)
        return;
    try {
        const userSnap = await (0, firestore_1.getFirestore)().collection('users').doc(recipientUid).get();
        const fcmToken = userSnap.data()?.fcm_token;
        if (!fcmToken)
            return;
        await (0, messaging_1.getMessaging)().send({
            token: fcmToken,
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data,
            android: {
                notification: {
                    channelId: 'glmoi_notifications',
                },
            },
        });
    }
    catch {
        // best-effort: never throw
    }
}
async function getSenderDisplayName(uid) {
    try {
        const snap = await (0, firestore_1.getFirestore)().collection('users').doc(uid).get();
        return snap.data()?.display_name ?? '누군가';
    }
    catch {
        return '누군가';
    }
}
