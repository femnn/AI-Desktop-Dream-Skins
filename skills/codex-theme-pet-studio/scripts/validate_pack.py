#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from packlib import validate_pack


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pack_dir", type=Path)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()
    report = validate_pack(args.pack_dir)
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
