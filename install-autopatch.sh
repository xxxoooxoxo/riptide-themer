#!/bin/zsh
set -euo pipefail

# Installs the LaunchAgent that keeps /Applications/HumanLayer.app auto-injecting
# the rounded CSS, re-applying the patch at login and after every auto-update.

ROOT="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.riptide.rounded.autopatch"
TEMPLATE="$ROOT/$LABEL.plist"
DEST_DIR="$HOME/Library/LaunchAgents"
DEST="$DEST_DIR/$LABEL.plist"
PATCHER_EXECUTABLE="$HOME/Applications/Riptide Rounded Patcher.app/Contents/MacOS/RiptideRoundedPatcher"

mkdir -p "$DEST_DIR"
"$ROOT/build-patcher-app.sh"
sed "s|__PATCHER_EXECUTABLE__|$PATCHER_EXECUTABLE|g" "$TEMPLATE" > "$DEST"

# Reload cleanly.
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$DEST"
launchctl enable "gui/$(id -u)/$LABEL"

echo "installed $DEST"
