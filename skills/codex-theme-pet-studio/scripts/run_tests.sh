#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
PYTHON="${PYTHON:-/Users/kangkang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3}"
TMP="$(mktemp -d /tmp/codex-theme-pet-tests.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

"$PYTHON" -m py_compile "$ROOT/scripts/"*.py
for script in "$ROOT/scripts/"*.sh; do /bin/bash -n "$script"; done
if /usr/bin/grep -Eq '^[[:space:]]*stop_codex([[:space:]]|$)' "$ROOT/scripts/switch_pack_macos.sh"; then
  echo "switch_pack_macos.sh must not unconditionally close Codex" >&2
  exit 1
fi

mkdir -p "$TMP/pack/theme" "$TMP/pack/pet"
cp "$HOME/Library/Application Support/CodexDreamSkinStudio/theme/theme.json" "$TMP/pack/theme/"
THEME_IMAGE="$("$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))["image"])' "$HOME/Library/Application Support/CodexDreamSkinStudio/theme/theme.json")"
cp "$HOME/Library/Application Support/CodexDreamSkinStudio/theme/$THEME_IMAGE" "$TMP/pack/theme/"
THEME_DECORATION="$($PYTHON -c 'import json,sys; print(json.load(open(sys.argv[1])).get("decoration", ""))' "$HOME/Library/Application Support/CodexDreamSkinStudio/theme/theme.json")"
if [ -n "$THEME_DECORATION" ]; then
  cp "$HOME/Library/Application Support/CodexDreamSkinStudio/theme/$THEME_DECORATION" "$TMP/pack/theme/"
fi
cp "$HOME/.codex/pets/molin/pet.json" "$HOME/.codex/pets/molin/spritesheet.webp" "$TMP/pack/pet/"
"$PYTHON" - "$TMP/pack/pack.json" <<'PY'
import json, sys
value = {
    "schemaVersion": 1,
    "id": "test-pack",
    "name": "Test Pack",
    "description": "Fixture.",
    "theme": {"path": "theme"},
    "pet": {"id": "molin", "path": "pet", "selectedAvatarId": "custom:molin"},
    "compatibility": {"platform": "darwin", "minSkinVersion": "1.1.1"},
}
open(sys.argv[1], "w", encoding="utf-8").write(json.dumps(value, indent=2) + "\n")
PY
"$PYTHON" "$ROOT/scripts/validate_pack.py" "$TMP/pack" >/dev/null

cp "$TMP/pack/theme/$THEME_IMAGE" "$TMP/pack/theme/decoration.png"
"$PYTHON" - "$TMP/pack/theme/theme.json" <<'PY'
import json, sys
path = sys.argv[1]
value = json.load(open(path))
value["decoration"] = "decoration.png"
json.dump(value, open(path, "w"))
PY
"$PYTHON" "$ROOT/scripts/validate_pack.py" "$TMP/pack" >/dev/null
"$PYTHON" - "$TMP/pack/theme/theme.json" <<'PY'
import json, sys
path = sys.argv[1]
value = json.load(open(path))
value["decoration"] = "../escape.png"
json.dump(value, open(path, "w"))
PY
if "$PYTHON" "$ROOT/scripts/validate_pack.py" "$TMP/pack" >/dev/null 2>&1; then
  echo "decoration traversal fixture unexpectedly passed" >&2
  exit 1
fi
"$PYTHON" - "$TMP/pack/theme/theme.json" <<'PY'
import json, sys
path = sys.argv[1]
value = json.load(open(path))
value["decoration"] = "decoration.png"
json.dump(value, open(path, "w"))
PY

cp "$TMP/pack/pack.json" "$TMP/good.json"
"$PYTHON" - "$TMP/pack/pack.json" <<'PY'
import json, sys
path = sys.argv[1]
value = json.load(open(path))
value["theme"]["path"] = "../escape"
json.dump(value, open(path, "w"))
PY
if "$PYTHON" "$ROOT/scripts/validate_pack.py" "$TMP/pack" >/dev/null 2>&1; then
  echo "path traversal fixture unexpectedly passed" >&2
  exit 1
fi
cp "$TMP/good.json" "$TMP/pack/pack.json"

"$PYTHON" - "$TMP/config.toml" <<'PY'
import sys
open(sys.argv[1], "w", encoding="utf-8").write(
    'model = "gpt-5"\n\n[desktop]\nkeepMe = true\n\n[features]\nmemories = true\n'
)
PY
printf '%s\n' '{"electron-persisted-atom-state":{"selected-avatar-id":"stale"},"keep":true}' >"$TMP/state.json"
"$PYTHON" "$ROOT/scripts/set_avatar_state.py" \
  --config "$TMP/config.toml" \
  --global-state "$TMP/state.json" \
  --selected-avatar-id custom:molin
grep -Fq 'selected-avatar-id = "custom:molin"' "$TMP/config.toml"
grep -Fq 'keepMe = true' "$TMP/config.toml"
grep -Fq 'memories = true' "$TMP/config.toml"
"$PYTHON" - "$TMP/state.json" <<'PY'
import json, sys
value = json.load(open(sys.argv[1]))
atoms = value["electron-persisted-atom-state"]
assert "selected-avatar-id" not in atoms
assert atoms["electron-avatar-overlay-open"] is True
assert value["electron-avatar-overlay-open"] is True
assert value["keep"] is True
PY

echo "PASS: skill scripts, valid pack, traversal rejection, avatar config preservation."
