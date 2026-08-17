#!/bin/zsh
set -euo pipefail

# Patches the packaged Electron app in place. Unlike the native HumanLayer app,
# Electron renders with Chromium rather than WKWebView, so the dylib hook cannot
# reach it. Install the same stylesheet as a renderer asset instead.

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="${HUMANLAYER_ELECTRON_APP:-/Applications/HumanLayerElectron.app}"
THEME_ROOT="${RIPTIDE_THEME_ROOT:-$ROOT}"
PLIST="$APP/Contents/Info.plist"
EXE="$APP/Contents/MacOS/HumanLayerElectron"
RENDERER_DIR="$APP/Contents/Resources/renderer"
INDEX="$RENDERER_DIR/index.html"
CSS="$THEME_ROOT/rounded.css"
PRESETS_DIR="$THEME_ROOT/presets"
INSTALLED_CSS="$RENDERER_DIR/riptide-rounded.css"
INSTALLED_PRESET_CSS="$RENDERER_DIR/riptide-rounded-preset.css"
BASE_LINK_MARKER="riptide-rounded-local-css"
PRESET_LINK_MARKER="riptide-rounded-preset-css"
BASE_LINK="    <link id=\"$BASE_LINK_MARKER\" rel=\"stylesheet\" href=\"/riptide-rounded.css\">"
PRESET_LINK="    <link id=\"$PRESET_LINK_MARKER\" rel=\"stylesheet\" href=\"/riptide-rounded-preset.css\">"
ENTITLEMENTS="$ROOT/local-entitlements.plist"
PRESET_CONFIG="$HOME/Library/Application Support/Riptide Rounded Patcher/theme-preset"
DEFAULT_PRESET="lets-get-nauti"

log() { print -r -- "[patch-humanlayer-electron] $*"; }

if [[ ! -d "$APP" ]]; then
  log "app not found: $APP" >&2
  exit 1
fi

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST" 2>/dev/null)" != "com.humanlayer.electron" ]]; then
  log "unexpected bundle identifier in $PLIST" >&2
  exit 1
fi

if [[ -n "${RIPTIDE_THEME_PRESET:-}" ]]; then
  PRESET="$RIPTIDE_THEME_PRESET"
elif [[ -f "$PRESET_CONFIG" ]]; then
  PRESET="$(<"$PRESET_CONFIG")"
else
  PRESET="$DEFAULT_PRESET"
fi
PRESET_CSS="$PRESETS_DIR/$PRESET.css"

if [[ ! "$PRESET" =~ '^[a-z0-9]+(-[a-z0-9]+)*$' || ! -f "$PRESET_CSS" ]]; then
  log "unknown theme preset: $PRESET" >&2
  exit 1
fi

for required in "$EXE" "$INDEX" "$CSS" "$PRESET_CSS" "$ENTITLEMENTS"; do
  if [[ ! -f "$required" ]]; then
    log "required file not found: $required" >&2
    exit 1
  fi
done

if ! grep -Fq '</head>' "$INDEX"; then
  log "could not find </head> in $INDEX" >&2
  exit 1
fi

if cmp -s "$CSS" "$INSTALLED_CSS" \
  && cmp -s "$PRESET_CSS" "$INSTALLED_PRESET_CSS" \
  && grep -Fq "id=\"$BASE_LINK_MARKER\"" "$INDEX" \
  && grep -Fq "id=\"$PRESET_LINK_MARKER\"" "$INDEX" \
  && grep -Fq "data-rr-preset=\"$PRESET\"" "$INDEX"; then
  log "already patched, nothing to do — active preset: $PRESET"
  exit 0
fi

# codesign cannot re-sign a running app bundle reliably. Stop only this app;
# its helper and renderer processes exit with the main process.
if pgrep -x HumanLayerElectron >/dev/null 2>&1; then
  log "quitting running HumanLayerElectron to allow re-signing"
  pkill -TERM -x HumanLayerElectron >/dev/null 2>&1 || true
  for _ in {1..20}; do
    pgrep -x HumanLayerElectron >/dev/null 2>&1 || break
    sleep 0.5
  done
  pkill -x HumanLayerElectron >/dev/null 2>&1 || true
  sleep 0.5
fi

log "installing rounded CSS renderer asset"
cp "$CSS" "$INSTALLED_CSS"
cp "$PRESET_CSS" "$INSTALLED_PRESET_CSS"

if ! grep -Fq "id=\"$BASE_LINK_MARKER\"" "$INDEX" \
  || ! grep -Fq "id=\"$PRESET_LINK_MARKER\"" "$INDEX" \
  || ! grep -Fq "data-rr-preset=\"$PRESET\"" "$INDEX"; then
  tmp_index="$(mktemp "$RENDERER_DIR/.riptide-index.XXXXXX")"
  trap 'rm -f "$tmp_index"' EXIT

  has_base_link=false
  has_preset_link=false
  grep -Fq "id=\"$BASE_LINK_MARKER\"" "$INDEX" && has_base_link=true
  grep -Fq "id=\"$PRESET_LINK_MARKER\"" "$INDEX" && has_preset_link=true

  /usr/bin/awk \
    -v preset="$PRESET" \
    -v base_link="$BASE_LINK" \
    -v preset_link="$PRESET_LINK" \
    -v has_base_link="$has_base_link" \
    -v has_preset_link="$has_preset_link" '
    /<html[ >]/ && !updated_html {
      gsub(/ data-rr-preset="[^"]*"/, "")
      sub(/<html/, "<html data-rr-preset=\"" preset "\"")
      updated_html = 1
    }
    /<\/head>/ && !inserted_links {
      if (has_base_link != "true") print base_link
      if (has_preset_link != "true") print preset_link
      inserted_links = 1
    }
    { print }
    END { if (!inserted_links) exit 42 }
  ' "$INDEX" > "$tmp_index"

  chmod "$(stat -f '%Lp' "$INDEX")" "$tmp_index"
  mv "$tmp_index" "$INDEX"
  trap - EXIT
fi

mkdir -p "${PRESET_CONFIG:h}"
print -r -- "$PRESET" > "$PRESET_CONFIG"

log "re-signing $APP (ad-hoc)"
codesign \
  --force \
  --sign - \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  "$APP" >/dev/null

codesign --verify --deep --strict "$APP"

# Refresh LaunchServices so normal Dock, Finder, and `open` launches use the
# newly signed bundle.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true

log "done — active preset: $PRESET"
