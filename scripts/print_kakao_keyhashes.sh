#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [[ ! -f "$KEY_PROPERTIES" ]]; then
  echo "[ERROR] Missing $KEY_PROPERTIES"
  exit 1
fi

if [[ ! -f "$DEBUG_KEYSTORE" ]]; then
  echo "[WARN] Debug keystore not found: $DEBUG_KEYSTORE"
fi

get_prop() {
  local key="$1"
  local value
  value="$(grep -E "^${key}=" "$KEY_PROPERTIES" | sed -E "s/^${key}=//")"
  printf '%s' "$value"
}

STORE_FILE_REL="$(get_prop storeFile)"
STORE_FILE_FROM_APP="$ANDROID_DIR/app/$STORE_FILE_REL"
STORE_FILE_FROM_ANDROID="$ANDROID_DIR/$STORE_FILE_REL"
KEY_ALIAS="$(get_prop keyAlias)"
STORE_PASSWORD="$(get_prop storePassword)"
KEY_PASSWORD="$(get_prop keyPassword)"

if [[ -f "$STORE_FILE_FROM_APP" ]]; then
  STORE_FILE="$STORE_FILE_FROM_APP"
elif [[ -f "$STORE_FILE_FROM_ANDROID" ]]; then
  STORE_FILE="$STORE_FILE_FROM_ANDROID"
else
  echo "[ERROR] Release keystore not found. Checked:"
  echo "  - $STORE_FILE_FROM_APP"
  echo "  - $STORE_FILE_FROM_ANDROID"
  exit 1
fi

echo "=== Kakao Android Key Hash Preflight ==="
echo "project: $ROOT_DIR"
echo

if [[ -f "$DEBUG_KEYSTORE" ]]; then
  DEBUG_HASH="$(keytool -exportcert -alias androiddebugkey -keystore "$DEBUG_KEYSTORE" -storepass android -keypass android 2>/dev/null | openssl sha1 -binary | openssl base64)"
  echo "[DEBUG]   $DEBUG_HASH"
else
  echo "[DEBUG]   (missing debug keystore on this machine)"
fi

RELEASE_HASH="$(keytool -exportcert -alias "$KEY_ALIAS" -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" -keypass "$KEY_PASSWORD" 2>/dev/null | openssl sha1 -binary | openssl base64)"
echo "[RELEASE] $RELEASE_HASH"

echo
echo "Register these hashes in Kakao Developers > My App > Platform > Android."
echo "Also register Google Play App Signing key hash for store builds:"
echo "1) Google Play Console > App integrity > App signing key certificate (SHA-1 hex)"
echo "2) Convert hex -> base64:"
echo "   echo \"FA:C6:...\" | tr -d ':' | xxd -r -p | openssl base64 -A"
echo
echo "If runtime still fails, reproduce share and read in-app mismatch guidance."
