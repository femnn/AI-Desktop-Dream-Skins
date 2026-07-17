#!/bin/bash

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
ENGINE="${CODEX_DREAM_SKIN_ENGINE:-$HOME/.codex/codex-dream-skin-studio}"
STATE_ROOT="$HOME/Library/Application Support/CodexDreamSkinStudio"
CURRENT_PACK="$STATE_ROOT/current-pack.json"
LOCK="$STATE_ROOT/.pack-switch.lock"
LOG="$STATE_ROOT/session-guard.log"
PORT=9341

[ -f "$CURRENT_PACK" ] || exit 0

lock_owner_is_alive() {
  [ -f "$LOCK/pid" ] || return 1
  owner="$(/bin/cat "$LOCK/pid" 2>/dev/null || true)"
  case "$owner" in
    ''|*[!0-9]*) return 1 ;;
  esac
  /bin/kill -0 "$owner" 2>/dev/null
}

if [ -d "$LOCK" ]; then
  if lock_owner_is_alive; then exit 0; fi
  printf '%s removing stale pack lock\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
  /usr/bin/find "$LOCK" -depth -delete 2>/dev/null || true
fi

if ! /bin/ps -axo command= | /usr/bin/grep -F '/Applications/ChatGPT.app/Contents/MacOS/ChatGPT' | /usr/bin/grep -v grep >/dev/null; then
  exit 0
fi

if /usr/bin/curl --noproxy '*' --silent --fail --max-time 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  if [ -f "$STATE_ROOT/state.json" ]; then exit 0; fi
fi

if ! /bin/mkdir "$LOCK" 2>/dev/null; then exit 0; fi
printf '%s\n' "$$" >"$LOCK/pid"
cleanup() { /usr/bin/find "$LOCK" -depth -delete 2>/dev/null || true; }
trap cleanup EXIT

printf '%s restoring current pack session\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
/bin/bash "$ENGINE/scripts/start-dream-skin-macos.sh" --port "$PORT" --restart-existing >>"$LOG" 2>&1 || true
