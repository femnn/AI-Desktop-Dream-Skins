#!/bin/bash

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
LEGACY_PLIST="$HOME/Library/LaunchAgents/local.codex.theme-pack-session.plist"

# Older builds polled every five seconds. Remove that job permanently; the
# native menu app now observes the single ChatGPT launch event instead.
/bin/launchctl bootout "gui/$(id -u)/local.codex.theme-pack-session" >/dev/null 2>&1 || true
if [ -e "$LEGACY_PLIST" ]; then
  /usr/bin/find "$LEGACY_PLIST" -delete
fi

/bin/bash "$SKILL_DIR/scripts/install_menubar_app_macos.sh"
printf 'Installed event-driven session restore in Codex Theme Packs.app\n'
