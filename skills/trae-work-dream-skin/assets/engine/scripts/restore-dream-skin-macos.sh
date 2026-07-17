#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

PORT=9355
PORT_EXPLICIT="false"
RESTART_TRAE="false"
UNINSTALL="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-}"; PORT_EXPLICIT="true"; shift 2 ;;
    --restart-trae) RESTART_TRAE="true"; shift ;;
    --uninstall) UNINSTALL="true"; shift ;;
    *) fail "Unknown restore argument: $1" ;;
  esac
done

discover_trae_app
require_macos_runtime
ensure_state_root
if [ "$PORT_EXPLICIT" = "false" ] && [ -f "$STATE_PATH" ]; then
  PORT="$(state_field port 2>/dev/null || printf '9355')"
fi

if [ -f "$STATE_PATH" ]; then stop_recorded_injector; fi
TRAE_RUNNING="false"
trae_is_running && TRAE_RUNNING="true"
DEBUG_READY="false"
verified_cdp_endpoint "$PORT" && DEBUG_READY="true"

if [ "$DEBUG_READY" = "true" ]; then
  "$NODE" "$INJECTOR" --remove --port "$PORT" --theme-dir "$THEME_DIR" --timeout-ms 10000 >/dev/null \
    || fail "The live skin could not be removed and verified."
elif [ "$TRAE_RUNNING" = "true" ] && [ "$RESTART_TRAE" = "false" ]; then
  fail "TRAE Work is running but the saved debug endpoint cannot be verified. Pass --restart-trae for a full restore."
fi

if [ "$RESTART_TRAE" = "true" ]; then
  [ "$TRAE_RUNNING" = "true" ] && stop_trae true
  launch_trae_normally
fi

/bin/rm -f "$STATE_PATH"
if [ "$UNINSTALL" = "true" ]; then
  /bin/rm -f "$HOME/Desktop/TRAE Work Dream Skin.command"
  /bin/rm -f "$HOME/Desktop/TRAE Work Dream Skin - Customize.command"
  /bin/rm -f "$HOME/Desktop/TRAE Work Dream Skin - Verify.command"
  /bin/rm -f "$HOME/Desktop/TRAE Work Dream Skin - Restore.command"
fi

printf 'TRAE Work Dream Skin was removed and the official appearance was restored.\n'
