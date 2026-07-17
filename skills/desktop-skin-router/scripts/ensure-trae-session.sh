#!/bin/bash
set -euo pipefail

STATE_ROOT="$HOME/Library/Application Support/DesktopSkinSessionGuard"
TRAE_STATE="$HOME/Library/Application Support/TraeWorkDreamSkinStudio"
ENGINE="$HOME/.trae/trae-work-dream-skin-studio"
LOCK="$STATE_ROOT/.trae-session.lock"
STAMP="$STATE_ROOT/trae-last-attempt"
LOG="$STATE_ROOT/trae-session.log"
PORT=9355

[ -s "$TRAE_STATE/theme/theme.json" ] || exit 0
[ -x "$ENGINE/scripts/start-dream-skin-macos.sh" ] || exit 0

if [ -f "$TRAE_STATE/state.json" ]; then
  saved_port="$(/usr/bin/plutil -extract port raw -o - "$TRAE_STATE/state.json" 2>/dev/null || true)"
  case "$saved_port" in ''|*[!0-9]*) ;; *) PORT="$saved_port" ;; esac
fi

if /usr/bin/curl --noproxy '*' --silent --fail --max-time 1 \
  "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  printf '%s TRAE endpoint ready; using hot recovery\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
  if "$ENGINE/scripts/start-dream-skin-macos.sh" --port "$PORT" >>"$LOG" 2>&1; then
    printf '%s TRAE hot recovery complete\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
  else
    printf '%s TRAE hot recovery failed\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
  fi
  exit 0
fi

if ! /bin/ps -axo command= | /usr/bin/grep -E '/Applications/TRAE (Work|SOLO|SOLO CN)\.app/Contents/MacOS/' | /usr/bin/grep -v grep >/dev/null; then
  exit 0
fi

now="$(/bin/date '+%s')"
last="$(/bin/cat "$STAMP" 2>/dev/null || printf '0')"
case "$last" in ''|*[!0-9]*) last=0 ;; esac
[ $((now - last)) -ge 30 ] || exit 0
if ! /bin/mkdir "$LOCK" 2>/dev/null; then exit 0; fi
cleanup() { /usr/bin/find "$LOCK" -depth -delete 2>/dev/null || true; }
trap cleanup EXIT
printf '%s\n' "$now" >"$STAMP"
printf '%s recovering TRAE theme on port %s\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "$PORT" >>"$LOG"
printf '%s TRAE endpoint absent; allowing one controlled recovery restart\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
if "$ENGINE/scripts/start-dream-skin-macos.sh" --port "$PORT" --restart-existing >>"$LOG" 2>&1; then
  printf '%s TRAE recovery complete\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
else
  printf '%s TRAE recovery failed\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
fi
