#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

IMAGE=""
THEME_NAME=""
TAGLINE=""
QUOTE=""
ACCENT="#e25563"
SECONDARY="#36b8c8"
HIGHLIGHT="#f3c96a"
APPLY_NOW="true"
RESET_DEMO="false"
PRESET=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image) IMAGE="${2:-}"; shift 2 ;;
    --name) THEME_NAME="${2:-}"; shift 2 ;;
    --tagline) TAGLINE="${2:-}"; shift 2 ;;
    --quote) QUOTE="${2:-}"; shift 2 ;;
    --accent) ACCENT="${2:-}"; shift 2 ;;
    --secondary) SECONDARY="${2:-}"; shift 2 ;;
    --highlight) HIGHLIGHT="${2:-}"; shift 2 ;;
    --preset) PRESET="${2:-}"; shift 2 ;;
    --no-apply) APPLY_NOW="false"; shift ;;
    --reset-demo) RESET_DEMO="true"; shift ;;
    *) fail "Unknown customize argument: $1" ;;
  esac
done

discover_trae_app
require_macos_runtime
ensure_state_root

if [ "$RESET_DEMO" = "true" ] && [ -n "$PRESET" ]; then
  fail "Choose either --reset-demo or --preset, not both."
fi

if [ -n "$PRESET" ]; then
  "$NODE" "$SCRIPT_DIR/write-theme.mjs" preset \
    --preset "$PRESET" \
    --output-dir "$THEME_DIR"
elif [ "$RESET_DEMO" = "true" ]; then
  "$NODE" "$SCRIPT_DIR/write-theme.mjs" reset-demo --output-dir "$THEME_DIR"
else
  if [ -z "$IMAGE" ]; then
    IMAGE="$(/usr/bin/osascript -e 'POSIX path of (choose file with prompt "选择一张 TRAE Work 主题图片（建议横向、宽度 2000px 以上）" of type {"public.image"})')" \
      || fail "Image selection was cancelled."
  fi
  [ -f "$IMAGE" ] || fail "Selected image does not exist: $IMAGE"
  SOURCE_BYTES="$(/usr/bin/stat -f '%z' "$IMAGE")"
  [ "$SOURCE_BYTES" -le 52428800 ] || fail "Selected image is larger than 50 MB."

  if [ -z "$THEME_NAME" ]; then
    THEME_NAME="$(/usr/bin/osascript -e 'text returned of (display dialog "给这套 TRAE Work 主题起个名字" default answer "我的 TRAE 主题" buttons {"取消", "继续"} default button "继续")')" \
      || fail "Theme setup was cancelled."
  fi
  [ -n "$TAGLINE" ] || TAGLINE="敲下一个任务，让灵感开始流动。"
  [ -n "$QUOTE" ] || QUOTE="MAKE SOMETHING WONDERFUL"

  /bin/mkdir -p "$THEME_DIR"
  /bin/chmod 700 "$THEME_DIR"
  image_name="background-$(/bin/date '+%Y%m%d-%H%M%S')-$$.jpg"
  temporary="$THEME_DIR/.${image_name}.tmp.jpg"
  prepared="$THEME_DIR/$image_name"
  cleanup_temporary() { /bin/rm -f "$temporary"; }
  trap cleanup_temporary EXIT
  /usr/bin/sips -s format jpeg -s formatOptions 84 -Z 3200 "$IMAGE" --out "$temporary" >/dev/null \
    || fail "macOS could not convert the selected image. Use PNG, JPEG, HEIC, TIFF, or WebP."
  [ -s "$temporary" ] || fail "The converted image is empty."
  PREPARED_BYTES="$(/usr/bin/stat -f '%z' "$temporary")"
  [ "$PREPARED_BYTES" -le 16777216 ] || fail "The prepared image is larger than 16 MB."
  /bin/mv -f "$temporary" "$prepared"
  /bin/chmod 600 "$prepared"

  "$NODE" "$SCRIPT_DIR/write-theme.mjs" custom \
    --output-dir "$THEME_DIR" \
    --image "$image_name" \
    --name "$THEME_NAME" \
    --tagline "$TAGLINE" \
    --quote "$QUOTE" \
    --accent "$ACCENT" \
    --secondary "$SECONDARY" \
    --highlight "$HIGHLIGHT"
  /usr/bin/find "$THEME_DIR" -maxdepth 1 -type f -name 'background-*' ! -name "$image_name" -delete
  trap - EXIT
fi

if [ "$APPLY_NOW" = "true" ]; then
  PORT=9355
  if [ -f "$STATE_PATH" ]; then
    saved_port="$(state_field port 2>/dev/null || true)"
    [ -n "$saved_port" ] && PORT="$saved_port"
  fi
  if ! hot_reapply_theme "$PORT" 10000; then
    "$SCRIPT_DIR/start-dream-skin-macos.sh" --port "$PORT" --prompt-restart
  fi
fi

printf 'TRAE Work Dream Skin theme is ready.\n'
