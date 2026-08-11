#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
SRC="$ROOT/wk-css-injector.m"
OUT="$BUILD_DIR/libriptide_css_injector.dylib"

mkdir -p "$BUILD_DIR"

xcrun clang \
  -dynamiclib \
  -fobjc-arc \
  -framework Foundation \
  -framework WebKit \
  "$SRC" \
  -o "$OUT"

codesign --force --sign - "$OUT" >/dev/null

echo "$OUT"
