#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:?Usage: download_sing_box.sh <output-dir>}"

RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/SagerNet/sing-box/releases/latest)
RELEASE_TAG=$(jq -er '.tag_name' <<< "$RELEASE_JSON")
ASSET_SUFFIX="_openwrt_aarch64_generic.apk"
ASSET_JSON=$(jq -c --arg suffix "$ASSET_SUFFIX" '[.assets[] | select(.name | endswith($suffix))][0] // empty' <<< "$RELEASE_JSON")

if [[ -z "$ASSET_JSON" || "$ASSET_JSON" == "null" ]]; then
  echo "Error: no official sing-box APK release found for aarch64_generic ($RELEASE_TAG)" >&2
  exit 1
fi

ASSET_NAME=$(jq -er '.name' <<< "$ASSET_JSON")
ASSET_URL=$(jq -er '.browser_download_url' <<< "$ASSET_JSON")
ASSET_DIGEST=$(jq -r '.digest // empty' <<< "$ASSET_JSON")
mkdir -p "$OUTPUT_DIR"
PACKAGE_PATH="$OUTPUT_DIR/$ASSET_NAME"

echo "Downloading official sing-box release $RELEASE_TAG: $ASSET_NAME"
curl -fL "$ASSET_URL" -o "$PACKAGE_PATH"

if [[ -n "$ASSET_DIGEST" ]]; then
  EXPECTED_SHA256="${ASSET_DIGEST#sha256:}"
  echo "$EXPECTED_SHA256  $PACKAGE_PATH" | sha256sum --check --status
  echo "Verified sing-box package checksum."
fi
