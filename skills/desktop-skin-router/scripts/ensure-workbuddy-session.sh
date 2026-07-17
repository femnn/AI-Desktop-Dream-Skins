#!/bin/zsh
set -euo pipefail

STATE_ROOT="$HOME/Library/Application Support/DesktopSkinSessionGuard"
THEME_PATH="$(<"$STATE_ROOT/workbuddy-theme-path")"
LOCK="$STATE_ROOT/.workbuddy-session.lock"
STAMP="$STATE_ROOT/workbuddy-last-attempt"
LOG="$STATE_ROOT/workbuddy-session.log"
CORE_DIR="${CODEDROBE_CORE_DIR:-$HOME/Documents/WorkBuddy/CodeDrobe-core}"
PORT="${CODEDROBE_WORKBUDDY_PORT:-9336}"
NODE_BIN=""

[[ -f "$THEME_PATH" ]] || exit 0
if [[ -f "$CORE_DIR/bin/codedrobe.mjs" ]]; then
  for candidate in /usr/local/bin/node /opt/homebrew/bin/node /usr/bin/node; do
    if [[ -x "$candidate" ]]; then NODE_BIN="$candidate"; break; fi
  done
  [[ -n "$NODE_BIN" ]] || exit 0
  CLI=("$NODE_BIN" "$CORE_DIR/bin/codedrobe.mjs")
elif command -v codedrobe >/dev/null 2>&1; then
  CLI=(codedrobe)
else
  exit 0
fi

if ${CLI[@]} verify --app workbuddy --port "$PORT" --theme "$THEME_PATH" --json >/dev/null 2>&1; then
  exit 0
fi
if ! /bin/ps -axo command= | /usr/bin/grep -F '/Applications/WorkBuddy.app/Contents/MacOS/Electron' | /usr/bin/grep -v grep >/dev/null; then
  exit 0
fi

now="$(/bin/date '+%s')"
last="$(/bin/cat "$STAMP" 2>/dev/null || printf '0')"
[[ "$last" == <-> ]] || last=0
(( now - last >= 30 )) || exit 0
mkdir "$LOCK" 2>/dev/null || exit 0
cleanup() { /usr/bin/find "$LOCK" -depth -delete 2>/dev/null || true; }
trap cleanup EXIT
printf '%s\n' "$now" >"$STAMP"
printf '%s recovering WorkBuddy theme %s\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "$THEME_PATH" >>"$LOG"
if /usr/bin/curl --noproxy '*' --silent --fail --max-time 1 \
  "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  APPLY_ARGS=(apply --app workbuddy --port "$PORT" --theme "$THEME_PATH" --json)
  printf '%s WorkBuddy endpoint ready; using hot recovery\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
else
  APPLY_ARGS=(apply --app workbuddy --port "$PORT" --theme "$THEME_PATH" --restart-existing --json)
  printf '%s WorkBuddy endpoint absent; allowing one controlled recovery restart\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
fi
if ${CLI[@]} ${APPLY_ARGS[@]} >>"$LOG" 2>&1 \
  && ${CLI[@]} verify --app workbuddy --port "$PORT" --theme "$THEME_PATH" --json >>"$LOG" 2>&1; then
  printf '%s WorkBuddy recovery complete\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
else
  printf '%s WorkBuddy recovery failed\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
fi
