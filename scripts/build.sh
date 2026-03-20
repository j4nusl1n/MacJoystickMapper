#!/usr/bin/env bash
#
# build.sh — Build MacJoystickMapper release binary
#
# Usage:
#   ./scripts/build.sh            # Build release binary
#   ./scripts/build.sh --debug    # Build debug binary
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG="release"
if [[ "${1:-}" == "--debug" ]]; then
    CONFIG="debug"
fi

echo "Building MacJoystickMapper ($CONFIG)..."
cd "$PROJECT_DIR"
swift build -c "$CONFIG"

BINARY="$PROJECT_DIR/.build/$CONFIG/MacJoystickMapper"
if [[ ! -f "$BINARY" ]]; then
    echo "Error: Build succeeded but binary not found at $BINARY"
    exit 1
fi

echo "Build complete: $BINARY"
