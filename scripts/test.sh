#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
source "$ROOT_DIR/scripts/build-settings.sh"
BUILD_DIR="$ROOT_DIR/work/test-build"
MODULE_CACHE="$ROOT_DIR/work/clang-cache"
SDK="${MENUBARGATE_SDK:-$(xcrun --sdk macosx --show-sdk-path)}"

mkdir -p "$BUILD_DIR" "$MODULE_CACHE"
cd "$ROOT_DIR"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swiftc \
  -target "$MENUBARGATE_TARGET" -sdk "$SDK" -module-cache-path "$MODULE_CACHE" \
  Sources/MenuBarGate/GateBinding.swift Sources/MenuBarGate/ReleaseMode.swift \
  Sources/MenuBarGate/FullscreenDetector.swift Tests/SelfTest/main.swift \
  -o "$BUILD_DIR/MenuBarGateSelfTest" -framework AppKit -framework ApplicationServices -framework CoreGraphics
"$BUILD_DIR/MenuBarGateSelfTest"
