#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import tempfile
from pathlib import Path

from packlib import PackError, validate_pack


def replace_tree(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(tempfile.mkdtemp(prefix=f".{destination.name}.", dir=destination.parent))
    staged = temporary / destination.name
    try:
        shutil.copytree(source, staged)
        backup = destination.with_name(destination.name + ".previous")
        if backup.exists():
            shutil.rmtree(backup)
        if destination.exists():
            destination.rename(backup)
        staged.rename(destination)
        if backup.exists():
            shutil.rmtree(backup)
    finally:
        shutil.rmtree(temporary, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pack_dir", type=Path)
    parser.add_argument(
        "--state-root",
        type=Path,
        default=Path.home() / "Library/Application Support/CodexDreamSkinStudio",
    )
    parser.add_argument(
        "--codex-home",
        type=Path,
        default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")),
    )
    args = parser.parse_args()
    report = validate_pack(args.pack_dir)
    if not report["ok"]:
        raise PackError("; ".join(report["errors"]))
    pack_id = report["id"]
    pet_id = report["petId"]
    destination = args.state_root / "packs" / pack_id
    replace_tree(args.pack_dir.resolve(), destination)
    replace_tree(destination / report["manifest"]["pet"]["path"], args.codex_home / "pets" / pet_id)
    result = {
        "ok": True,
        "pack": str(destination),
        "pet": str(args.codex_home / "pets" / pet_id),
        "id": pack_id,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
