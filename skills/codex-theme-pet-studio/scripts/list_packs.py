#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from packlib import validate_pack


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path.home() / "Library/Application Support/CodexDreamSkinStudio/packs",
    )
    parser.add_argument("--format", choices=("json", "lines"), default="json")
    args = parser.parse_args()
    packs = []
    if args.root.is_dir():
        for directory in sorted(args.root.iterdir()):
            if not directory.is_dir() or not (directory / "pack.json").is_file():
                continue
            report = validate_pack(directory)
            if report["ok"]:
                packs.append({
                    "id": report["id"],
                    "name": report["name"],
                    "petId": report["petId"],
                    "petVersion": report["petVersion"],
                })
    if args.format == "lines":
        for pack in packs:
            print(f'{pack["id"]}\t{pack["name"]}')
    else:
        print(json.dumps(packs, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
