import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

import {
  buildDownloadUrl,
  deriveWebpObjectPath,
  parseFirebaseStorageDownloadUrl,
} from './storageUrl';

type Args = {
  projectId: string;
  appId: string;
  apply: boolean;
  maxUpdates: number;
};

function parseArgs(argv: string[]): Args {
  const out: Args = {
    projectId: '',
    appId: 'maumsori',
    apply: false,
    maxUpdates: 5000,
  };

  const takeValue = (i: number): string | null => {
    const v = argv[i];
    if (!v) return null;
    if (v.startsWith('--')) return null;
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
      if (Number.isFinite(n) && n > 0) out.maxUpdates = n;
      continue;
    }
    if (a === '--maxUpdates') {
      const raw = takeValue(i + 1) ?? '';
      const n = Number.parseInt(raw, 10);
      if (Number.isFinite(n) && n > 0) out.maxUpdates = n;
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

function getDownloadToken(metadata: any): string | null {
  const tokens =
    (metadata?.metadata?.firebaseStorageDownloadTokens as string | undefined) ||
    (metadata?.firebaseStorageDownloadTokens as string | undefined);

  if (!tokens || typeof tokens !== 'string') return null;
  const first = tokens.split(',')[0]?.trim();
  return first || null;
}

async function tryResolveWebpUrl(originalUrl: string): Promise<string | null> {
  const parsed = parseFirebaseStorageDownloadUrl(originalUrl);
  if (!parsed) return null;
  const webpObjectPath = deriveWebpObjectPath(parsed.objectPath);
  if (!webpObjectPath) return null;

  try {
    const bucket = admin.storage().bucket(parsed.bucket);
    const file = bucket.file(webpObjectPath);
    const [meta] = await file.getMetadata();
    const token = getDownloadToken(meta);
    if (!token) return null;
    return buildDownloadUrl(parsed.bucket, webpObjectPath, token);
  } catch (_) {
    return null;
  }
}

async function backfillQuotes(
  db: admin.firestore.Firestore,
  args: Args,
) {
  let scanned = 0;
  let candidates = 0;
  let updated = 0;
  let last: admin.firestore.QueryDocumentSnapshot | null = null;

  while (updated < args.maxUpdates) {
    let q = db
      .collection('quotes')
      .where('app_id', '==', args.appId)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;

    scanned += snap.size;

    let batch: admin.firestore.WriteBatch | null = args.apply ? db.batch() : null;
    let batchOps = 0;

    for (const doc of snap.docs) {
      const data = doc.data() as Record<string, unknown>;
      const imageUrl = (data['image_url'] as string | undefined) ?? '';
      if (!imageUrl) continue;

      const webpUrl = await tryResolveWebpUrl(imageUrl);
      if (!webpUrl) continue;
      if (webpUrl === imageUrl) continue;

      candidates += 1;
      if (args.apply) {
        batch!.update(doc.ref, {
          image_url: webpUrl,
          updatedAt: FieldValue.serverTimestamp(),
        });
        batchOps += 1;
      }

      if (args.apply && batchOps >= 450) {
        await batch!.commit();
        updated += batchOps;
        batch = db.batch();
        batchOps = 0;

        if (updated >= args.maxUpdates) break;
      }
    }

    if (args.apply && batchOps > 0) {
      await batch!.commit();
      updated += batchOps;
    }

    last = snap.docs[snap.docs.length - 1];

    if (scanned % 5000 === 0) {
      console.log(
        JSON.stringify(
          {
            scanned,
            candidates,
            updated: args.apply ? updated : 0,
            maxUpdates: args.maxUpdates,
          },
          null,
          2,
        ),
      );
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
  console.log(
    JSON.stringify(
      {
        projectId: args.projectId,
        appId: args.appId,
        apply: args.apply,
        maxUpdates: args.maxUpdates,
      },
      null,
      2,
    ),
  );

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
