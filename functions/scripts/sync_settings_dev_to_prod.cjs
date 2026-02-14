/*
  Copies admin settings docs from DEV -> PROD (Firestore only).
  Excludes content/images collections.

  This script overwrites the target documents in PROD.

  Usage:

    DEV_SERVICE_ACCOUNT_KEY_PATH="/abs/path/dev-serviceAccountKey.json" \
    PROD_SERVICE_ACCOUNT_KEY_PATH="/abs/path/prod-serviceAccountKey.json" \
      node scripts/sync_settings_dev_to_prod.cjs

  Optional:
    --dry-run   Prints what would be copied; no writes.
    --backup    Saves current PROD docs into ./scripts/_backup_prod_settings_<timestamp>.json
*/

const fs = require('node:fs');
const path = require('node:path');

const admin = require('firebase-admin');

function readJsonFromEnv(envName) {
  const p = process.env[envName];
  if (!p) {
    throw new Error(`Missing ${envName} (absolute path to serviceAccountKey.json).`);
  }
  const abs = path.isAbsolute(p) ? p : path.resolve(process.cwd(), p);
  return JSON.parse(fs.readFileSync(abs, 'utf8'));
}

function initApp(name, serviceAccount) {
  const existing = admin.apps.find((a) => a.name === name);
  if (existing) return existing;
  return admin.initializeApp(
    {
      credential: admin.credential.cert(serviceAccount),
    },
    name,
  );
}

async function getDocData(db, collection, doc) {
  const snap = await db.collection(collection).doc(doc).get();
  return snap.exists ? snap.data() : null;
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const backup = process.argv.includes('--backup');

  const devSa = readJsonFromEnv('DEV_SERVICE_ACCOUNT_KEY_PATH');
  const prodSa = readJsonFromEnv('PROD_SERVICE_ACCOUNT_KEY_PATH');

  const devApp = initApp('dev-admin', devSa);
  const prodApp = initApp('prod-admin', prodSa);

  const devDb = admin.firestore(devApp);
  const prodDb = admin.firestore(prodApp);

  const targets = [
    { collection: 'config', doc: 'app_config' },
    { collection: 'config', doc: 'ad_config' },
    { collection: 'config', doc: 'terms_config' },
    { collection: 'admin_settings', doc: 'bad_words' },
  ];

  if (backup) {
    const snapshot = {};
    for (const t of targets) {
      const key = `${t.collection}/${t.doc}`;
      snapshot[key] = await getDocData(prodDb, t.collection, t.doc);
    }
    const ts = new Date().toISOString().replace(/[:.]/g, '-');
    const outPath = path.resolve(
      process.cwd(),
      `scripts/_backup_prod_settings_${ts}.json`,
    );
    fs.writeFileSync(outPath, JSON.stringify(snapshot, null, 2), 'utf8');
    console.log(`Backup written: ${outPath}`);
  }

  const results = [];
  for (const t of targets) {
    const key = `${t.collection}/${t.doc}`;
    const data = await getDocData(devDb, t.collection, t.doc);
    if (!data) {
      results.push({ doc: key, action: 'skip', reason: 'missing-in-dev' });
      continue;
    }

    if (dryRun) {
      results.push({ doc: key, action: 'would-copy' });
      continue;
    }

    await prodDb.collection(t.collection).doc(t.doc).set(data);
    results.push({ doc: key, action: 'copied' });
  }

  console.log(JSON.stringify({ ok: true, dryRun, results }, null, 2));
  process.exit(0);
}

main().catch((err) => {
  console.error(err?.stack || String(err));
  process.exit(1);
});
