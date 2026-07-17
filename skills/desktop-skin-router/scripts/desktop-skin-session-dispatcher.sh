#!/bin/bash
set -euo pipefail

STATE_ROOT="$HOME/Library/Application Support/DesktopSkinSessionGuard"
LOG="$STATE_ROOT/session-guard.log"
BUNDLE_ID="${1:-}"
/bin/mkdir -p "$STATE_ROOT"

printf '%s launch event %s\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "$BUNDLE_ID" >>"$LOG"

case "$BUNDLE_ID" in
  com.workbuddy.workbuddy)
    [ -s "$STATE_ROOT/workbuddy-theme-path" ] || exit 0
    exec "$STATE_ROOT/ensure-workbuddy-session.sh"
    ;;
  com.trae.solo.app|com.trae.work.app|cn.trae.solo.app)
    [ -e "$STATE_ROOT/trae-enabled" ] || exit 0
    exec "$STATE_ROOT/ensure-trae-session.sh"
    ;;
  *) exit 0 ;;
esac
