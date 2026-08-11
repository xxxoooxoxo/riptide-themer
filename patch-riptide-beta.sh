#!/bin/zsh
set -euo pipefail

# Patches the REAL /Applications/HumanLayer.app in place so that launching it
# normally (Dock / Finder / `open`) always auto-injects the rounded CSS.
#
# It does this by:
#   1. Adding LSEnvironment (DYLD_INSERT_LIBRARIES + RIPTIDE_CUSTOM_CSS) to the
#      app's Info.plist, which LaunchServices applies on every normal launch.
#   2. Re-signing the bundle ad-hoc with disable-library-validation so the
#      hardened-runtime process accepts our ad-hoc-signed dylib.
#
# HumanLayer auto-updates overwrite the bundle and revert this patch, so the
# companion LaunchAgent re-runs this script whenever the bundle changes.

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="/Applications/HumanLayer.app"
PLIST="$APP/Contents/Info.plist"
EXE="$APP/Contents/MacOS/HumanLayer-Local"
CSS="$ROOT/rounded.css"
PRESETS_DIR="$ROOT/presets"
LIB="$ROOT/build/libriptide_css_injector.dylib"
SRC="$ROOT/wk-css-injector.m"
ENTITLEMENTS="$ROOT/local-entitlements.plist"
STAMP_DIR="$HOME/Library/Application Support/Riptide Rounded Patcher"
STAMP="$STAMP_DIR/patch-stamp"
PRESET_CONFIG="$STAMP_DIR/theme-preset"
DEFAULT_PRESET="vercel-dark"

mkdir -p "$STAMP_DIR"

log() { print -r -- "[patch-riptide-beta] $*"; }

if [[ ! -d "$APP" ]]; then
  log "app not found: $APP" >&2
  exit 1
fi

if [[ ! -f "$CSS" ]]; then
  log "CSS not found: $CSS" >&2
  exit 1
fi

# A shell override updates the persisted selection. Otherwise, reuse the saved
# selection so HumanLayer updates do not reset the user's theme.
if [[ -n "${RIPTIDE_THEME_PRESET:-}" ]]; then
  PRESET="$RIPTIDE_THEME_PRESET"
elif [[ -f "$PRESET_CONFIG" ]]; then
  PRESET="$(<"$PRESET_CONFIG")"
else
  PRESET="$DEFAULT_PRESET"
fi

if [[ ! "$PRESET" =~ '^[a-z0-9]+(-[a-z0-9]+)*$' || ! -f "$PRESETS_DIR/$PRESET.css" ]]; then
  log "unknown theme preset: $PRESET" >&2
  log "available presets:" >&2
  for preset_file in "$PRESETS_DIR"/*.css(N); do
    log "  ${${preset_file:t}%.css}" >&2
  done
  exit 1
fi

print -r -- "$PRESET" > "$PRESET_CONFIG"

# Build the injector dylib if missing or stale.
if [[ ! -f "$LIB" || "$SRC" -nt "$LIB" ]]; then
  log "building injector dylib"
  "$ROOT/build-local-injector.sh" >/dev/null
fi

# Skip if already patched for this exact bundle signing timestamp + dylib mtime.
current_sig="$(stat -f '%m' "$EXE" 2>/dev/null || echo 0):$(stat -f '%m' "$LIB" 2>/dev/null || echo 0):$(stat -f '%m' "$CSS" 2>/dev/null || echo 0):$PRESET:$(stat -f '%m' "$PRESETS_DIR/$PRESET.css" 2>/dev/null || echo 0)"
if [[ -f "$STAMP" && "$(cat "$STAMP" 2>/dev/null)" == "$current_sig" ]]; then
  # Verify LSEnvironment is still present (belt and suspenders).
  installed_css="$(/usr/libexec/PlistBuddy -c "Print :LSEnvironment:RIPTIDE_CUSTOM_CSS" "$PLIST" 2>/dev/null || true)"
  installed_preset="$(/usr/libexec/PlistBuddy -c "Print :LSEnvironment:RIPTIDE_THEME_PRESET" "$PLIST" 2>/dev/null || true)"
  if /usr/libexec/PlistBuddy -c "Print :LSEnvironment:DYLD_INSERT_LIBRARIES" "$PLIST" >/dev/null 2>&1 \
    && [[ "$installed_css" == "$CSS" && "$installed_preset" == "$PRESET" ]]; then
    log "already patched, nothing to do"
    exit 0
  fi
fi

# codesign cannot re-sign a running executable; quit the app first if needed.
if pgrep -x HumanLayer-Local >/dev/null 2>&1; then
  log "quitting running HumanLayer to allow re-signing"
  pkill -TERM -x HumanLayer-Local >/dev/null 2>&1 || true
  for _ in {1..20}; do
    pgrep -x HumanLayer-Local >/dev/null 2>&1 || break
    sleep 0.5
  done
  pkill -x HumanLayer-Local >/dev/null 2>&1 || true
  sleep 0.5
fi

log "writing LSEnvironment into Info.plist"
/usr/libexec/PlistBuddy -c "Delete :LSEnvironment" "$PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSEnvironment dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :LSEnvironment:DYLD_INSERT_LIBRARIES string $LIB" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :LSEnvironment:RIPTIDE_CUSTOM_CSS string $CSS" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :LSEnvironment:RIPTIDE_THEME_PRESET string $PRESET" "$PLIST"

log "re-signing $APP (ad-hoc, disable-library-validation)"
codesign \
  --force \
  --deep \
  --sign - \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  "$APP" >/dev/null

# Refresh LaunchServices so the new LSEnvironment is honored.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true

print -r -- "$(stat -f '%m' "$EXE"):$(stat -f '%m' "$LIB"):$(stat -f '%m' "$CSS"):$PRESET:$(stat -f '%m' "$PRESETS_DIR/$PRESET.css")" > "$STAMP"
log "done — active preset: $PRESET"
