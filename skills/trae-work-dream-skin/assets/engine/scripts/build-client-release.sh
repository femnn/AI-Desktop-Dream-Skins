#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
VERSION="$(/usr/bin/tr -d '[:space:]' < "$ROOT/VERSION")"
OUTPUT="${1:-$HOME/Desktop/TRAE Work Dream Skin $VERSION.zip}"
PRESET="${2:-}"
case "$PRESET" in *[!A-Za-z0-9-]*) printf 'Invalid preset: %s\n' "$PRESET" >&2; exit 1 ;; esac
TMP="$(/usr/bin/mktemp -d /tmp/trae-work-dream-skin-client.XXXXXX)"
CLIENT_ROOT="$TMP/TRAE Work Dream Skin"
ENGINE="$CLIENT_ROOT/.trae-work-dream-skin-studio"
trap '/bin/rm -rf "$TMP"' EXIT
INSTALL_COMMAND='exec "$ROOT/.trae-work-dream-skin-studio/scripts/install-dream-skin-macos.sh"'
[ -z "$PRESET" ] || INSTALL_COMMAND="$INSTALL_COMMAND --preset \"$PRESET\""

"$ROOT/tests/run-tests.sh"
/bin/mkdir -p "$ENGINE"
/usr/bin/rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude '._*' \
  --exclude 'agents/' \
  --exclude 'client-delivery/' \
  --exclude 'menubar/' \
  --exclude 'release/' \
  "$ROOT/" "$ENGINE/"

/usr/bin/printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'ROOT="$(cd "$(dirname "$0")" && pwd -P)"' \
  "$INSTALL_COMMAND" \
  > "$CLIENT_ROOT/安装 TRAE Work Dream Skin.command"

/usr/bin/printf '%s\n' \
  "TRAE Work Dream Skin $VERSION" \
  '' \
  '双击“安装 TRAE Work Dream Skin.command”。' \
  '安装后，桌面会出现启动、定制、验证和恢复四个入口。' \
  "$([ -z "$PRESET" ] || printf '安装器会自动启用预设：%s。' "$PRESET")" \
  '' \
  '不要只复制图片或 CSS；隐藏目录是完整运行引擎。' \
  > "$CLIENT_ROOT/使用说明.txt"

/bin/chmod 755 "$CLIENT_ROOT/安装 TRAE Work Dream Skin.command"
/bin/chmod 755 "$ENGINE"/*.command "$ENGINE"/scripts/*.sh "$ENGINE"/tests/*.sh
/usr/bin/xattr -cr "$CLIENT_ROOT"
/usr/bin/find "$CLIENT_ROOT" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/mkdir -p "$(dirname "$OUTPUT")"
/bin/rm -f "$OUTPUT"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$CLIENT_ROOT" "$OUTPUT"
SHA256="$(/usr/bin/shasum -a 256 "$OUTPUT" | /usr/bin/awk '{print $1}')"
/usr/bin/printf 'Created %s\nSHA-256 %s\n' "$OUTPUT" "$SHA256"
