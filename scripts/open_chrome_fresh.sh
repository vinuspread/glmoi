#!/usr/bin/env bash
set -euo pipefail

# Open a URL in a fresh Chrome profile.
# Used to avoid "wrong Google account" issues during `gcloud auth login`.

URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "Usage: $0 <url>" >&2
  exit 2
fi

PROFILE_DIR="$(mktemp -d -t chrome-gcloud-auth.XXXXXX)"

open -na "Google Chrome" --args \
  --user-data-dir="$PROFILE_DIR" \
  --no-first-run \
  --no-default-browser-check \
  "$URL"
