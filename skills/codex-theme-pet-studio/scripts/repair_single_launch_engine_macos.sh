#!/bin/bash
set -euo pipefail

ENGINE="${CODEX_DREAM_SKIN_ENGINE:-$HOME/.codex/codex-dream-skin-studio}"
TARGET="$ENGINE/scripts/start-dream-skin-macos.sh"
[ -f "$TARGET" ] || { printf 'Dream Skin start script is missing: %s\n' "$TARGET" >&2; exit 1; }

/usr/bin/python3 - "$TARGET" <<'PY'
from pathlib import Path
import os
import sys
import tempfile

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
unsafe = '''  # Some builds open the window slowly; also try activating the app once.
  /usr/bin/open -na "$CODEX_BUNDLE" --args --remote-debugging-address=127.0.0.1 --remote-debugging-port="$PORT" >/dev/null 2>&1 || true
'''
safe = '''  # launch_codex_with_cdp already creates the single themed app instance.
  # A second `open -na` creates another window and can redirect the user to
  # New Task, so never use activation-by-relaunch here.
'''
if unsafe in text:
    backup = path.with_suffix(path.suffix + ".pre-single-launch-fix")
    if not backup.exists():
        backup.write_text(text, encoding="utf-8")
    text = text.replace(unsafe, safe, 1)
    fd, temporary = tempfile.mkstemp(prefix=".start-dream-skin.", dir=path.parent)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(text)
    os.chmod(temporary, path.stat().st_mode)
    os.replace(temporary, path)
elif safe not in text:
    raise SystemExit("Unknown Dream Skin start script; refusing an unsafe automatic edit.")
print(f"single-launch engine verified: {path}")
PY

/bin/bash -n "$TARGET"
