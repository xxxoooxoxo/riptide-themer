#!/bin/zsh
set -u

# Keep both current HumanLayer desktop implementations patched. Each patcher
# uses the injection mechanism appropriate to that app's renderer.

ROOT="$(cd "$(dirname "$0")" && pwd)"
status=0
patched_any=false

run_if_installed() {
  local app="$1"
  local patcher="$2"

  if [[ ! -d "$app" ]]; then
    return
  fi

  patched_any=true
  if ! "$patcher"; then
    status=1
  fi
}

run_if_installed "/Applications/HumanLayer.app" "$ROOT/patch-riptide-beta.sh"
run_if_installed "/Applications/HumanLayerElectron.app" "$ROOT/patch-humanlayer-electron.sh"

if [[ "$patched_any" == false ]]; then
  print -u2 -- "[patch-humanlayer-apps] no supported HumanLayer app was found"
  exit 1
fi

exit "$status"
