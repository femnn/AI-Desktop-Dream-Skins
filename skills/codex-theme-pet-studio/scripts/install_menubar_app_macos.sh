#!/bin/bash

set -euo pipefail
NO_LAUNCH="false"
if [ "${1:-}" = "--no-launch" ]; then
  NO_LAUNCH="true"
elif [ "$#" -gt 0 ]; then
  printf 'Usage: install_menubar_app_macos.sh [--no-launch]\n' >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
SOURCE="$SKILL_DIR/assets/ThemePackMenuBar.m"
APP="$HOME/Applications/Codex Theme Packs.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
EXECUTABLE="$MACOS/CodexThemePacks"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/local.codex.theme-packs.plist"
TMP="$(mktemp -d /tmp/codex-theme-pack-menubar.XXXXXX)"
trap 'find "$TMP" -depth -delete 2>/dev/null || true' EXIT

CLANG="$(xcrun --find clang)"
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
"$CLANG" -fobjc-arc -O2 -isysroot "$SDKROOT" -mmacosx-version-min=13.0 \
  -framework Cocoa "$SOURCE" -o "$TMP/CodexThemePacks"
mkdir -p "$MACOS"
cp "$TMP/CodexThemePacks" "$EXECUTABLE"
chmod 755 "$EXECUTABLE"

/usr/bin/python3 - "$CONTENTS/Info.plist" <<'PY'
import plistlib, sys
value = {
    "CFBundleDevelopmentRegion": "zh_CN",
    "CFBundleExecutable": "CodexThemePacks",
    "CFBundleIdentifier": "local.codex.theme-packs",
    "CFBundleInfoDictionaryVersion": "6.0",
    "CFBundleName": "Codex Theme Packs",
    "CFBundlePackageType": "APPL",
    "CFBundleShortVersionString": "1.0.0",
    "CFBundleVersion": "1",
    "CFBundleURLTypes": [{
        "CFBundleURLName": "local.codex.theme-packs",
        "CFBundleURLSchemes": ["codex-theme-packs"],
    }],
    "LSMinimumSystemVersion": "13.0",
    "LSUIElement": True,
}
with open(sys.argv[1], "wb") as handle:
    plistlib.dump(value, handle)
PY

/usr/bin/codesign --force --sign - "$APP" >/dev/null
/usr/bin/python3 - "$LAUNCH_AGENT" "$EXECUTABLE" <<'PY'
import os, plistlib, sys
path, executable = sys.argv[1:]
os.makedirs(os.path.dirname(path), exist_ok=True)
value = {
    "Label": "local.codex.theme-packs",
    "ProgramArguments": [executable],
    "RunAtLoad": True,
    "KeepAlive": False,
}
with open(path, "wb") as handle:
    plistlib.dump(value, handle)
PY
/bin/launchctl bootout "gui/$(id -u)/local.codex.theme-packs" >/dev/null 2>&1 || true
/usr/bin/pkill -f "$EXECUTABLE" >/dev/null 2>&1 || true
if [ "$NO_LAUNCH" = "false" ]; then
  /bin/launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
  for _ in 1 2 3 4 5; do
    if /usr/bin/pgrep -f "$EXECUTABLE" >/dev/null 2>&1; then break; fi
    /bin/sleep 0.4
  done
  if ! /usr/bin/pgrep -f "$EXECUTABLE" >/dev/null 2>&1; then
    /usr/bin/open -a "$APP"
  fi
  printf 'Installed and launched: %s\n' "$APP"
else
  printf 'Installed without launching: %s\n' "$APP"
fi
