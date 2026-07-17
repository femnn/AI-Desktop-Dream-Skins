#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

REQUIRE_LIVE="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --require-live) REQUIRE_LIVE="true"; shift ;;
    *) fail "Unknown doctor argument: $1" ;;
  esac
done

discover_trae_app
require_macos_runtime
for required in \
  "$PROJECT_ROOT/assets/dream-skin.css" \
  "$PROJECT_ROOT/assets/renderer-inject.js" \
  "$PROJECT_ROOT/assets/theme.json" \
  "$PROJECT_ROOT/assets/portal-hero.png" \
  "$PROJECT_ROOT/scripts/injector.mjs" \
  "$PROJECT_ROOT/scripts/trae-runtime-node-macos.sh"
do
  [ -s "$required" ] || fail "Required project file is missing or empty: $required"
done

PAYLOAD_JSON="$("$NODE" "$INJECTOR" --check-payload --theme-dir "$THEME_DIR")"
PORT=9355
if [ -f "$STATE_PATH" ]; then PORT="$(state_field port)"; fi
LIVE="false"
if [ -f "$STATE_PATH" ] && verified_cdp_endpoint "$PORT"; then
  if "$NODE" "$INJECTOR" --verify --port "$PORT" --theme-dir "$THEME_DIR" --timeout-ms 12000 >/dev/null 2>&1; then
    LIVE="true"
  fi
fi
[ "$REQUIRE_LIVE" = "false" ] || [ "$LIVE" = "true" ] || fail "No verified live Dream Skin session is active."

"$NODE" -e '
  const payload = JSON.parse(process.argv[1]);
  const result = {
    pass: true,
    product: "TRAE Work Dream Skin Studio",
    version: process.argv[2],
    platform: `darwin-${process.argv[3]}`,
    traeVersion: process.argv[4],
    traeBundleId: process.argv[5],
    traeTeamId: process.argv[6],
    nodeVersion: process.argv[7],
    officialAppSignatureValid: true,
    modifiesOfficialApp: false,
    live: process.argv[8] === "true",
    port: Number(process.argv[9]),
    theme: {
      id: payload.themeId,
      name: payload.themeName,
      imageBytes: payload.imageBytes,
      payloadBytes: payload.payloadBytes,
    },
  };
  console.log(JSON.stringify(result, null, 2));
' "$PAYLOAD_JSON" "$SKIN_VERSION" "$(/usr/bin/uname -m)" "$TRAE_VERSION" "$TRAE_BUNDLE_ID" "$TRAE_TEAM_ID" "$NODE_VERSION" "$LIVE" "$PORT"
