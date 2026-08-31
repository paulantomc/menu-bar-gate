#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
source "$ROOT_DIR/scripts/build-settings.sh"
CONFIGURATION="${1:-release}"
OUTPUT_DIR="$ROOT_DIR/outputs"
APP_DIR="$OUTPUT_DIR/MenuBarGate.app"
BUILD_DIR="$ROOT_DIR/work/build"
MODULE_CACHE="$ROOT_DIR/work/clang-cache"
ICON_FILE="$ROOT_DIR/Assets/MenuBarGate.icns"
SDK="${MENUBARGATE_SDK:-$(xcrun --sdk macosx --show-sdk-path)}"

cd "$ROOT_DIR"
mkdir -p "$BUILD_DIR" "$MODULE_CACHE"
OPTIMIZATION="-O"
[[ "$CONFIGURATION" == "debug" ]] && OPTIMIZATION="-Onone"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swiftc \
  -target "$MENUBARGATE_TARGET" -sdk "$SDK" \
  -module-cache-path "$MODULE_CACHE" -parse-as-library "$OPTIMIZATION" \
  Sources/MenuBarGate/*.swift -o "$BUILD_DIR/MenuBarGate" \
  -framework AppKit -framework ApplicationServices -framework CoreGraphics \
  -framework ServiceManagement

if [[ ! -f "$ICON_FILE" ]]; then
  echo "Missing app icon: $ICON_FILE" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/MenuBarGate" "$APP_DIR/Contents/MacOS/MenuBarGate"
cp "$ICON_FILE" "$APP_DIR/Contents/Resources/MenuBarGate.icns"
/usr/libexec/PlistBuddy -c 'Clear dict' "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string MenuBarGate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.local.MenuBarGate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string Menu Bar Gate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Menu Bar Gate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 1.1.1' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 4' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string MenuBarGate.icns' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MENUBARGATE_MIN_MACOS" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$APP_DIR/Contents/Info.plist"
codesign --force --sign - \
  --requirements '=designated => identifier "com.local.MenuBarGate"' \
  "$APP_DIR"
"$ROOT_DIR/scripts/verify-app.sh" "$APP_DIR"
echo "$APP_DIR"
