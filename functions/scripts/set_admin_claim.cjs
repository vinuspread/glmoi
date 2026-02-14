/*
  Usage:

    # 1) Download a service account key JSON from the *target* Firebase project
    #    (dev/stg/prod) and store it locally (DO NOT COMMIT).
    #
    # 2) Run:
    #   SERVICE_ACCOUNT_KEY_PATH="/absolute/path/to/serviceAccountKey.json" \
    #     node scripts/set_admin_claim.cjs vinus@vinus.co.kr
    #
    # Optional: remove admin claim
    #   SERVICE_ACCOUNT_KEY_PATH="..." node scripts/set_admin_claim.cjs vinus@vinus.co.kr --remove
*/

const fs = require('node:fs');
const path = require('node:path');

const admin = require('firebase-admin');

function readServiceAccountJson() {
  const keyPath =
    process.env.SERVICE_ACCOUNT_KEY_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!keyPath) {
    throw new Error(
      'Missing SERVICE_ACCOUNT_KEY_PATH (or GOOGLE_APPLICATION_CREDENTIALS).',
    );
  }

  const abs = path.isAbsolute(keyPath)
    ? keyPath
    : path.resolve(process.cwd(), keyPath);
  const raw = fs.readFileSync(abs, 'utf8');
  return JSON.parse(raw);
}

async function main() {
  const email = process.argv[2];
  const remove = process.argv.includes('--remove');

  if (!email || email.startsWith('-')) {
    throw new Error(
      'Usage: node scripts/set_admin_claim.cjs <email> [--remove]',
    );
  }

  const serviceAccount = readServiceAccountJson();

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  const user = await admin.auth().getUserByEmail(email);
  const claims = remove ? {} : { admin: true };
  await admin.auth().setCustomUserClaims(user.uid, claims);

  // Print the final state for confirmation.
  const updated = await admin.auth().getUser(user.uid);
  const customClaims = updated.customClaims || {};
  console.log(
    JSON.stringify(
      {
        ok: true,
        email: updated.email,
        uid: updated.uid,
        customClaims,
        note:
          'Client must sign out/in (or refresh token) to receive updated claims.',
      },
      null,
      2,
    ),
  );
}

main().catch((err) => {
  console.error(err?.stack || String(err));
  process.exit(1);
});
