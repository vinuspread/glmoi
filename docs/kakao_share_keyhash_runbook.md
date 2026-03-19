# Kakao Share KeyHash Runbook

This runbook prevents recurrence of `code: -401` / `android keyhash mismatched` in production.

## Why this happens

- Kakao validates Android key hash from request header against hashes registered in Kakao Developers Console.
- Store-distributed app can be signed by Google Play App Signing key, which may differ from local release keystore.
- Registering only local release hash is insufficient when Play App Signing is enabled.

## Required hash sources

Register all hashes below in Kakao Developers Console > My App > Platform > Android:

1. Local debug hash (developer testing)
2. Local release hash (manual local release validation)
3. Google Play App Signing hash (actual store distribution)

## Pre-release checklist (mandatory)

1. Compute local hashes:
   - Run `./scripts/print_kakao_keyhashes.sh`
2. Obtain Google Play App Signing SHA-1 (hex):
   - Google Play Console > App Integrity > App signing key certificate
3. Convert Play SHA-1 hex to Base64:
   - `echo "FA:C6:..." | tr -d ':' | xxd -r -p | openssl base64 -A`
4. Open Kakao Developers Console and ensure all hashes are registered.
5. Build and test share on `prod` flavor:
   - `flutter build apk --debug --flavor prod`
   - Verify Kakao share success on device.
6. Mandatory Play-signed verification before rollout:
   - Upload to Play internal track and install from Play.
   - Verify Kakao share on the Play-distributed app.

## Release-day checklist (mandatory)

1. Re-run `./scripts/print_kakao_keyhashes.sh` to confirm no local key changes.
2. Re-check Play App Signing certificate (especially after key rotation or account changes).
3. Validate Kakao Android platform settings one more time before rollout.

## Post-release verification

1. Install app from Play internal track.
2. Open quote detail > tap share > tap KakaoTalk.
3. Confirm one of these outcomes:
   - Kakao share succeeds, or
   - App shows keyhash guidance and auto-fallback to other share (no dead-end failure).

## Incident response

If `-401` appears again:

1. Capture shown key hash from in-app guidance.
   - Save screenshot of snackbar message for incident traceability.
2. Compare with Kakao Developers Android key hash list.
3. Add missing hash immediately.
4. Retry share without requiring app update.

## Ownership

- Release owner must execute this runbook for every Android rollout.
- QA owner must verify share behavior on Play-distributed build.
