import * as path from 'node:path';

export type StorageDownloadUrlParts = {
  bucket: string;
  objectPath: string;
};

export function parseFirebaseStorageDownloadUrl(url: string): StorageDownloadUrlParts | null {
  try {
    const u = new URL(url);
    if (u.hostname !== 'firebasestorage.googleapis.com') return null;
    const parts = u.pathname.split('/').filter(Boolean);
    if (parts.length < 4) return null;
    if (parts[0] !== 'v0') return null;
    if (parts[1] !== 'b') return null;
    const bucket = parts[2];
    if (parts[3] !== 'o') return null;
    const rawObject = parts.slice(4).join('/');
    const objectPath = decodeURIComponent(rawObject);
    if (!bucket || !objectPath) return null;
    return { bucket, objectPath };
  } catch (_) {
    return null;
  }
}

export function deriveWebpObjectPath(originalObjectPath: string): string | null {
  const parts = originalObjectPath.split('/');
  if (parts.length < 4) return null;
  if (parts[0] !== 'assets') return null;
  const appId = parts[1];
  if (!appId) return null;
  if (parts[2] !== 'images') return null;

  const fileName = parts[parts.length - 1] ?? '';
  const ext = path.extname(fileName).toLowerCase();
  const baseName = ext ? fileName.slice(0, -ext.length) : fileName;
  if (!baseName) return null;

  return `assets/${appId}/webp/${baseName}.webp`;
}

export function deriveThumbObjectPath(originalObjectPath: string): string | null {
  const parts = originalObjectPath.split('/');
  if (parts.length < 4) return null;
  if (parts[0] !== 'assets') return null;
  const appId = parts[1];
  if (!appId) return null;
  if (parts[2] !== 'images') return null;

  const fileName = parts[parts.length - 1] ?? '';
  const ext = path.extname(fileName).toLowerCase();
  const baseName = ext ? fileName.slice(0, -ext.length) : fileName;
  if (!baseName) return null;

  return `assets/${appId}/thumbnails/${baseName}_thumb.jpg`;
}

export function buildDownloadUrl(bucket: string, objectPath: string, token: string): string {
  const encoded = encodeURIComponent(objectPath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encoded}?alt=media&token=${token}`;
}
