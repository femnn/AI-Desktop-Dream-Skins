#!/bin/bash

set -euo pipefail

resolve_executable() {
  local app="${TRAE_BUNDLE:-}"
  local candidate
  local identifier
  local executable_name

  for candidate in \
    "$app" \
    "/Applications/TRAE Work.app" \
    "/Applications/TRAE SOLO.app" \
    "/Applications/TRAE SOLO CN.app" \
    "$HOME/Applications/TRAE Work.app" \
    "$HOME/Applications/TRAE SOLO.app" \
    "$HOME/Applications/TRAE SOLO CN.app"
  do
    [ -n "$candidate" ] || continue
    [ -f "$candidate/Contents/Info.plist" ] || continue
    identifier="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$candidate/Contents/Info.plist" 2>/dev/null || true)"
    case "$identifier" in com.trae.solo.app|com.trae.work.app|cn.trae.solo.app) ;; *) continue ;; esac
    executable_name="$(/usr/bin/plutil -extract CFBundleExecutable raw -o - "$candidate/Contents/Info.plist")"
    printf '%s\n' "$candidate/Contents/MacOS/$executable_name"
    return 0
  done
  return 1
}

EXE="${TRAE_EXE:-}"
if [ -z "$EXE" ] || [ ! -x "$EXE" ]; then
  EXE="$(resolve_executable)" || {
    printf 'TRAE Work Dream Skin: official TRAE Work executable was not found.\n' >&2
    exit 1
  }
fi

export ELECTRON_RUN_AS_NODE=1
exec "$EXE" "$@"
