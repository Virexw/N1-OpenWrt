#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="${1:?Usage: download_release_asset.sh <owner/repo> <asset-prefix> <asset-suffix> <output-dir>}"
ASSET_PREFIX="${2:?Usage: download_release_asset.sh <owner/repo> <asset-prefix> <asset-suffix> <output-dir>}"
ASSET_SUFFIX="${3:?Usage: download_release_asset.sh <owner/repo> <asset-prefix> <asset-suffix> <output-dir>}"
OUTPUT_DIR="${4:?Usage: download_release_asset.sh <owner/repo> <asset-prefix> <asset-suffix> <output-dir>}"

API_HEADERS=(-H 'Accept: application/vnd.github+json')
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  API_HEADERS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

RELEASE_JSON=$(curl -fsSL "${API_HEADERS[@]}" "https://api.github.com/repos/$REPOSITORY/releases/latest")
RELEASE_TAG=$(jq -er '.tag_name' <<< "$RELEASE_JSON")
ASSET_COUNT=$(jq -er --arg prefix "$ASSET_PREFIX" --arg suffix "$ASSET_SUFFIX" \
  '[.assets[] | select((.name | startswith($prefix)) and (.name | endswith($suffix)))] | length' \
  <<< "$RELEASE_JSON")

if [[ "$ASSET_COUNT" != 1 ]]; then
  echo "Error: expected one matching release asset for $REPOSITORY ($RELEASE_TAG), found $ASSET_COUNT" >&2
  exit 1
fi

ASSET_JSON=$(jq -ce --arg prefix "$ASSET_PREFIX" --arg suffix "$ASSET_SUFFIX" \
  '[.assets[] | select((.name | startswith($prefix)) and (.name | endswith($suffix)))] | .[0]' \
  <<< "$RELEASE_JSON")
ASSET_NAME=$(jq -er '.name' <<< "$ASSET_JSON")
ASSET_URL=$(jq -er '.browser_download_url' <<< "$ASSET_JSON")
ASSET_DIGEST=$(jq -r '.digest // empty' <<< "$ASSET_JSON")

mkdir -p "$OUTPUT_DIR"
PACKAGE_PATH="$OUTPUT_DIR/$ASSET_NAME"
echo "Downloading $REPOSITORY $RELEASE_TAG: $ASSET_NAME" >&2
curl -fsSL "$ASSET_URL" -o "$PACKAGE_PATH"

if [[ "$ASSET_DIGEST" == sha256:* ]]; then
  EXPECTED_SHA256="${ASSET_DIGEST#sha256:}"
  if ! printf '%s  %s\n' "$EXPECTED_SHA256" "$PACKAGE_PATH" | sha256sum --check --status; then
    echo "Error: checksum verification failed for $ASSET_NAME" >&2
    exit 1
  fi
  echo "Verified release asset checksum." >&2
elif [[ -n "$ASSET_DIGEST" ]]; then
  echo "Error: unsupported checksum format for $ASSET_NAME: $ASSET_DIGEST" >&2
  exit 1
else
  echo "Error: release asset $ASSET_NAME has no SHA-256 digest" >&2
  exit 1
fi

printf '%s\n' "$PACKAGE_PATH"
