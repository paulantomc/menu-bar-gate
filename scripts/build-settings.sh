# Shared by the app build, self-tests, and compatibility check.
# The SDK version is not the deployment target: always set the latter explicitly.
MENUBARGATE_ARCH="arm64"
MENUBARGATE_MIN_MACOS="13.0"
MENUBARGATE_TARGET="${MENUBARGATE_ARCH}-apple-macosx${MENUBARGATE_MIN_MACOS}"
