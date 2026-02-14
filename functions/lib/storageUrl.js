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
exports.parseFirebaseStorageDownloadUrl = parseFirebaseStorageDownloadUrl;
exports.deriveWebpObjectPath = deriveWebpObjectPath;
exports.deriveThumbObjectPath = deriveThumbObjectPath;
exports.buildDownloadUrl = buildDownloadUrl;
const path = __importStar(require("node:path"));
function parseFirebaseStorageDownloadUrl(url) {
    try {
        const u = new URL(url);
        if (u.hostname !== 'firebasestorage.googleapis.com')
            return null;
        const parts = u.pathname.split('/').filter(Boolean);
        if (parts.length < 4)
            return null;
        if (parts[0] !== 'v0')
            return null;
        if (parts[1] !== 'b')
            return null;
        const bucket = parts[2];
        if (parts[3] !== 'o')
            return null;
        const rawObject = parts.slice(4).join('/');
        const objectPath = decodeURIComponent(rawObject);
        if (!bucket || !objectPath)
            return null;
        return { bucket, objectPath };
    }
    catch (_) {
        return null;
    }
}
function deriveWebpObjectPath(originalObjectPath) {
    const parts = originalObjectPath.split('/');
    if (parts.length < 4)
        return null;
    if (parts[0] !== 'assets')
        return null;
    const appId = parts[1];
    if (!appId)
        return null;
    if (parts[2] !== 'images')
        return null;
    const fileName = parts[parts.length - 1] ?? '';
    const ext = path.extname(fileName).toLowerCase();
    const baseName = ext ? fileName.slice(0, -ext.length) : fileName;
    if (!baseName)
        return null;
    return `assets/${appId}/webp/${baseName}.webp`;
}
function deriveThumbObjectPath(originalObjectPath) {
    const parts = originalObjectPath.split('/');
    if (parts.length < 4)
        return null;
    if (parts[0] !== 'assets')
        return null;
    const appId = parts[1];
    if (!appId)
        return null;
    if (parts[2] !== 'images')
        return null;
    const fileName = parts[parts.length - 1] ?? '';
    const ext = path.extname(fileName).toLowerCase();
    const baseName = ext ? fileName.slice(0, -ext.length) : fileName;
    if (!baseName)
        return null;
    return `assets/${appId}/thumbnails/${baseName}_thumb.jpg`;
}
function buildDownloadUrl(bucket, objectPath, token) {
    const encoded = encodeURIComponent(objectPath);
    return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encoded}?alt=media&token=${token}`;
}
