import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

export async function sendPushToUser(
  recipientUid: string,
  senderUid: string,
  notification: { title: string; body: string },
  data: Record<string, string>
): Promise<void> {
  if (recipientUid === senderUid) return;

  try {
    const userSnap = await getFirestore().collection('users').doc(recipientUid).get();
    const fcmToken = userSnap.data()?.fcm_token as string | undefined;
    if (!fcmToken) return;

    await getMessaging().send({
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
  } catch {
    // best-effort: never throw
  }
}

export async function getSenderDisplayName(uid: string): Promise<string> {
  try {
    const snap = await getFirestore().collection('users').doc(uid).get();
    return (snap.data()?.display_name as string | undefined) ?? '누군가';
  } catch {
    return '누군가';
  }
}
