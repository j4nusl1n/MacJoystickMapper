#!/usr/bin/env bash
#
# bundle.sh — Package MacJoystickMapper into a macOS .app bundle
#
# The .app bundle gives MacJoystickMapper its own Accessibility permission
# entry in System Settings, separate from Terminal.
#
# Usage:
#   ./scripts/bundle.sh                        # Build & bundle to ./MacJoystickMapper.app
#   ./scripts/bundle.sh --output ~/Apps        # Build & bundle to ~/Apps/MacJoystickMapper.app
#   ./scripts/bundle.sh --install              # Build, bundle & copy to ~/Applications
#   ./scripts/bundle.sh --no-build             # Bundle only (skip build, use existing binary)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

APP_NAME="MacJoystickMapper"
BUNDLE_ID="com.janus.MacJoystickMapper"
VERSION="1.0"
MIN_MACOS="13.0"

OUTPUT_DIR="$PROJECT_DIR"
SKIP_BUILD=false
INSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --no-build)
            SKIP_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --output DIR    Output directory for .app bundle (default: project root)"
            echo "  --install       Copy .app bundle to ~/Applications after building"
            echo "  --no-build      Skip build step, use existing release binary"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Step 1: Build release binary
BINARY="$PROJECT_DIR/.build/release/$APP_NAME"

if [[ "$SKIP_BUILD" == false ]]; then
    echo "Step 1/3: Building release binary..."
    "$SCRIPT_DIR/build.sh"
else
    echo "Step 1/3: Skipping build (--no-build)"
fi

if [[ ! -f "$BINARY" ]]; then
    echo "Error: Release binary not found at $BINARY"
    echo "Run without --no-build or run ./scripts/build.sh first."
    exit 1
fi

# Step 2: Create .app bundle
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
echo "Step 2/3: Creating app bundle at $APP_BUNDLE..."

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSBackgroundOnly</key>
    <true/>
</dict>
</plist>
PLIST

echo "  Bundle created: $APP_BUNDLE"

# Step 3: Install (optional)
if [[ "$INSTALL" == true ]]; then
    INSTALL_DIR="$HOME/Applications"
    echo "Step 3/3: Installing to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    cp -R "$APP_BUNDLE" "$INSTALL_DIR/$APP_NAME.app"
    echo "  Installed: $INSTALL_DIR/$APP_NAME.app"
else
    echo "Step 3/3: Skipping install (use --install to copy to ~/Applications)"
fi

echo ""
echo "Done! Run with:"
echo "  $APP_BUNDLE/Contents/MacOS/$APP_NAME"
echo "  $APP_BUNDLE/Contents/MacOS/$APP_NAME --scan"
echo "  $APP_BUNDLE/Contents/MacOS/$APP_NAME my-mapping.yaml"
