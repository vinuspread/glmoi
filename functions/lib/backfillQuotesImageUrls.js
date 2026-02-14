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
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const storageUrl_1 = require("./storageUrl");
function parseArgs(argv) {
    const out = {
        projectId: '',
        appId: 'maumsori',
        apply: false,
        maxUpdates: 5000,
    };
    const takeValue = (i) => {
        const v = argv[i];
        if (!v)
            return null;
        if (v.startsWith('--'))
            return null;
        return v;
    };
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === '--apply') {
            out.apply = true;
            continue;
        }
        if (a.startsWith('--projectId=')) {
            out.projectId = a.split('=')[1] ?? '';
            continue;
        }
        if (a === '--projectId') {
            out.projectId = takeValue(i + 1) ?? '';
            continue;
        }
        if (a.startsWith('--appId=')) {
            out.appId = a.split('=')[1] ?? 'maumsori';
            continue;
        }
        if (a === '--appId') {
            out.appId = takeValue(i + 1) ?? 'maumsori';
            continue;
        }
        if (a.startsWith('--maxUpdates=')) {
            const raw = a.split('=')[1] ?? '';
            const n = Number.parseInt(raw, 10);
            if (Number.isFinite(n) && n > 0)
                out.maxUpdates = n;
            continue;
        }
        if (a === '--maxUpdates') {
            const raw = takeValue(i + 1) ?? '';
            const n = Number.parseInt(raw, 10);
            if (Number.isFinite(n) && n > 0)
                out.maxUpdates = n;
            continue;
        }
    }
    if (!out.projectId.trim()) {
        throw new Error('Missing required --projectId');
    }
    if (!out.appId.trim()) {
        throw new Error('Missing required --appId');
    }
    return out;
}
function getDownloadToken(metadata) {
    const tokens = metadata?.metadata?.firebaseStorageDownloadTokens ||
        metadata?.firebaseStorageDownloadTokens;
    if (!tokens || typeof tokens !== 'string')
        return null;
    const first = tokens.split(',')[0]?.trim();
    return first || null;
}
async function tryResolveWebpUrl(originalUrl) {
    const parsed = (0, storageUrl_1.parseFirebaseStorageDownloadUrl)(originalUrl);
    if (!parsed)
        return null;
    const webpObjectPath = (0, storageUrl_1.deriveWebpObjectPath)(parsed.objectPath);
    if (!webpObjectPath)
        return null;
    try {
        const bucket = admin.storage().bucket(parsed.bucket);
        const file = bucket.file(webpObjectPath);
        const [meta] = await file.getMetadata();
        const token = getDownloadToken(meta);
        if (!token)
            return null;
        return (0, storageUrl_1.buildDownloadUrl)(parsed.bucket, webpObjectPath, token);
    }
    catch (_) {
        return null;
    }
}
async function backfillQuotes(db, args) {
    let scanned = 0;
    let candidates = 0;
    let updated = 0;
    let last = null;
    while (updated < args.maxUpdates) {
        let q = db
            .collection('quotes')
            .where('app_id', '==', args.appId)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(500);
        if (last)
            q = q.startAfter(last);
        const snap = await q.get();
        if (snap.empty)
            break;
        scanned += snap.size;
        let batch = args.apply ? db.batch() : null;
        let batchOps = 0;
        for (const doc of snap.docs) {
            const data = doc.data();
            const imageUrl = data['image_url'] ?? '';
            if (!imageUrl)
                continue;
            const webpUrl = await tryResolveWebpUrl(imageUrl);
            if (!webpUrl)
                continue;
            if (webpUrl === imageUrl)
                continue;
            candidates += 1;
            if (args.apply) {
                batch.update(doc.ref, {
                    image_url: webpUrl,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                });
                batchOps += 1;
            }
            if (args.apply && batchOps >= 450) {
                await batch.commit();
                updated += batchOps;
                batch = db.batch();
                batchOps = 0;
                if (updated >= args.maxUpdates)
                    break;
            }
        }
        if (args.apply && batchOps > 0) {
            await batch.commit();
            updated += batchOps;
        }
        last = snap.docs[snap.docs.length - 1];
        if (scanned % 5000 === 0) {
            console.log(JSON.stringify({
                scanned,
                candidates,
                updated: args.apply ? updated : 0,
                maxUpdates: args.maxUpdates,
            }, null, 2));
        }
    }
    return {
        scanned,
        candidates,
        updated: args.apply ? updated : 0,
        maxUpdates: args.maxUpdates,
    };
}
async function main() {
    const args = parseArgs(process.argv.slice(2));
    console.log(JSON.stringify({
        projectId: args.projectId,
        appId: args.appId,
        apply: args.apply,
        maxUpdates: args.maxUpdates,
    }, null, 2));
    admin.initializeApp({ projectId: args.projectId });
    const db = admin.firestore();
    const res = await backfillQuotes(db, args);
    console.log(JSON.stringify(res, null, 2));
    if (!args.apply) {
        console.log('Dry-run complete. Re-run with --apply to write updates.');
    }
}
main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
