#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

record_start_error() {
  local code="$1"
  local line="$2"
  ensure_state_root
  printf '%s exit=%s line=%s\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "$code" "$line" >> "$START_ERROR_LOG"
  printf 'TRAE Work Dream Skin: start failed at line %s (exit %s). See %s\n' "$line" "$code" "$START_ERROR_LOG" >&2
}
trap 'code=$?; record_start_error "$code" "$LINENO"' ERR

PORT=9355
PORT_EXPLICIT="false"
RESTART_EXISTING="false"
PROMPT_RESTART="false"
FOREGROUND_INJECTOR="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-}"; PORT_EXPLICIT="true"; shift 2 ;;
    --restart-existing) RESTART_EXISTING="true"; shift ;;
    --prompt-restart) PROMPT_RESTART="true"; shift ;;
    --foreground-injector) FOREGROUND_INJECTOR="true"; shift ;;
    *) fail "Unknown start argument: $1" ;;
  esac
done
case "$PORT" in ''|*[!0-9]*) fail "Invalid port: $PORT" ;; esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Port must be between 1024 and 65535."

discover_trae_app
require_macos_runtime
ensure_state_root

if [ "$PORT_EXPLICIT" = "false" ] && [ -f "$STATE_PATH" ]; then
  saved_port="$(state_field port 2>/dev/null || true)"
  [ -n "$saved_port" ] && PORT="$saved_port"
fi

DEBUG_READY="false"
if verified_cdp_endpoint "$PORT"; then DEBUG_READY="true"; fi

if trae_is_running && [ "$DEBUG_READY" = "false" ]; then
  if [ "$PROMPT_RESTART" = "true" ] && [ "$RESTART_EXISTING" = "false" ]; then
    /usr/bin/osascript -e 'display dialog "TRAE Work 需要重启一次才能启用 Dream Skin。未发送的输入请先保存。" buttons {"取消", "重启并应用"} default button "重启并应用" with title "TRAE Work Dream Skin"' >/dev/null \
      || fail "Theme launch was cancelled."
    RESTART_EXISTING="true"
  fi
  [ "$RESTART_EXISTING" = "true" ] \
    || fail "TRAE Work is already running without the verified skin endpoint. Close it first or pass --restart-existing."
  stop_trae true
fi

if [ "$DEBUG_READY" = "false" ]; then
  PORT="$(select_available_port "$PORT")"
  printf 'Launching TRAE Work with loopback skin port %s…\n' "$PORT" >&2
  launch_trae_with_cdp "$PORT"
  wait_for_cdp "$PORT" \
    || fail "TRAE Work did not expose a verified loopback endpoint on port $PORT. See $APP_LOG and $APP_ERROR_LOG"
fi

if [ -f "$STATE_PATH" ]; then
  stop_recorded_injector
  /bin/rm -f "$STATE_PATH"
fi

if [ "$FOREGROUND_INJECTOR" = "true" ]; then
  exec "$NODE" "$INJECTOR" --watch --port "$PORT" --theme-dir "$THEME_DIR"
fi

INJECTOR_PID="$(launch_injector_daemon "$PORT")"
INJECTOR_STARTED_AT="$(process_started_at "$INJECTOR_PID")"
[ -n "$INJECTOR_STARTED_AT" ] || fail "Could not record the injector process start time."
TRAE_PID="$(trae_main_pids | /usr/bin/head -n 1)"
write_state "$PORT" "$INJECTOR_PID" "$INJECTOR_STARTED_AT" "${TRAE_PID:-0}"

VERIFY_OUTPUT="$STATE_ROOT/last-verify.json"
set +e
"$NODE" "$INJECTOR" --verify --port "$PORT" --theme-dir "$THEME_DIR" --timeout-ms 20000 >"$VERIFY_OUTPUT" 2>>"$INJECTOR_ERROR_LOG"
verify_code=$?
set -e
if [ "$verify_code" -ne 0 ]; then
  /bin/kill -TERM "$INJECTOR_PID" 2>/dev/null || true
  /bin/rm -f "$STATE_PATH"
  fail "Injection verification failed. The injector was stopped; see $VERIFY_OUTPUT and $INJECTOR_ERROR_LOG"
fi

printf 'TRAE Work Dream Skin %s is active on loopback port %s.\n' "$SKIN_VERSION" "$PORT"
