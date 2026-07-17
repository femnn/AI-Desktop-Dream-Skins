#!/bin/bash

set -euo pipefail

if [ -z "${HOME:-}" ]; then
  CURRENT_USER="$(/usr/bin/id -un)"
  HOME="$(/usr/bin/dscl . -read "/Users/$CURRENT_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
  [ -n "$HOME" ] || { printf 'TRAE Work Dream Skin: could not resolve the current home directory.\n' >&2; exit 1; }
  export HOME
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
INJECTOR="$SCRIPT_DIR/injector.mjs"
NODE_WRAPPER="$SCRIPT_DIR/trae-runtime-node-macos.sh"
INSTALL_ROOT="$HOME/.trae/trae-work-dream-skin-studio"
STATE_ROOT="$HOME/Library/Application Support/TraeWorkDreamSkinStudio"
STATE_PATH="$STATE_ROOT/state.json"
THEME_DIR="$STATE_ROOT/theme"
INJECTOR_LOG="$STATE_ROOT/injector.log"
INJECTOR_ERROR_LOG="$STATE_ROOT/injector-error.log"
APP_LOG="$STATE_ROOT/trae-launch.log"
APP_ERROR_LOG="$STATE_ROOT/trae-launch-error.log"
START_ERROR_LOG="$STATE_ROOT/start-error.log"
INJECTOR_JOB_LABEL="com.trae.work-dream-skin-studio.injector"
EXPECTED_TRAE_GLOBAL_TEAM_ID="${TRAE_EXPECTED_TEAM_ID:-79M8227NKH}"
EXPECTED_TRAE_CN_TEAM_ID="${TRAE_EXPECTED_CN_TEAM_ID:-CG2SCM6AV5}"
SKIN_VERSION="0.2.0"

fail() {
  local message="$*"
  if [ -n "${START_ERROR_LOG:-}" ] && [ -n "${STATE_ROOT:-}" ]; then
    /bin/mkdir -p "$STATE_ROOT" 2>/dev/null || true
    printf '%s %s\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "$message" >> "$START_ERROR_LOG" 2>/dev/null || true
  fi
  printf 'TRAE Work Dream Skin: %s\n' "$message" >&2
  exit 1
}

ensure_state_root() {
  /bin/mkdir -p "$STATE_ROOT"
  /bin/chmod 700 "$STATE_ROOT"
}

is_supported_trae_bundle_id() {
  case "$1" in
    com.trae.solo.app|com.trae.work.app|cn.trae.solo.app) return 0 ;;
    *) return 1 ;;
  esac
}

expected_trae_team_id() {
  case "$1" in
    cn.trae.solo.app) printf '%s\n' "$EXPECTED_TRAE_CN_TEAM_ID" ;;
    com.trae.solo.app|com.trae.work.app) printf '%s\n' "$EXPECTED_TRAE_GLOBAL_TEAM_ID" ;;
    *) return 1 ;;
  esac
}

discover_trae_app() {
  local candidate=""
  local identifier=""
  local executable_name=""
  local configured="${TRAE_WORK_APP_BUNDLE:-}"

  for candidate in \
    "$configured" \
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
    if is_supported_trae_bundle_id "$identifier"; then
      TRAE_BUNDLE="$candidate"
      TRAE_BUNDLE_ID="$identifier"
      break
    fi
  done

  if [ -z "${TRAE_BUNDLE:-}" ]; then
    for identifier in com.trae.solo.app com.trae.work.app cn.trae.solo.app; do
      candidate="$(/usr/bin/mdfind "kMDItemCFBundleIdentifier == \"$identifier\"" | /usr/bin/head -n 1)"
      [ -n "$candidate" ] || continue
      [ -f "$candidate/Contents/Info.plist" ] || continue
      TRAE_BUNDLE="$candidate"
      TRAE_BUNDLE_ID="$identifier"
      break
    done
  fi

  [ -n "${TRAE_BUNDLE:-}" ] || fail "Could not find the official TRAE Work desktop app."
  executable_name="$(/usr/bin/plutil -extract CFBundleExecutable raw -o - "$TRAE_BUNDLE/Contents/Info.plist")"
  TRAE_EXE="$TRAE_BUNDLE/Contents/MacOS/$executable_name"
  TRAE_VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$TRAE_BUNDLE/Contents/Info.plist")"
  [ -x "$TRAE_EXE" ] || fail "TRAE Work executable is missing: $TRAE_EXE"
  export TRAE_BUNDLE TRAE_BUNDLE_ID TRAE_EXE TRAE_VERSION
}

codesign_team_id() {
  /usr/bin/codesign -dv --verbose=4 "$1" 2>&1 \
    | /usr/bin/awk -F= '/^TeamIdentifier=/{print $2; exit}'
}

require_macos_runtime() {
  local machine_arch
  local node_major

  [ "$(/usr/bin/uname -s)" = "Darwin" ] || fail "This launcher requires macOS."
  [ -n "${TRAE_BUNDLE:-}" ] || fail "Discover TRAE Work before validating its runtime."
  [ -x "$NODE_WRAPPER" ] || fail "The signed-runtime wrapper is missing: $NODE_WRAPPER"

  /usr/bin/codesign --verify --deep --strict "$TRAE_BUNDLE" >/dev/null 2>&1 \
    || fail "TRAE Work's code signature is invalid. Reinstall the official app before continuing."
  /usr/bin/codesign --verify --strict "$TRAE_EXE" >/dev/null 2>&1 \
    || fail "TRAE Work's Electron executable failed signature validation."

  TRAE_TEAM_ID="$(codesign_team_id "$TRAE_BUNDLE")"
  EXE_TEAM_ID="$(codesign_team_id "$TRAE_EXE")"
  EXPECTED_TRAE_TEAM_ID="$(expected_trae_team_id "$TRAE_BUNDLE_ID")" \
    || fail "Unsupported TRAE Work bundle identifier: $TRAE_BUNDLE_ID"
  [ "$TRAE_TEAM_ID" = "$EXPECTED_TRAE_TEAM_ID" ] \
    || fail "Unexpected TRAE Work signing team: ${TRAE_TEAM_ID:-missing}."
  [ "$EXE_TEAM_ID" = "$TRAE_TEAM_ID" ] \
    || fail "TRAE Work's executable signer does not match its app bundle."

  machine_arch="$(/usr/bin/uname -m)"
  /usr/bin/file "$TRAE_EXE" | /usr/bin/grep -Eq "$machine_arch|universal binary" \
    || fail "TRAE Work does not contain the current Mac architecture ($machine_arch)."

  NODE="$NODE_WRAPPER"
  NODE_VERSION="$(ELECTRON_RUN_AS_NODE=1 "$TRAE_EXE" --version 2>/dev/null || true)"
  node_major="${NODE_VERSION#v}"
  node_major="${node_major%%.*}"
  case "$node_major" in ''|*[!0-9]*) fail "Could not validate TRAE Work's embedded Node version: ${NODE_VERSION:-missing}" ;; esac
  [ "$node_major" -ge 22 ] || fail "TRAE Work's embedded Node $NODE_VERSION is too old; version 22 or newer is required."

  export NODE NODE_VERSION TRAE_TEAM_ID EXE_TEAM_ID
}

trae_main_pids() {
  local pid
  local command_line
  while read -r pid command_line; do
    [ -n "$pid" ] || continue
    case "$command_line" in
      "$TRAE_EXE"*)
        case "$command_line" in
          *injector.mjs*|*write-theme.mjs*|*" -e "*|*" --check "*) ;;
          *) printf '%s\n' "$pid" ;;
        esac
        ;;
    esac
  done < <(/bin/ps -axo pid=,command=)
}

trae_is_running() {
  [ -n "$(trae_main_pids)" ]
}

process_started_at() {
  /bin/ps -p "$1" -o lstart= 2>/dev/null | /usr/bin/awk '{$1=$1; print}'
}

stop_trae() {
  local allow_force="${1:-false}"
  local deadline
  local pid

  trae_is_running || return 0
  /usr/bin/osascript -e "tell application id \"$TRAE_BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  deadline=$((SECONDS + 20))
  while trae_is_running && [ "$SECONDS" -lt "$deadline" ]; do /bin/sleep 0.25; done
  trae_is_running || return 0

  [ "$allow_force" = "true" ] || fail "TRAE Work did not close within 20 seconds; explicit restart authorization is required."
  while IFS= read -r pid; do
    [ -n "$pid" ] && /bin/kill -TERM "$pid" 2>/dev/null || true
  done < <(trae_main_pids)
  deadline=$((SECONDS + 5))
  while trae_is_running && [ "$SECONDS" -lt "$deadline" ]; do /bin/sleep 0.25; done
  if trae_is_running; then
    while IFS= read -r pid; do
      [ -n "$pid" ] && /bin/kill -KILL "$pid" 2>/dev/null || true
    done < <(trae_main_pids)
  fi
  /bin/sleep 0.4
  trae_is_running && fail "TRAE Work could not be stopped safely."
}

listener_pids() {
  /usr/sbin/lsof -nP -iTCP:"$1" -sTCP:LISTEN -t 2>/dev/null | /usr/bin/sort -u || true
}

port_is_available() {
  [ -z "$(listener_pids "$1")" ]
}

pid_is_trae_descendant() {
  local current="$1"
  local command_line=""
  local parent=""
  local depth=0
  while [ "$current" -gt 1 ] 2>/dev/null && [ "$depth" -lt 32 ]; do
    command_line="$(/bin/ps -p "$current" -o command= 2>/dev/null || true)"
    case "$command_line" in "$TRAE_EXE"*) return 0 ;; esac
    parent="$(/bin/ps -p "$current" -o ppid= 2>/dev/null | /usr/bin/awk '{$1=$1; print}')"
    case "$parent" in ''|*[!0-9]*) return 1 ;; esac
    [ "$parent" -ne "$current" ] || return 1
    current="$parent"
    depth=$((depth + 1))
  done
  return 1
}

port_belongs_to_trae() {
  local port="$1"
  local found="false"
  local pid
  local command_line
  while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    command_line="$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)"
    case "$command_line" in
      "$TRAE_EXE"*) found="true" ;;
      *) pid_is_trae_descendant "$pid" || return 1 ;;
    esac
  done < <(listener_pids "$port")
  [ "$found" = "true" ]
}

cdp_http_ready() {
  local port="$1"
  /usr/bin/curl --noproxy '*' --silent --fail --max-time 1 \
    "http://127.0.0.1:${port}/json/version" >/dev/null 2>&1
}

verified_cdp_endpoint() {
  local port="$1"
  cdp_http_ready "$port" || return 1
  port_belongs_to_trae "$port" || return 1
  return 0
}

select_available_port() {
  local preferred="$1"
  local candidate="$preferred"
  local last=$((preferred + 100))
  [ "$last" -le 65535 ] || last=65535
  while [ "$candidate" -le "$last" ]; do
    if port_is_available "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
    candidate=$((candidate + 1))
  done
  fail "No free loopback port was found between $preferred and $last."
}

wait_for_cdp() {
  local port="$1"
  local deadline=$((SECONDS + 45))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if verified_cdp_endpoint "$port"; then return 0; fi
    /bin/sleep 0.35
  done
  return 1
}

state_field() {
  local key="$1"
  "$NODE" -e '
    const fs = require("node:fs");
    const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"))[process.argv[2]];
    if (value !== undefined && value !== null) process.stdout.write(String(value));
  ' "$STATE_PATH" "$key"
}

write_state() {
  local port="$1"
  local injector_pid="$2"
  local injector_started_at="$3"
  local trae_pid="$4"
  "$NODE" -e '
    const fs = require("node:fs");
    const [file, version, port, pid, startedAt, injector, node, nodeVersion, bundle, exe, appVersion, bundleId, teamId, root, themeDir, appPid, arch] = process.argv.slice(1);
    const state = {
      schemaVersion: 1,
      platform: `darwin-${arch}`,
      skinVersion: version,
      port: Number(port),
      injectorPid: Number(pid),
      injectorStartedAt: startedAt,
      injectorPath: injector,
      nodePath: node,
      nodeVersion,
      traeBundle: bundle,
      traeExe: exe,
      traeVersion: appVersion,
      traeBundleId: bundleId,
      traeTeamId: teamId,
      traePid: Number(appPid || 0),
      projectRoot: root,
      themeDir,
      createdAt: new Date().toISOString()
    };
    const temporary = `${file}.${process.pid}.tmp`;
    fs.writeFileSync(temporary, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600 });
    fs.renameSync(temporary, file);
  ' "$STATE_PATH" "$SKIN_VERSION" "$port" "$injector_pid" "$injector_started_at" "$INJECTOR" "$NODE" "$NODE_VERSION" "$TRAE_BUNDLE" "$TRAE_EXE" "$TRAE_VERSION" "$TRAE_BUNDLE_ID" "$TRAE_TEAM_ID" "$PROJECT_ROOT" "$THEME_DIR" "$trae_pid" "$(/usr/bin/uname -m)"
}

stop_recorded_injector() {
  [ -f "$STATE_PATH" ] || return 0
  local pid
  local saved_start
  local saved_injector
  local actual_start
  local command_line

  pid="$(state_field injectorPid 2>/dev/null || true)"
  if [ -z "${pid:-}" ] || [ "$pid" = "0" ]; then return 0; fi
  /bin/kill -0 "$pid" 2>/dev/null || return 0

  saved_start="$(state_field injectorStartedAt 2>/dev/null || true)"
  saved_injector="$(state_field injectorPath 2>/dev/null || true)"
  command_line="$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)"
  case "$command_line" in
    *injector.mjs*--watch*) ;;
    *) return 0 ;;
  esac
  if [ -n "$saved_injector" ]; then
    case "$command_line" in *"$saved_injector"*) ;; *) return 0 ;; esac
  fi
  if [ -n "$saved_start" ]; then
    actual_start="$(process_started_at "$pid")"
    [ -z "$actual_start" ] || [ "$actual_start" = "$saved_start" ] || return 0
  fi

  /bin/kill -TERM "$pid" 2>/dev/null || true
  local deadline=$((SECONDS + 6))
  while /bin/kill -0 "$pid" 2>/dev/null && [ "$SECONDS" -lt "$deadline" ]; do /bin/sleep 0.2; done
  /bin/kill -KILL "$pid" 2>/dev/null || true
}

launch_injector_daemon() {
  local port="$1"
  local pid
  : > "$INJECTOR_LOG"
  : > "$INJECTOR_ERROR_LOG"
  /usr/bin/nohup "$NODE" "$INJECTOR" --watch --port "$port" --theme-dir "$THEME_DIR" \
    >>"$INJECTOR_LOG" 2>>"$INJECTOR_ERROR_LOG" &
  pid="$!"
  /bin/sleep 0.5
  /bin/kill -0 "$pid" 2>/dev/null || fail "The injector exited during startup. See $INJECTOR_ERROR_LOG"
  printf '%s\n' "$pid"
}

hot_reapply_theme() {
  local port="${1:-9355}"
  local timeout_ms="${2:-10000}"
  local injector_pid
  local started_at
  local trae_pid

  verified_cdp_endpoint "$port" || return 1
  stop_recorded_injector 2>/dev/null || true
  injector_pid="$(launch_injector_daemon "$port")"
  if ! "$NODE" "$INJECTOR" --once --port "$port" --theme-dir "$THEME_DIR" --timeout-ms "$timeout_ms" >/dev/null; then
    /bin/kill -TERM "$injector_pid" 2>/dev/null || true
    return 1
  fi
  started_at="$(process_started_at "$injector_pid")"
  trae_pid="$(trae_main_pids | /usr/bin/head -n 1)"
  write_state "$port" "$injector_pid" "${started_at:-unknown}" "${trae_pid:-0}"
  return 0
}

launch_trae_with_cdp() {
  local port="$1"
  : > "$APP_LOG"
  : > "$APP_ERROR_LOG"
  /usr/bin/open -na "$TRAE_BUNDLE" --args \
    --remote-debugging-address=127.0.0.1 \
    --remote-debugging-port="$port" \
    >>"$APP_LOG" 2>>"$APP_ERROR_LOG"
}

launch_trae_normally() {
  /usr/bin/open -na "$TRAE_BUNDLE"
}
