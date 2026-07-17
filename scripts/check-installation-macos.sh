#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SKILLS="$HOME/.codex/skills"
FAILED=0

check_file() {
  if [ -s "$1" ]; then
    printf 'PASS  %s\n' "$2"
  else
    printf 'FAIL  %s (%s)\n' "$2" "$1"
    FAILED=1
  fi
}

check_file "$SKILLS/desktop-skin-router/SKILL.md" 'desktop-skin-router Skill'
check_file "$SKILLS/codex-theme-pet-studio/SKILL.md" 'Codex Skill'
check_file "$SKILLS/workbuddy-theme-studio/SKILL.md" 'WorkBuddy Skill'
check_file "$SKILLS/trae-work-dream-skin/SKILL.md" 'TRAE Skill'
check_file "$ROOT/themes/codex/astro-bot/pack.json" 'Codex ASTRO BOT pack'
check_file "$ROOT/themes/workbuddy/switch2-adventure/switch2-adventure-1.2.1.codedrobe-theme" 'WorkBuddy Switch 2 package'
check_file "$ROOT/themes/trae/xbox-series-xs/theme.json" 'TRAE Xbox preset'

if [ -x "$SKILLS/desktop-skin-router/scripts/status_persistence_guard_macos.sh" ]; then
  printf '\nPersistence guard:\n'
  "$SKILLS/desktop-skin-router/scripts/status_persistence_guard_macos.sh"
else
  printf 'FAIL  persistence status script\n'
  FAILED=1
fi

exit "$FAILED"
