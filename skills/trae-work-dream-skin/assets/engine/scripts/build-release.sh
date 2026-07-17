#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
VERSION="$(/usr/bin/tr -d '[:space:]' < "$ROOT/VERSION")"
RELEASE_DIR="$ROOT/release"
ARCHIVE="$RELEASE_DIR/trae-work-dream-skin-studio-v$VERSION-macos.zip"
TMP="$(/usr/bin/mktemp -d /tmp/trae-work-dream-skin-release.XXXXXX)"
trap '/bin/rm -rf "$TMP"' EXIT

if [ "${1:-}" != "--skip-tests" ]; then "$ROOT/tests/run-tests.sh"; fi

/bin/mkdir -p "$TMP/trae-work-dream-skin-studio" "$RELEASE_DIR"
/usr/bin/rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude '._*' \
  --exclude 'agents/' \
  --exclude 'client-delivery/' \
  --exclude 'menubar/' \
  --exclude 'release/' \
  "$ROOT/" "$TMP/trae-work-dream-skin-studio/"
/bin/chmod 755 "$TMP/trae-work-dream-skin-studio"/*.command
/bin/chmod 755 "$TMP/trae-work-dream-skin-studio"/scripts/*.sh "$TMP/trae-work-dream-skin-studio"/tests/*.sh
/usr/bin/find "$TMP/trae-work-dream-skin-studio" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/rm -f "$ARCHIVE"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr \
  "$TMP/trae-work-dream-skin-studio" "$ARCHIVE"
SHA256="$(/usr/bin/shasum -a 256 "$ARCHIVE" | /usr/bin/awk '{print $1}')"
/usr/bin/printf '%s  %s\n' "$SHA256" "$(basename "$ARCHIVE")" > "$RELEASE_DIR/SHA256SUMS.txt"
/usr/bin/printf 'Created %s\nSHA-256 %s\n' "$ARCHIVE" "$SHA256"
