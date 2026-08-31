#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
source "$ROOT_DIR/scripts/build-settings.sh"
APP_DIR="${1:-$ROOT_DIR/outputs/MenuBarGate.app}"
PLIST="$APP_DIR/Contents/Info.plist"
EXECUTABLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST")
BINARY="$APP_DIR/Contents/MacOS/$EXECUTABLE"
PLIST_MIN=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$PLIST")
BINARY_ARCH=$(xcrun lipo -archs "$BINARY")
BINARY_MIN=$(xcrun vtool -show-build "$BINARY" | awk '$1 == "minos" { print $2 }')

# Info.plist alone is not enough: the executable records its own minimum OS.
if [[ "$BINARY_ARCH" != "$MENUBARGATE_ARCH" ||
      "$PLIST_MIN" != "$MENUBARGATE_MIN_MACOS" ||
      "$BINARY_MIN" != "$MENUBARGATE_MIN_MACOS" ]]; then
  print -u2 "Compatibility check failed for $APP_DIR"
  print -u2 "Expected $MENUBARGATE_ARCH, macOS $MENUBARGATE_MIN_MACOS."
  print -u2 "Found $BINARY_ARCH, executable macOS $BINARY_MIN, Info.plist macOS $PLIST_MIN."
  exit 1
fi

codesign --verify --deep --strict "$APP_DIR"
print "Verified: $MENUBARGATE_ARCH, macOS $MENUBARGATE_MIN_MACOS minimum, valid signature."
