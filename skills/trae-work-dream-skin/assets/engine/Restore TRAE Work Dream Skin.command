#!/bin/bash
set -euo pipefail
INSTALLED="$HOME/.trae/trae-work-dream-skin-studio/scripts/restore-dream-skin-macos.sh"
if [ ! -x "$INSTALLED" ]; then
  /usr/bin/osascript -e 'display alert "没有找到已安装的 TRAE Work Dream Skin Studio。" as warning' >/dev/null
  exit 1
fi
exec "$INSTALLED" --restart-trae
