#!/bin/bash
set -euo pipefail

STATE_ROOT="$HOME/Library/Application Support/DesktopSkinSessionGuard"
LABEL="local.desktop-skin-session-guard"

if /bin/launchctl print "gui/$(/usr/bin/id -u)/$LABEL" >/dev/null 2>&1; then
  printf 'guard: running\n'
else
  printf 'guard: not-running\n'
fi

if [ -e "$STATE_ROOT/trae-enabled" ]; then
  printf 'trae: enabled\n'
  if [ -s "$HOME/Library/Application Support/TraeWorkDreamSkinStudio/theme/theme.json" ]; then
    printf 'trae theme: installed\n'
  else
    printf 'trae theme: missing\n'
  fi
  printf 'trae recovery attempts: %s\n' "$(/usr/bin/grep -c 'recovering TRAE theme' "$STATE_ROOT/trae-session.log" 2>/dev/null || true)"
  printf 'trae recovery successes: %s\n' "$(/usr/bin/grep -Ec 'TRAE (hot )?recovery complete' "$STATE_ROOT/trae-session.log" 2>/dev/null || true)"
else
  printf 'trae: disabled\n'
fi

if [ -s "$STATE_ROOT/workbuddy-theme-path" ]; then
  printf 'workbuddy: enabled\n'
  printf 'workbuddy theme: %s\n' "$(/bin/cat "$STATE_ROOT/workbuddy-theme-path")"
  if [ -s "$(/bin/cat "$STATE_ROOT/workbuddy-theme-path")" ]; then
    printf 'workbuddy package: present\n'
  else
    printf 'workbuddy package: missing\n'
  fi
  printf 'workbuddy recovery attempts: %s\n' "$(/usr/bin/grep -c 'recovering WorkBuddy theme' "$STATE_ROOT/workbuddy-session.log" 2>/dev/null || true)"
  printf 'workbuddy recovery successes: %s\n' "$(/usr/bin/grep -c 'WorkBuddy recovery complete' "$STATE_ROOT/workbuddy-session.log" 2>/dev/null || true)"
else
  printf 'workbuddy: disabled\n'
fi
