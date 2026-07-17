#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
COMMON="$ROOT/scripts/common-macos.sh"

. "$COMMON"
discover_trae_app
require_macos_runtime

CORE_SHELL_FILES=(
  "$ROOT/scripts/common-macos.sh"
  "$ROOT/scripts/trae-runtime-node-macos.sh"
  "$ROOT/scripts/install-dream-skin-macos.sh"
  "$ROOT/scripts/start-dream-skin-macos.sh"
  "$ROOT/scripts/customize-theme-macos.sh"
  "$ROOT/scripts/verify-dream-skin-macos.sh"
  "$ROOT/scripts/restore-dream-skin-macos.sh"
  "$ROOT/scripts/doctor-macos.sh"
  "$ROOT/scripts/build-release.sh"
  "$ROOT/scripts/build-client-release.sh"
  "$ROOT/Install TRAE Work Dream Skin.command"
  "$ROOT/Start TRAE Work Dream Skin.command"
  "$ROOT/Customize TRAE Work Dream Skin.command"
  "$ROOT/Verify TRAE Work Dream Skin.command"
  "$ROOT/Restore TRAE Work Dream Skin.command"
)

for file in "${CORE_SHELL_FILES[@]}"; do
  [ -s "$file" ] || fail "Required test input is missing: $file"
  /bin/bash -n "$file"
done

for file in \
  "$ROOT/scripts/injector.mjs" \
  "$ROOT/scripts/write-theme.mjs" \
  "$ROOT/assets/renderer-inject.js"
do
  "$NODE" --check "$file" >/dev/null
done

if /usr/bin/grep -R -n -E '(writeFile|rename|copyFile|rm|cp|mv).*app\.asar' \
  "$ROOT/scripts" "$ROOT/assets" >/dev/null; then
  fail "A runtime script appears to mutate app.asar."
fi

/usr/bin/grep -q 'solo-lite.html' "$ROOT/scripts/injector.mjs"
/usr/bin/grep -q '#solo-lite-root' "$ROOT/scripts/injector.mjs"
/usr/bin/grep -q ':scope > div' "$ROOT/scripts/injector.mjs"
/usr/bin/grep -q 'pointer-events: none' "$ROOT/assets/dream-skin.css"
/usr/bin/grep -q 'data-trae-dream-theme' "$ROOT/assets/renderer-inject.js"
/usr/bin/grep -q 'cn.trae.solo.app' "$ROOT/scripts/common-macos.sh"
/usr/bin/grep -q 'TRAE SOLO CN.app' "$ROOT/scripts/trae-runtime-node-macos.sh"
/usr/bin/grep -q 'CG2SCM6AV5' "$ROOT/scripts/common-macos.sh"
/usr/bin/grep -q 'trae-portal-demo' "$ROOT/assets/theme.json"
[ -s "$ROOT/assets/portal-hero.png" ]
[ -s "$ROOT/presets/pixel-8bit/theme.json" ]
[ -s "$ROOT/presets/pixel-8bit/pixel-8bit-demo.png" ]
[ -s "$ROOT/presets/electric-forest/theme.json" ]
[ -s "$ROOT/presets/electric-forest/electric-forest-demo.png" ]
[ -s "$ROOT/presets/sky-friends/theme.json" ]
[ -s "$ROOT/presets/sky-friends/sky-friends-demo.png" ]
[ -s "$ROOT/presets/retro-2007/theme.json" ]
[ -s "$ROOT/presets/retro-2007/retro-2007-demo.png" ]
[ -s "$ROOT/presets/xbox-series-xs/theme.json" ]
[ -s "$ROOT/presets/xbox-series-xs/xbox-series-xs-hero.png" ]

DEFAULT_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload)"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass || value.themeId !== "trae-portal-demo" || value.themeName !== "TRAE PORTAL" || value.visualStyle !== "arcade-modern" || value.imageBytes < 1) process.exit(1);
' "$DEFAULT_PAYLOAD_JSON"

TMP="$(/usr/bin/mktemp -d /tmp/trae-work-dream-skin-tests.XXXXXX)"
trap '/bin/rm -rf "$TMP"' EXIT
/bin/mkdir -p "$TMP/theme"
/bin/cp "$ROOT/assets/portal-hero.png" "$TMP/theme/background.png"
"$NODE" "$ROOT/scripts/write-theme.mjs" custom \
  --output-dir "$TMP/theme" \
  --image background.png \
  --name '测试 TRAE 主题' \
  --tagline '测试口号' \
  --quote 'TEST WORK' \
  --accent '#e25563' \
  --secondary '#f3a8af' \
  --highlight '#c93d4c' >/dev/null
PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass || value.themeName !== "测试 TRAE 主题" || value.imageBytes < 1) process.exit(1);
' "$PAYLOAD_JSON"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

"$NODE" "$ROOT/scripts/write-theme.mjs" preset \
  --preset xbox-series-xs \
  --output-dir "$TMP/theme" >/dev/null
XBOX_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass ||
      value.themeId !== "xbox-series-xs" ||
      value.themeName !== "XBOX SERIES X|S · POWER LAB" ||
      value.visualStyle !== "xbox-series-xs" ||
      value.imageBytes < 1) process.exit(1);
' "$XBOX_PAYLOAD_JSON"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

"$NODE" "$ROOT/scripts/write-theme.mjs" preset \
  --preset pixel-8bit \
  --output-dir "$TMP/theme" >/dev/null
PRESET_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass ||
      value.themeId !== "pixel-8bit" ||
      value.themeName !== "PIXEL WORK 8-BIT" ||
      value.visualStyle !== "pixel-8bit" ||
      value.imageBytes < 1) process.exit(1);
' "$PRESET_PAYLOAD_JSON"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

"$NODE" "$ROOT/scripts/write-theme.mjs" preset \
  --preset electric-forest \
  --output-dir "$TMP/theme" >/dev/null
FOREST_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass ||
      value.themeId !== "electric-forest" ||
      value.themeName !== "ELECTRIC FOREST" ||
      value.visualStyle !== "electric-forest" ||
      value.imageBytes < 1) process.exit(1);
' "$FOREST_PAYLOAD_JSON"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

"$NODE" "$ROOT/scripts/write-theme.mjs" preset \
  --preset sky-friends \
  --output-dir "$TMP/theme" >/dev/null
SKY_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass ||
      value.themeId !== "sky-friends" ||
      value.themeName !== "SKY FRIENDS" ||
      value.visualStyle !== "sky-friends" ||
      value.imageBytes < 1) process.exit(1);
' "$SKY_PAYLOAD_JSON"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

"$NODE" "$ROOT/scripts/write-theme.mjs" preset \
  --preset retro-2007 \
  --output-dir "$TMP/theme" >/dev/null
RETRO_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass ||
      value.themeId !== "retro-2007" ||
      value.themeName !== "RETRO WORK 2007" ||
      value.visualStyle !== "retro-2007" ||
      value.imageBytes < 1) process.exit(1);
' "$RETRO_PAYLOAD_JSON"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

/usr/bin/env -u HOME /bin/bash -c '. "$1/scripts/common-macos.sh"; [ -n "$HOME" ] && [ "$SKIN_VERSION" = "0.2.0" ]' _ "$ROOT"
"$ROOT/scripts/doctor-macos.sh" >/dev/null

printf 'PASS: shell/JavaScript syntax, signed TRAE runtime, payload, custom and preset themes, renderer guard, HOME recovery, and doctor checks.\n'
