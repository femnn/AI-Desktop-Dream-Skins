#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--description", required=True)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", args.id):
        parser.error("--id must use lowercase letters, digits, and hyphens")
    root = args.output_dir.resolve()
    if root.exists() and any(root.iterdir()) and not args.force:
        parser.error(f"output directory is not empty: {root}")
    for path in (
        root / "pack" / "theme",
        root / "pack" / "pet",
        root / "research",
        root / "qa",
        root / "prompts",
    ):
        path.mkdir(parents=True, exist_ok=True)
    request = {
        "schemaVersion": 1,
        "id": args.id,
        "name": args.name,
        "description": args.description,
        "stages": ["research", "theme", "theme-qa", "pet", "package", "live-qa"],
    }
    (root / "pack-request.json").write_text(
        json.dumps(request, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
