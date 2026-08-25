#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_PATH="$ROOT_DIR/outputs/MenuBarGate.app"
DMG_PATH="$ROOT_DIR/outputs/MenuBarGate.dmg"
STAGING_DIR="$ROOT_DIR/work/dmg-staging"

"$ROOT_DIR/scripts/build-app.sh" release

mkdir -p "$STAGING_DIR"
rm -rf "$STAGING_DIR/MenuBarGate.app" "$STAGING_DIR/Applications"
ditto "$APP_PATH" "$STAGING_DIR/MenuBarGate.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "MenuBarGate" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$DMG_PATH"
