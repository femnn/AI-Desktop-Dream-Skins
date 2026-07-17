#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TARGET="$HOME/.codex/skills"
STAMP="$(/bin/date '+%Y%m%d-%H%M%S')"
BACKUP="$HOME/.codex/skill-backups/desktop-dream-skins-$STAMP"
SKILLS=(desktop-skin-router codex-theme-pet-studio hatch-pet workbuddy-theme-studio trae-work-dream-skin)

[ "$(/usr/bin/uname -s)" = "Darwin" ] || { printf 'macOS only.\n' >&2; exit 2; }
/bin/mkdir -p "$TARGET" "$BACKUP"

for skill in "${SKILLS[@]}"; do
  [ -d "$ROOT/skills/$skill" ] || { printf 'Missing bundled Skill: %s\n' "$skill" >&2; exit 1; }
  if [ -e "$TARGET/$skill" ]; then
    /usr/bin/ditto "$TARGET/$skill" "$BACKUP/$skill"
  fi
  /bin/mkdir -p "$TARGET/$skill"
  /usr/bin/ditto "$ROOT/skills/$skill" "$TARGET/$skill"
done

/usr/bin/find "$TARGET/desktop-skin-router/scripts" "$TARGET/codex-theme-pet-studio/scripts" \
  "$TARGET/workbuddy-theme-studio/scripts" "$TARGET/trae-work-dream-skin/scripts" \
  -type f \( -name '*.sh' -o -name '*.py' \) -exec /bin/chmod 700 {} +

/usr/bin/python3 "$TARGET/codex-theme-pet-studio/scripts/install_pack.py" \
  "$ROOT/themes/codex/astro-bot"

"$TARGET/codex-theme-pet-studio/scripts/install_session_guard_macos.sh"

"$TARGET/desktop-skin-router/scripts/install_persistence_guard_macos.sh" \
  --enable-trae \
  --workbuddy-theme "$ROOT/themes/workbuddy/switch2-adventure/switch2-adventure-1.2.1.codedrobe-theme"

printf 'Installed Skills. Backup: %s\n' "$BACKUP"
printf 'No foreground application was restarted. Read docs/STARTUP-GUIDE.zh-CN.md before activation.\n'
