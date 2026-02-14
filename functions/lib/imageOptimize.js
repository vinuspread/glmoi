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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.optimizeImageOnUpload = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-functions/v2/storage");
const crypto = __importStar(require("node:crypto"));
const os = __importStar(require("node:os"));
const path = __importStar(require("node:path"));
const sharp_1 = __importDefault(require("sharp"));
function parseDerivedPaths(objectPath) {
    // Expected: assets/{appId}/images/{objectName}
    const parts = objectPath.split('/');
    if (parts.length < 4)
        return null;
    if (parts[0] !== 'assets')
        return null;
    const appId = parts[1];
    if (parts[2] !== 'images')
        return null;
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
function getDownloadToken(metadata) {
    // Firebase download tokens live under metadata.metadata.firebaseStorageDownloadTokens
    const tokens = metadata?.metadata?.firebaseStorageDownloadTokens ||
        metadata?.firebaseStorageDownloadTokens;
    if (!tokens || typeof tokens !== 'string')
        return null;
    // Can be comma-separated.
    const first = tokens.split(',')[0]?.trim();
    return first || null;
}
function buildDownloadUrl(bucket, objectPath, token) {
    // Standard Firebase download URL format.
    const encoded = encodeURIComponent(objectPath);
    return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encoded}?alt=media&token=${token}`;
}
exports.optimizeImageOnUpload = (0, storage_1.onObjectFinalized)({
    region: 'asia-northeast3',
    // Image processing can be memory heavy.
    memory: '1GiB',
    timeoutSeconds: 300,
}, async (event) => {
    const obj = event.data;
    const bucketName = obj.bucket;
    const objectPath = obj.name;
    const contentType = obj.contentType;
    if (!bucketName || !objectPath)
        return;
    if (!contentType || !contentType.toLowerCase().startsWith('image/'))
        return;
    // Avoid infinite loops for derived outputs.
    if (objectPath.includes('/thumbnails/') || objectPath.includes('/webp/'))
        return;
    const derived = parseDerivedPaths(objectPath);
    if (!derived)
        return;
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
    const src = (0, sharp_1.default)(tmpOriginal).rotate();
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
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                });
            }
            await batch.commit();
        }
    }
    catch (e) {
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
    await snap.docs[0].ref.set({
        thumbnail_url: thumbnailUrl,
        webp_url: webpUrl,
        updated_at: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
});
