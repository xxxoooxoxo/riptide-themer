#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/Riptide Rounded Patcher.app"
CONTENTS="$APP/Contents"
EXECUTABLE="$CONTENTS/MacOS/RiptideRoundedPatcher"
if [[ -z "${RIPTIDE_PATCHER_SIGNING_IDENTITY:-}" ]]; then
  print -u2 "RIPTIDE_PATCHER_SIGNING_IDENTITY must name a local code-signing identity"
  exit 1
fi
SIGNING_IDENTITY="$RIPTIDE_PATCHER_SIGNING_IDENTITY"

mkdir -p "$CONTENTS/MacOS"

xcrun swiftc \
  -parse-as-library \
  -O \
  "$ROOT/RiptideRoundedPatcher.swift" \
  -o "$EXECUTABLE"

cp "$ROOT/RiptideRoundedPatcher-Info.plist" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy \
  -c "Set :RiptidePatchScript $ROOT/patch-humanlayer-apps.sh" \
  "$CONTENTS/Info.plist"

codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --sign "$SIGNING_IDENTITY" \
  "$APP"

echo "built $APP"
