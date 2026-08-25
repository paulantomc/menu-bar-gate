#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
CONFIGURATION="${1:-release}"
OUTPUT_DIR="$ROOT_DIR/outputs"
APP_DIR="$OUTPUT_DIR/MenuBarGate.app"
BUILD_DIR="$ROOT_DIR/work/build"
MODULE_CACHE="$ROOT_DIR/work/clang-cache"
SDK="${MENUBARGATE_SDK:-$(xcrun --sdk macosx --show-sdk-path)}"
# This machine's newest SDK is one patch ahead of its Swift standard library.
[[ -d /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ]] && \
  SDK="${MENUBARGATE_SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"

cd "$ROOT_DIR"
mkdir -p "$BUILD_DIR" "$MODULE_CACHE"
OPTIMIZATION="-O"
[[ "$CONFIGURATION" == "debug" ]] && OPTIMIZATION="-Onone"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swiftc \
  -sdk "$SDK" -module-cache-path "$MODULE_CACHE" -parse-as-library "$OPTIMIZATION" \
  Sources/MenuBarGate/*.swift -o "$BUILD_DIR/MenuBarGate" \
  -framework AppKit -framework ApplicationServices -framework CoreGraphics \
  -framework ServiceManagement

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/MenuBarGate" "$APP_DIR/Contents/MacOS/MenuBarGate"
/usr/libexec/PlistBuddy -c 'Clear dict' "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string MenuBarGate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.local.MenuBarGate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string Menu Bar Gate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Menu Bar Gate' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 1.0.0' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 1' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 13.0' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$APP_DIR/Contents/Info.plist"
codesign --force --sign - "$APP_DIR"
echo "$APP_DIR"
