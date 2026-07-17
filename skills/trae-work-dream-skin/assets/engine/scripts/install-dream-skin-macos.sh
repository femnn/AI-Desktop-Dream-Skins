#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

PORT=9355
CREATE_LAUNCHERS="true"
LAUNCH_AFTER_INSTALL="true"
IN_PLACE="false"
PRESET=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-}"; shift 2 ;;
    --preset) PRESET="${2:-}"; shift 2 ;;
    --no-launchers) CREATE_LAUNCHERS="false"; shift ;;
    --no-launch) LAUNCH_AFTER_INSTALL="false"; shift ;;
    --in-place) IN_PLACE="true"; shift ;;
    *) fail "Unknown installer argument: $1" ;;
  esac
done
case "$PORT" in ''|*[!0-9]*) fail "Invalid port: $PORT" ;; esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Port must be between 1024 and 65535."
case "$PRESET" in *[!A-Za-z0-9-]*) fail "Invalid preset: $PRESET" ;; esac

deploy_project() {
  local temporary="$INSTALL_ROOT.installing.$$"
  local previous="$INSTALL_ROOT.previous.$$"
  /bin/rm -rf "$temporary"
  /bin/mkdir -p "$temporary"
  /usr/bin/rsync -a \
    --exclude '.git/' \
    --exclude '.DS_Store' \
    --exclude 'release/' \
    "$PROJECT_ROOT/" "$temporary/"
  /bin/chmod 700 "$temporary"/*.command "$temporary"/scripts/*.sh "$temporary"/tests/*.sh 2>/dev/null || true
  if [ -e "$INSTALL_ROOT" ]; then /bin/mv "$INSTALL_ROOT" "$previous"; fi
  if ! /bin/mv "$temporary" "$INSTALL_ROOT"; then
    [ -e "$previous" ] && /bin/mv "$previous" "$INSTALL_ROOT"
    fail "Could not install the project at $INSTALL_ROOT"
  fi
  /bin/rm -rf "$previous"
}

if [ "$IN_PLACE" = "false" ] && [ "$PROJECT_ROOT" != "$INSTALL_ROOT" ]; then
  /bin/mkdir -p "$(dirname "$INSTALL_ROOT")"
  deploy_project
  install_args=(--in-place --port "$PORT")
  [ -z "$PRESET" ] || install_args+=(--preset "$PRESET")
  [ "$CREATE_LAUNCHERS" = "true" ] || install_args+=(--no-launchers)
  [ "$LAUNCH_AFTER_INSTALL" = "true" ] || install_args+=(--no-launch)
  exec "$INSTALL_ROOT/scripts/install-dream-skin-macos.sh" "${install_args[@]}"
fi

discover_trae_app
require_macos_runtime
ensure_state_root
[ -z "$PRESET" ] || "$NODE" "$SCRIPT_DIR/write-theme.mjs" preset \
  --preset "$PRESET" \
  --output-dir "$THEME_DIR"
"$NODE" "$INJECTOR" --check-payload --theme-dir "$THEME_DIR" >/dev/null

shell_quote() {
  "$NODE" -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

write_launcher() {
  local target="$1"
  local command="$2"
  if [ -e "$target" ] && ! /usr/bin/grep -q '^# TraeWorkDreamSkinStudio launcher$' "$target" 2>/dev/null; then
    fail "Refusing to overwrite an unrelated Desktop file: $target"
  fi
  /usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    '# TraeWorkDreamSkinStudio launcher' \
    'set -e' \
    "$command" > "$target"
  /bin/chmod 700 "$target"
}

if [ "$CREATE_LAUNCHERS" = "true" ]; then
  /bin/mkdir -p "$HOME/Desktop"
  start_script="$(shell_quote "$SCRIPT_DIR/start-dream-skin-macos.sh")"
  customize_script="$(shell_quote "$SCRIPT_DIR/customize-theme-macos.sh")"
  verify_script="$(shell_quote "$SCRIPT_DIR/verify-dream-skin-macos.sh")"
  restore_script="$(shell_quote "$SCRIPT_DIR/restore-dream-skin-macos.sh")"
  screenshot="$(shell_quote "$HOME/Desktop/TRAE Work Dream Skin Verification.png")"
  write_launcher "$HOME/Desktop/TRAE Work Dream Skin.command" "exec $start_script --port $PORT --prompt-restart"
  write_launcher "$HOME/Desktop/TRAE Work Dream Skin - Customize.command" "exec $customize_script"
  write_launcher "$HOME/Desktop/TRAE Work Dream Skin - Verify.command" "$verify_script --screenshot $screenshot && /usr/bin/open $screenshot"
  write_launcher "$HOME/Desktop/TRAE Work Dream Skin - Restore.command" "exec $restore_script --restart-trae"
fi

printf 'TRAE Work Dream Skin %s installed at %s for TRAE Work %s using its signed Electron/Node %s.\n' \
  "$SKIN_VERSION" "$PROJECT_ROOT" "$TRAE_VERSION" "$NODE_VERSION"
if [ "$CREATE_LAUNCHERS" = "true" ]; then
  printf 'Use the Desktop launchers to customize, start, verify, or restore the official appearance.\n'
else
  printf 'Desktop launchers were not created; use the project-local commands or installed scripts.\n'
fi

if [ "$LAUNCH_AFTER_INSTALL" = "true" ]; then
  "$SCRIPT_DIR/start-dream-skin-macos.sh" --port "$PORT" --prompt-restart
fi
