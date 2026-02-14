#!/usr/bin/env bash
set -euo pipefail

# Apply Google Cloud Storage CORS settings for Firebase Storage buckets.
#
# Prereqs:
# - gcloud/gsutil installed
# - authenticated with an account that has storage.buckets.update on the target buckets
#
# Usage:
#   scripts/apply_storage_cors.sh cors.json gs://bucket-1 gs://bucket-2 ...
#
# Example:
#   scripts/apply_storage_cors.sh cors.json \
#     gs://glmoi-dev.firebasestorage.app \
#     gs://glmoi-stg.firebasestorage.app \
#     gs://glmoi-prod.firebasestorage.app

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <cors.json> <gs://bucket> [gs://bucket...]" >&2
  exit 2
fi

CORS_FILE="$1"
shift

if [[ ! -f "$CORS_FILE" ]]; then
  echo "CORS file not found: $CORS_FILE" >&2
  exit 2
fi

if ! command -v gsutil >/dev/null 2>&1; then
  echo "gsutil not found. Install Google Cloud SDK first." >&2
  exit 2
fi

if command -v gcloud >/dev/null 2>&1; then
  echo "Active gcloud account(s):"
  gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true
  echo
fi

for bucket in "$@"; do
  if [[ "$bucket" != gs://* ]]; then
    echo "Bucket must start with gs://, got: $bucket" >&2
    exit 2
  fi

  echo "Setting CORS on $bucket ..."
  gsutil cors set "$CORS_FILE" "$bucket"

  echo "Verifying CORS on $bucket ..."
  gsutil cors get "$bucket"
  echo
done

echo "Done. If the admin web is still failing to preview images, hard refresh the browser." 
