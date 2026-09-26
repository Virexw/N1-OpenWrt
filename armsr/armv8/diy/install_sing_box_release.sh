#!/usr/bin/env bash
set -euo pipefail

ROOTFS_ARCHIVE="${1:?Usage: install_sing_box_release.sh <rootfs.tar.gz> <release-package.apk> <host-apk>}"
PACKAGE_PATH="${2:?Usage: install_sing_box_release.sh <rootfs.tar.gz> <release-package.apk> <host-apk>}"
PACKAGE_MANAGER="${3:?Usage: install_sing_box_release.sh <rootfs.tar.gz> <release-package.apk> <host-apk>}"

if [[ ! -f "$ROOTFS_ARCHIVE" || ! -f "$PACKAGE_PATH" || ! -x "$PACKAGE_MANAGER" ]]; then
  echo "Error: rootfs archive, release package, or host package manager is missing" >&2
  exit 1
fi

WORK_DIR=$(mktemp -d)
ROOTFS_DIR="$WORK_DIR/rootfs"
UPDATED_ARCHIVE="$ROOTFS_ARCHIVE.updated"
mkdir -p "$ROOTFS_DIR"
trap 'sudo rm -rf "$WORK_DIR"; rm -f "$UPDATED_ARCHIVE"' EXIT

sudo tar --extract --gzip --file "$ROOTFS_ARCHIVE" --directory "$ROOTFS_DIR" \
  --numeric-owner --same-owner --xattrs --xattrs-include='*' --acls --selinux

APK_REPO="$WORK_DIR/repository"
mkdir -p "$APK_REPO"
cp "$PACKAGE_PATH" "$APK_REPO/"
sudo "$PACKAGE_MANAGER" mkndx --allow-untrusted --output "$APK_REPO/packages.adb" "$APK_REPO"/*.apk
sudo "$PACKAGE_MANAGER" --root "$ROOTFS_DIR" --arch aarch64_generic \
  --repositories-file /dev/null --repository "$APK_REPO/packages.adb" \
  --allow-untrusted --no-scripts --no-cache add --upgrade sing-box

sudo tar --create --gzip --file "$UPDATED_ARCHIVE" --directory "$ROOTFS_DIR" \
  --numeric-owner --xattrs --xattrs-include='*' --acls --selinux .
sudo chown "$(id -u):$(id -g)" "$UPDATED_ARCHIVE"
mv "$UPDATED_ARCHIVE" "$ROOTFS_ARCHIVE"

echo "Installed the official sing-box APK release into $ROOTFS_ARCHIVE"
