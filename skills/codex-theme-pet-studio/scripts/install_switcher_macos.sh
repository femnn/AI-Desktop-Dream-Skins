#!/bin/bash

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
PROJECT_HOME="${CODEX_THEME_PROJECT_HOME:-$HOME/Documents/Codex/2026-07-16/codex-codex-imagen}"
DEST="$PROJECT_HOME/launchers/Codex 主题套装.command"
/bin/mkdir -p "$(/usr/bin/dirname "$DEST")"
TMP="${DEST}.tmp.$$"
{
  printf '%s\n' '#!/bin/bash'
  printf 'exec /bin/bash %q\n' "$SKILL_DIR/scripts/choose_pack_macos.sh"
} >"$TMP"
chmod 755 "$TMP"
mv "$TMP" "$DEST"
printf 'Installed: %s\n' "$DEST"
