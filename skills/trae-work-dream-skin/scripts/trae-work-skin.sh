#!/bin/bash

set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
REPO_ENGINE="$(cd "$SKILL_ROOT/../.." 2>/dev/null && pwd -P)/macos"
BUNDLED_ENGINE="$SKILL_ROOT/assets/engine"
if [ -x "$REPO_ENGINE/scripts/install-dream-skin-macos.sh" ]; then
  ENGINE="$REPO_ENGINE"
else
  ENGINE="$BUNDLED_ENGINE"
fi
INSTALLED="$HOME/.trae/trae-work-dream-skin-studio"
PERSISTENCE_INSTALLER="$HOME/.codex/skills/desktop-skin-router/scripts/install_persistence_guard_macos.sh"

usage() {
  /usr/bin/printf '%s\n' \
    'Usage: trae-work-skin.sh <command> [options]' \
    '' \
    'Commands:' \
    '  doctor                         Check TRAE Work and the active skin' \
    '  test                           Validate the theme engine' \
    '  install [installer options]    Install and start the skin' \
    '  start                          Start or reapply the installed skin' \
    '  apply-preset <name>            Install and apply a bundled preset' \
    '  apply-default                  Return to Arcade Modern' \
    '  customize [customize options]  Choose an image or pass image/name/colors' \
    '  verify [screenshot path]       Verify and save a screenshot' \
    '  restore                        Restore the official appearance' \
    '  persist                        Restore the active theme after normal app launches' \
    '  build-zip <output> [preset]    Build a client ZIP' \
    '  scaffold <target directory>    Copy an editable engine project'
}

require_engine() {
  [ -x "$ENGINE/scripts/install-dream-skin-macos.sh" ] \
    || { /usr/bin/printf 'TRAE Work theme engine is incomplete: %s\n' "$ENGINE" >&2; exit 1; }
}

ensure_installed() {
  "$ENGINE/scripts/install-dream-skin-macos.sh" --no-launch
}

install_persistence() {
  [ -x "$PERSISTENCE_INSTALLER" ] || return 0
  "$PERSISTENCE_INSTALLER" --enable-trae
}

absolute_path() {
  case "$1" in
    /*) /usr/bin/printf '%s\n' "$1" ;;
    *) /usr/bin/printf '%s/%s\n' "$PWD" "$1" ;;
  esac
}

require_engine
COMMAND="${1:-help}"
[ "$#" -eq 0 ] || shift

case "$COMMAND" in
  doctor) "$ENGINE/scripts/doctor-macos.sh" ;;
  test) "$ENGINE/tests/run-tests.sh" ;;
  install) "$ENGINE/scripts/install-dream-skin-macos.sh" "$@"; install_persistence ;;
  start)
    ensure_installed
    "$INSTALLED/scripts/start-dream-skin-macos.sh" --prompt-restart
    install_persistence
    ;;
  apply-preset)
    PRESET="${1:-}"
    [ -n "$PRESET" ] || { /usr/bin/printf 'apply-preset requires a preset name.\n' >&2; exit 2; }
    "$ENGINE/scripts/install-dream-skin-macos.sh" --no-launch --preset "$PRESET"
    "$INSTALLED/scripts/customize-theme-macos.sh" --preset "$PRESET"
    install_persistence
    ;;
  apply-default)
    ensure_installed
    "$INSTALLED/scripts/customize-theme-macos.sh" --reset-demo
    install_persistence
    ;;
  customize)
    ensure_installed
    "$INSTALLED/scripts/customize-theme-macos.sh" "$@"
    install_persistence
    ;;
  verify)
    OUTPUT="$(absolute_path "${1:-TRAE Work Dream Skin Verification.png}")"
    "$INSTALLED/scripts/verify-dream-skin-macos.sh" --screenshot "$OUTPUT"
    /usr/bin/printf 'Screenshot: %s\n' "$OUTPUT"
    ;;
  restore)
    [ -x "$INSTALLED/scripts/restore-dream-skin-macos.sh" ] \
      || { /usr/bin/printf 'TRAE Work Dream Skin is not installed.\n' >&2; exit 1; }
    "$INSTALLED/scripts/restore-dream-skin-macos.sh" --restart-trae
    ;;
  persist)
    [ -x "$PERSISTENCE_INSTALLER" ] \
      || { /usr/bin/printf 'Desktop skin persistence installer is unavailable.\n' >&2; exit 1; }
    "$PERSISTENCE_INSTALLER" --enable-trae
    ;;
  build-zip)
    OUTPUT="${1:-}"
    PRESET="${2:-}"
    [ -n "$OUTPUT" ] || { /usr/bin/printf 'build-zip requires an output path.\n' >&2; exit 2; }
    "$ENGINE/scripts/build-client-release.sh" "$(absolute_path "$OUTPUT")" "$PRESET"
    ;;
  scaffold)
    TARGET="${1:-}"
    [ -n "$TARGET" ] || { /usr/bin/printf 'scaffold requires a target directory.\n' >&2; exit 2; }
    TARGET="$(absolute_path "$TARGET")"
    [ ! -e "$TARGET" ] || { /usr/bin/printf 'Refusing to overwrite existing path: %s\n' "$TARGET" >&2; exit 1; }
    /usr/bin/ditto "$ENGINE" "$TARGET"
    /usr/bin/printf 'Created editable TRAE Work theme project: %s\n' "$TARGET"
    ;;
  help|-h|--help) usage ;;
  *)
    /usr/bin/printf 'Unknown command: %s\n\n' "$COMMAND" >&2
    usage >&2
    exit 2
    ;;
esac
