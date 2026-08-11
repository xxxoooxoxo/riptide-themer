#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PRESETS_DIR="$ROOT/presets"
STAMP_DIR="$HOME/Library/Application Support/Riptide Rounded Patcher"
PRESET_CONFIG="$STAMP_DIR/theme-preset"

usage() {
  print -r -- "usage: ./set-theme.sh <preset>"
  print -r -- ""
  print -r -- "available presets:"
  for preset_file in "$PRESETS_DIR"/*.css(N); do
    print -r -- "  ${${preset_file:t}%.css}"
  done
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 64
fi

PRESET="$1"
if [[ ! "$PRESET" =~ '^[a-z0-9]+(-[a-z0-9]+)*$' || ! -f "$PRESETS_DIR/$PRESET.css" ]]; then
  print -r -- "unknown theme preset: $PRESET" >&2
  usage >&2
  exit 64
fi

mkdir -p "$STAMP_DIR"
print -r -- "$PRESET" > "$PRESET_CONFIG"

RIPTIDE_THEME_PRESET="$PRESET" "$ROOT/patch-riptide-beta.sh"
print -r -- "selected $PRESET; reopen HumanLayer to apply it"
