#!/bin/bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
STATE_ROOT="$HOME/Library/Application Support/DesktopSkinSessionGuard"
AGENT="$HOME/Library/LaunchAgents/local.desktop-skin-session-guard.plist"
LABEL="local.desktop-skin-session-guard"
SOURCE="$SKILL_DIR/assets/DesktopSkinSessionGuard.m"
BINARY="$STATE_ROOT/DesktopSkinSessionGuard"
DISPATCHER="$STATE_ROOT/desktop-skin-session-dispatcher.sh"
ENABLE_TRAE="false"
WORKBUDDY_THEME=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --enable-trae) ENABLE_TRAE="true"; shift ;;
    --workbuddy-theme) WORKBUDDY_THEME="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[ "$(/usr/bin/uname -s)" = "Darwin" ] || { printf 'macOS only.\n' >&2; exit 2; }
if [ -n "$WORKBUDDY_THEME" ]; then
  case "$WORKBUDDY_THEME" in /*) ;; *) printf 'WorkBuddy theme path must be absolute.\n' >&2; exit 2 ;; esac
  [ -s "$WORKBUDDY_THEME" ] || { printf 'WorkBuddy theme is missing: %s\n' "$WORKBUDDY_THEME" >&2; exit 2; }
fi

/bin/mkdir -p "$STATE_ROOT" "$HOME/Library/LaunchAgents"
/usr/bin/clang -fobjc-arc -framework Cocoa "$SOURCE" -o "$BINARY"
/usr/bin/install -m 700 "$SKILL_DIR/scripts/desktop-skin-session-dispatcher.sh" "$DISPATCHER"
/usr/bin/install -m 700 "$SKILL_DIR/scripts/ensure-trae-session.sh" "$STATE_ROOT/ensure-trae-session.sh"
/usr/bin/install -m 700 "$SKILL_DIR/scripts/ensure-workbuddy-session.sh" "$STATE_ROOT/ensure-workbuddy-session.sh"
[ "$ENABLE_TRAE" = "false" ] || /usr/bin/touch "$STATE_ROOT/trae-enabled"
[ -z "$WORKBUDDY_THEME" ] || /usr/bin/printf '%s\n' "$WORKBUDDY_THEME" >"$STATE_ROOT/workbuddy-theme-path"

/bin/launchctl bootout "gui/$(/usr/bin/id -u)/$LABEL" >/dev/null 2>&1 || true
/bin/rm -f "$AGENT"
/usr/libexec/PlistBuddy -c "Add :Label string $LABEL" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments array" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $BINARY" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:1 string $DISPATCHER" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :RunAtLoad bool true" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :KeepAlive bool true" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :ProcessType string Background" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :StandardOutPath string $STATE_ROOT/guard-output.log" "$AGENT"
/usr/libexec/PlistBuddy -c "Add :StandardErrorPath string $STATE_ROOT/guard-error.log" "$AGENT"
/bin/chmod 600 "$AGENT"
/bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$AGENT"
/bin/launchctl enable "gui/$(/usr/bin/id -u)/$LABEL"
/bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/$LABEL"

printf 'Installed event-driven desktop skin persistence guard.\n'
