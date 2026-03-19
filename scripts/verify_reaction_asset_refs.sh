#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[verify_reaction_asset_refs] scanning dart files..."

refs=()
while IFS= read -r line; do
  refs+=("$line")
done < <(
  grep -RhoE "assets/icons/reactions/[A-Za-z0-9._/-]+" lib test 2>/dev/null \
    | sort -u
)

if [[ ${#refs[@]} -eq 0 ]]; then
  echo "[verify_reaction_asset_refs] no reaction asset references found"
  exit 0
fi

missing=0
for ref in "${refs[@]}"; do
  if [[ ! -f "$ref" ]]; then
    echo "[verify_reaction_asset_refs] MISSING: $ref"
    missing=1
  fi
done

if [[ $missing -ne 0 ]]; then
  echo "[verify_reaction_asset_refs] failed: missing referenced files"
  exit 1
fi

echo "[verify_reaction_asset_refs] OK (${#refs[@]} refs)"
