import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { onObjectFinalized } from 'firebase-functions/v2/storage';

import * as crypto from 'node:crypto';
import * as os from 'node:os';
import * as path from 'node:path';

import sharp from 'sharp';

type DerivedPaths = {
  appId: string;
  originalPath: string;
  baseName: string;
  thumbPath: string;
  webpPath: string;
};

function parseDerivedPaths(objectPath: string): DerivedPaths | null {
  // Expected: assets/{appId}/images/{objectName}
  const parts = objectPath.split('/');
  if (parts.length < 4) return null;
  if (parts[0] !== 'assets') return null;
  const appId = parts[1];
  if (parts[2] !== 'images') return null;

  const fileName = parts[parts.length - 1];
  const ext = path.extname(fileName).toLowerCase();
  const baseName = ext ? fileName.slice(0, -ext.length) : fileName;

  const thumbPath = `assets/${appId}/thumbnails/${baseName}_thumb.jpg`;
  const webpPath = `assets/${appId}/webp/${baseName}.webp`;
  return {
    appId,
    originalPath: objectPath,
    baseName,
    thumbPath,
    webpPath,
  };
}

function getDownloadToken(metadata: any): string | null {
  // Firebase download tokens live under metadata.metadata.firebaseStorageDownloadTokens
  const tokens =
    (metadata?.metadata?.firebaseStorageDownloadTokens as string | undefined) ||
    (metadata?.firebaseStorageDownloadTokens as string | undefined);

  if (!tokens || typeof tokens !== 'string') return null;
  // Can be comma-separated.
  const first = tokens.split(',')[0]?.trim();
  return first || null;
}

function buildDownloadUrl(bucket: string, objectPath: string, token: string): string {
  // Standard Firebase download URL format.
  const encoded = encodeURIComponent(objectPath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encoded}?alt=media&token=${token}`;
}

export const optimizeImageOnUpload = onObjectFinalized(
  {
    region: 'asia-northeast3',
    // Image processing can be memory heavy.
    memory: '1GiB',
    timeoutSeconds: 300,
  },
  async (event) => {
    const obj = event.data;
    const bucketName = obj.bucket;
    const objectPath = obj.name;
    const contentType = obj.contentType;

    if (!bucketName || !objectPath) return;
    if (!contentType || !contentType.toLowerCase().startsWith('image/')) return;

    // Avoid infinite loops for derived outputs.
    if (objectPath.includes('/thumbnails/') || objectPath.includes('/webp/')) return;

    const derived = parseDerivedPaths(objectPath);
    if (!derived) return;

    const bucket = admin.storage().bucket(bucketName);
    const originalFile = bucket.file(objectPath);

    // Fetch metadata so we can locate the Firestore doc by original_url.
    const [meta] = await originalFile.getMetadata();
    const originalToken = getDownloadToken(meta);
    if (!originalToken) {
      // If there is no token, we can't compute the same download URL
      // that the client stored.
      return;
    }
    const originalUrl = buildDownloadUrl(bucketName, objectPath, originalToken);

    const tmpOriginal = path.join(os.tmpdir(), path.basename(objectPath));
    await originalFile.download({ destination: tmpOriginal });

    const src = sharp(tmpOriginal).rotate();

    // 1) Thumbnail (used in image pool + composer picker)
    // Keep 9:16 to match the admin UI aspect.
    const thumbBuffer = await src
      .clone()
      .resize(360, 640, { fit: 'cover' })
      .jpeg({ quality: 82, mozjpeg: true })
      .toBuffer();

    const thumbToken = crypto.randomUUID();
    const thumbFile = bucket.file(derived.thumbPath);
    await thumbFile.save(thumbBuffer, {
      contentType: 'image/jpeg',
      metadata: {
        metadata: {
          firebaseStorageDownloadTokens: thumbToken,
        },
        cacheControl: 'public,max-age=31536000',
      },
    });
    const thumbnailUrl = buildDownloadUrl(bucketName, derived.thumbPath, thumbToken);

    // 2) WebP (used as background image for composing)
    const webpBuffer = await src
      .clone()
      .resize({ width: 1080, withoutEnlargement: true })
      .webp({ quality: 82 })
      .toBuffer();

    const webpToken = crypto.randomUUID();
    const webpFile = bucket.file(derived.webpPath);
    await webpFile.save(webpBuffer, {
      contentType: 'image/webp',
      metadata: {
        metadata: {
          firebaseStorageDownloadTokens: webpToken,
        },
        cacheControl: 'public,max-age=31536000',
      },
    });
    const webpUrl = buildDownloadUrl(bucketName, derived.webpPath, webpToken);

    try {
      const db = admin.firestore();
      const quotesSnap = await db
        .collection('quotes')
        .where('app_id', '==', derived.appId)
        .where('image_url', '==', originalUrl)
        .limit(200)
        .get();

      if (!quotesSnap.empty) {
        const batch = db.batch();
        for (const doc of quotesSnap.docs) {
          batch.update(doc.ref, {
            image_url: webpUrl,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      console.warn('Failed to upgrade quotes image_url to webp_url', e);
    }

    // Current schema stores original_url as a download URL.
    const db = admin.firestore();
    const snap = await db
      .collection('image_assets')
      .where('original_url', '==', originalUrl)
      .limit(1)
      .get();

    if (snap.empty) {
      return;
    }

    await snap.docs[0].ref.set(
      {
        thumbnail_url: thumbnailUrl,
        webp_url: webpUrl,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);
