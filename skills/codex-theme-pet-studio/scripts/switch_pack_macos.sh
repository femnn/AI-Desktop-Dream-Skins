#!/bin/bash

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
ENGINE="${CODEX_DREAM_SKIN_ENGINE:-$HOME/.codex/codex-dream-skin-studio}"
COMMON="$ENGINE/scripts/common-macos.sh"
DEFAULT_PYTHON="$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
if [ -x "$DEFAULT_PYTHON" ]; then
  PYTHON="${CODEX_THEME_PACK_PYTHON:-$DEFAULT_PYTHON}"
else
  PYTHON="${CODEX_THEME_PACK_PYTHON:-$(command -v python3 2>/dev/null || true)}"
fi
STATE_ROOT="$HOME/Library/Application Support/CodexDreamSkinStudio"
PACKS_ROOT="$STATE_ROOT/packs"
ACTIVE_THEME="$STATE_ROOT/theme"
CURRENT_PACK="$STATE_ROOT/current-pack.json"
CONFIG="$HOME/.codex/config.toml"
GLOBAL_STATE="$HOME/.codex/.codex-global-state.json"
LOG="$STATE_ROOT/pack-switch.log"
PACK_ID=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --id) PACK_ID="${2:-}"; shift 2 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done
[ -n "$PACK_ID" ] || { printf 'Usage: switch_pack_macos.sh --id <pack-id>\n' >&2; exit 2; }
[ -f "$COMMON" ] || { printf 'Dream Skin engine is missing: %s\n' "$ENGINE" >&2; exit 1; }
[ -x "$PYTHON" ] || { printf 'Bundled Python is missing: %s\n' "$PYTHON" >&2; exit 1; }

PACK_DIR="$PACKS_ROOT/$PACK_ID"
"$PYTHON" "$SKILL_DIR/scripts/validate_pack.py" "$PACK_DIR" >/dev/null

mkdir -p "$STATE_ROOT" "$PACKS_ROOT"
chmod 700 "$STATE_ROOT" "$PACKS_ROOT" 2>/dev/null || true
TXN="$(mktemp -d "$STATE_ROOT/.pack-switch.XXXXXX")"
LOCK="$STATE_ROOT/.pack-switch.lock"
ROLLBACK_NEEDED="true"

log() {
  printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >>"$LOG"
}

notify() {
  /usr/bin/osascript -e "display notification \"$(printf '%s' "$*" | sed 's/"/\\"/g')\" with title \"Codex 主题套装\"" >/dev/null 2>&1 || true
}

backup_file() {
  if [ -f "$1" ]; then cp -p "$1" "$2"; fi
  return 0
}

lock_owner_is_alive() {
  [ -f "$LOCK/pid" ] || return 1
  owner="$(/bin/cat "$LOCK/pid" 2>/dev/null || true)"
  case "$owner" in
    ''|*[!0-9]*) return 1 ;;
  esac
  /bin/kill -0 "$owner" 2>/dev/null
}

acquire_lock() {
  if [ -d "$LOCK" ]; then
    if lock_owner_is_alive; then
      printf 'Another theme-pack operation is already running (pid %s).\n' "$owner" >&2
      return 1
    fi
    log "removed stale switch lock"
    /usr/bin/find "$LOCK" -depth -delete 2>/dev/null || true
  fi
  /bin/mkdir "$LOCK"
  printf '%s\n' "$$" >"$LOCK/pid"
}

owns_lock() {
  [ -f "$LOCK/pid" ] || return 1
  [ "$(/bin/cat "$LOCK/pid" 2>/dev/null || true)" = "$$" ]
}

restore_transaction() {
  set +e
  rm -rf "$ACTIVE_THEME"
  [ -d "$TXN/theme" ] && cp -R "$TXN/theme" "$ACTIVE_THEME"
  [ -f "$TXN/config.toml" ] && cp -p "$TXN/config.toml" "$CONFIG"
  [ -f "$TXN/global-state.json" ] && cp -p "$TXN/global-state.json" "$GLOBAL_STATE"
  if [ -f "$TXN/current-pack.json" ]; then
    cp -p "$TXN/current-pack.json" "$CURRENT_PACK"
  else
    rm -f "$CURRENT_PACK"
  fi
  /bin/bash "$ENGINE/scripts/start-dream-skin-macos.sh" --port 9341 --restart-existing >>"$LOG" 2>&1 || true
  notify "切换失败，已恢复上一套"
  log "rollback completed for target=$PACK_ID"
}

cleanup() {
  code=$?
  if [ "$code" -ne 0 ] && [ "$ROLLBACK_NEEDED" = "true" ]; then
    if owns_lock; then
      restore_transaction
    else
      log "skipped stale rollback target=$PACK_ID owner=$$"
    fi
  fi
  rm -rf "$TXN"
  if owns_lock; then
    /usr/bin/find "$LOCK" -depth -delete 2>/dev/null || true
  fi
  exit "$code"
}
trap cleanup EXIT

acquire_lock
log "switch start target=$PACK_ID"
notify "正在切换到 ${PACK_ID}…"
[ -d "$ACTIVE_THEME" ] && cp -R "$ACTIVE_THEME" "$TXN/theme"
backup_file "$CONFIG" "$TXN/config.toml"
backup_file "$GLOBAL_STATE" "$TXN/global-state.json"
backup_file "$CURRENT_PACK" "$TXN/current-pack.json"

# shellcheck source=/dev/null
. "$COMMON"
discover_codex_app
require_macos_runtime

# Do not close a healthy themed Codex session just to change packs. The engine's
# start entrypoint already has a CDP fast path that reloads the theme in place.
# A full restart remains a recovery path only when the running app has no usable
# CDP endpoint (for example, the first themed launch).

PET_ID="$("$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))["pet"]["id"])' "$PACK_DIR/pack.json")"
SELECTED="custom:$PET_ID"

rm -rf "$ACTIVE_THEME.next"
mkdir -p "$ACTIVE_THEME.next"
cp -R "$PACK_DIR/theme/." "$ACTIVE_THEME.next/"
rm -rf "$ACTIVE_THEME"
mv "$ACTIVE_THEME.next" "$ACTIVE_THEME"
chmod 700 "$ACTIVE_THEME"
chmod 600 "$ACTIVE_THEME"/* 2>/dev/null || true

rm -rf "$HOME/.codex/pets/$PET_ID.next"
mkdir -p "$HOME/.codex/pets/$PET_ID.next"
cp -R "$PACK_DIR/pet/." "$HOME/.codex/pets/$PET_ID.next/"
rm -rf "$HOME/.codex/pets/$PET_ID"
mv "$HOME/.codex/pets/$PET_ID.next" "$HOME/.codex/pets/$PET_ID"

"$PYTHON" "$SKILL_DIR/scripts/set_avatar_state.py" \
  --config "$CONFIG" \
  --global-state "$GLOBAL_STATE" \
  --selected-avatar-id "$SELECTED"

"$PYTHON" - "$PACK_DIR/pack.json" "$CURRENT_PACK" <<'PY'
import json, os, sys, tempfile
source, target = sys.argv[1:]
pack = json.load(open(source, encoding="utf-8"))
value = json.dumps({"schemaVersion": 1, "id": pack["id"], "name": pack["name"]}, ensure_ascii=False, indent=2) + "\n"
directory = os.path.dirname(target)
fd, temporary = tempfile.mkstemp(prefix=".current-pack.", dir=directory)
with os.fdopen(fd, "w", encoding="utf-8") as handle:
    handle.write(value)
os.replace(temporary, target)
PY

/bin/bash "$ENGINE/scripts/start-dream-skin-macos.sh" --port 9341 --restart-existing >>"$LOG" 2>&1
grep -Fq "selected-avatar-id = \"$SELECTED\"" "$CONFIG"
set +e
"$NODE" "$ENGINE/scripts/injector.mjs" --verify --port 9341 --theme-dir "$ACTIVE_THEME" --timeout-ms 30000 >"$TXN/verify.json" 2>>"$LOG"
VERIFY_CODE=$?
set -e
cat "$TXN/verify.json" >>"$LOG"
if [ "$VERIFY_CODE" -ne 0 ] && ! grep -q '"installed": true' "$TXN/verify.json"; then
  printf 'Live theme verification failed.\n' >&2
  exit 1
fi

ROLLBACK_NEEDED="false"
notify "已切换：$PACK_ID"
log "switch success target=$PACK_ID pet=$PET_ID"
