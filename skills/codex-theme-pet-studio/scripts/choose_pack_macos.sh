#!/bin/bash

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
PYTHON="${CODEX_THEME_PACK_PYTHON:-/Users/kangkang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3}"
LIST="$("$PYTHON" "$SKILL_DIR/scripts/list_packs.py" --format lines)"
[ -n "$LIST" ] || { /usr/bin/osascript -e 'display alert "Codex 主题套装" message "还没有已安装的主题套装。"' >/dev/null; exit 1; }

OPTIONS="$(printf '%s\n' "$LIST" | /usr/bin/awk -F '\t' '{print $2 " 〔" $1 "〕"}')"
choose_pack() {
  /usr/bin/osascript - "$OPTIONS" <<'APPLESCRIPT'
on run argv
  set rawOptions to item 1 of argv
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to linefeed
  set choices to text items of rawOptions
  set AppleScript's text item delimiters to oldDelimiters
  set picked to choose from list choices with title "Codex 主题套装" with prompt "选择要同时启用的界面和宠物：" OK button name "一键切换" cancel button name "取消"
  if picked is false then error number -128
  return item 1 of picked
end run
APPLESCRIPT
}
CHOSEN="$(choose_pack)" || exit 0

PACK_ID="$(printf '%s' "$CHOSEN" | /usr/bin/sed -E 's/^.*〔([^〕]+)〕$/\1/')"
exec /bin/bash "$SKILL_DIR/scripts/switch_pack_macos.sh" --id "$PACK_ID"
