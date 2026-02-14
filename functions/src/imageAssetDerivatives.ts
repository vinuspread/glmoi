import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import type { Bucket } from '@google-cloud/storage';

import {
  buildDownloadUrl,
  deriveThumbObjectPath,
  deriveWebpObjectPath,
  parseFirebaseStorageDownloadUrl,
} from './storageUrl';

function getDownloadToken(metadata: any): string | null {
  const tokens =
    (metadata?.metadata?.firebaseStorageDownloadTokens as string | undefined) ||
    (metadata?.firebaseStorageDownloadTokens as string | undefined);

  if (!tokens || typeof tokens !== 'string') return null;
  const first = tokens.split(',')[0]?.trim();
  return first || null;
}

async function tryGetDownloadUrl(bucket: Bucket, objectPath: string) {
  try {
    const file = bucket.file(objectPath);
    const [meta] = await file.getMetadata();
    const token = getDownloadToken(meta);
    if (!token) return null;
    return buildDownloadUrl(bucket.name, objectPath, token);
  } catch (_) {
    return null;
  }
}

export const fillImageAssetDerivedUrls = onDocumentCreated(
  {
    document: 'image_assets/{id}',
    region: 'asia-northeast3',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;

    const originalUrl = (data['original_url'] as string | undefined) ?? '';
    if (!originalUrl) return;

    const parsed = parseFirebaseStorageDownloadUrl(originalUrl);
    if (!parsed) return;

    const webpObjectPath = deriveWebpObjectPath(parsed.objectPath);
    const thumbObjectPath = deriveThumbObjectPath(parsed.objectPath);
    if (!webpObjectPath && !thumbObjectPath) return;

    const bucket = admin.storage().bucket(parsed.bucket);
    const [thumbUrl, webpUrl] = await Promise.all([
      thumbObjectPath ? tryGetDownloadUrl(bucket, thumbObjectPath) : null,
      webpObjectPath ? tryGetDownloadUrl(bucket, webpObjectPath) : null,
    ]);

    const update: Record<string, unknown> = {
      updated_at: FieldValue.serverTimestamp(),
    };

    if (thumbUrl) update['thumbnail_url'] = thumbUrl;
    if (webpUrl) update['webp_url'] = webpUrl;

    if (Object.keys(update).length <= 1) return;
    await snap.ref.set(update, { merge: true });
  },
);
