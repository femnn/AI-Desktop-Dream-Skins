#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import tempfile
from pathlib import Path


def atomic_write(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(value)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def update_config(content: str, selected: str) -> str:
    lines = content.splitlines(keepends=True)
    start = None
    end = len(lines)
    for index, line in enumerate(lines):
        if re.match(r"^\s*\[desktop\]\s*(?:#.*)?$", line):
            start = index
            continue
        if start is not None and index > start and re.match(r"^\s*\[", line):
            end = index
            break
    entry = f'selected-avatar-id = "{selected}"\n'
    if start is None:
        separator = "" if not content or content.endswith("\n\n") else ("\n" if content.endswith("\n") else "\n\n")
        return content + separator + "[desktop]\n" + entry
    for index in range(start + 1, end):
        if re.match(r"^\s*selected-avatar-id\s*=", lines[index]):
            lines[index] = entry
            return "".join(lines)
    lines.insert(end, entry)
    return "".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--global-state", required=True, type=Path)
    parser.add_argument("--selected-avatar-id", required=True)
    args = parser.parse_args()
    content = args.config.read_text(encoding="utf-8")
    atomic_write(args.config, update_config(content, args.selected_avatar_id))
    state = {}
    if args.global_state.exists():
        state = json.loads(args.global_state.read_text(encoding="utf-8"))
    atoms = state.setdefault("electron-persisted-atom-state", {})
    atoms.pop("selected-avatar-id", None)
    atoms["electron-avatar-overlay-open"] = True
    state["electron-avatar-overlay-open"] = True
    atomic_write(args.global_state, json.dumps(state, ensure_ascii=False, separators=(",", ":")) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
