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
exports.fillImageAssetDerivedUrls = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const storageUrl_1 = require("./storageUrl");
function getDownloadToken(metadata) {
    const tokens = metadata?.metadata?.firebaseStorageDownloadTokens ||
        metadata?.firebaseStorageDownloadTokens;
    if (!tokens || typeof tokens !== 'string')
        return null;
    const first = tokens.split(',')[0]?.trim();
    return first || null;
}
async function tryGetDownloadUrl(bucket, objectPath) {
    try {
        const file = bucket.file(objectPath);
        const [meta] = await file.getMetadata();
        const token = getDownloadToken(meta);
        if (!token)
            return null;
        return (0, storageUrl_1.buildDownloadUrl)(bucket.name, objectPath, token);
    }
    catch (_) {
        return null;
    }
}
exports.fillImageAssetDerivedUrls = (0, firestore_2.onDocumentCreated)({
    document: 'image_assets/{id}',
    region: 'asia-northeast3',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const originalUrl = data['original_url'] ?? '';
    if (!originalUrl)
        return;
    const parsed = (0, storageUrl_1.parseFirebaseStorageDownloadUrl)(originalUrl);
    if (!parsed)
        return;
    const webpObjectPath = (0, storageUrl_1.deriveWebpObjectPath)(parsed.objectPath);
    const thumbObjectPath = (0, storageUrl_1.deriveThumbObjectPath)(parsed.objectPath);
    if (!webpObjectPath && !thumbObjectPath)
        return;
    const bucket = admin.storage().bucket(parsed.bucket);
    const [thumbUrl, webpUrl] = await Promise.all([
        thumbObjectPath ? tryGetDownloadUrl(bucket, thumbObjectPath) : null,
        webpObjectPath ? tryGetDownloadUrl(bucket, webpObjectPath) : null,
    ]);
    const update = {
        updated_at: firestore_1.FieldValue.serverTimestamp(),
    };
    if (thumbUrl)
        update['thumbnail_url'] = thumbUrl;
    if (webpUrl)
        update['webp_url'] = webpUrl;
    if (Object.keys(update).length <= 1)
        return;
    await snap.ref.set(update, { merge: true });
});
