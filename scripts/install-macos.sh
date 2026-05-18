#!/usr/bin/env bash
set -euo pipefail

REPO="Starbreadlover/AuRA-Browser"
APP_NAME="AuRA Browser"
INSTALL_DIR="/Applications"
TMPDIR_INSTALL="$(mktemp -d)"

cleanup() {
  hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
  rm -rf "$TMPDIR_INSTALL"
}
trap cleanup EXIT

echo "==> Fetching latest AuRA Browser release..."
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DMG_URL="$(curl -fsSL "$API_URL" | grep '"browser_download_url"' | grep '\.dmg"' | head -1 | sed 's/.*"browser_download_url": "\(.*\)"/\1/')"

if [[ -z "$DMG_URL" ]]; then
  echo "Error: No .dmg found in the latest release. Check https://github.com/${REPO}/releases" >&2
  exit 1
fi

DMG_FILE="$TMPDIR_INSTALL/AuRABrowser.dmg"
echo "==> Downloading $(basename "$DMG_URL")..."
curl -fsSL --progress-bar -o "$DMG_FILE" "$DMG_URL"

echo "==> Mounting disk image..."
MOUNT_POINT="$(hdiutil attach "$DMG_FILE" -nobrowse -quiet | awk 'END{print $NF}')"

if [[ -z "$MOUNT_POINT" ]]; then
  echo "Error: Failed to mount the disk image." >&2
  exit 1
fi

APP_SRC="$MOUNT_POINT/${APP_NAME}.app"
if [[ ! -d "$APP_SRC" ]]; then
  APP_SRC="$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" | head -1)"
fi

if [[ -z "$APP_SRC" || ! -d "$APP_SRC" ]]; then
  echo "Error: Could not find .app bundle in the disk image." >&2
  exit 1
fi

DEST="$INSTALL_DIR/${APP_NAME}.app"
if [[ -d "$DEST" ]]; then
  echo "==> Removing existing installation at $DEST..."
  rm -rf "$DEST"
fi

echo "==> Installing ${APP_NAME}.app to $INSTALL_DIR ..."
cp -R "$APP_SRC" "$INSTALL_DIR/"

echo ""
echo "AuRA Browser has been installed to $INSTALL_DIR."
echo "To open it: right-click AuRA Browser in Applications and choose Open (required on first launch)."
