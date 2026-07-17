#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


REQUIRED_THEME_FIELDS = (
    "id", "name", "brandSubtitle", "tagline", "projectPrefix",
    "projectLabel", "statusText", "quote", "image", "colors",
)

CSS_SURFACES = {
    "task background": "main.main-surface",
    "sidebar": "aside.app-shell-left-panel",
    "home cards": "group\\/home-suggestions",
    "composer": ".composer-surface-chrome",
    "project selector": "group\\/project-selector",
    "selected state": "[aria-current",
    "hover state": ":hover",
    "project rows": "data-app-action-sidebar-project-row",
    "brand icon": ".dream-skin-portal-mark",
    "responsive rules": "@media",
}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: audit_theme_completeness.py <pack-dir>", file=sys.stderr)
        return 2
    pack_dir = Path(sys.argv[1]).expanduser().resolve()
    errors: list[str] = []
    warnings: list[str] = []
    manifest = json.loads((pack_dir / "pack.json").read_text(encoding="utf-8"))
    theme_dir = (pack_dir / manifest["theme"]["path"]).resolve()
    try:
        theme_dir.relative_to(pack_dir)
    except ValueError:
        errors.append("theme.path escapes the pack")
    theme = json.loads((theme_dir / "theme.json").read_text(encoding="utf-8"))

    for field in REQUIRED_THEME_FIELDS:
        if field not in theme or theme[field] in (None, "", {}):
            errors.append(f"theme.json is missing {field}")
    if not theme.get("composerPlaceholder"):
        warnings.append("composerPlaceholder is missing; add theme-specific input guidance")

    image_path = theme_dir / str(theme.get("image", ""))
    if image_path.is_file():
        with Image.open(image_path) as image:
            width, height = image.size
            ratio = width / max(height, 1)
            if width < 1280 or height < 720:
                warnings.append(f"wallpaper is only {width}x{height}; prefer at least 1280x720")
            if not 1.65 <= ratio <= 1.9:
                warnings.append(f"wallpaper aspect ratio is {ratio:.2f}; target 16:9")

    css_path = theme_dir / "theme.css"
    if not css_path.is_file():
        errors.append("theme.css is required for a complete interface theme")
        css = ""
    else:
        css = css_path.read_text(encoding="utf-8")
    if "html.codex-dream-skin" not in css:
        errors.append("theme.css is not scoped under html.codex-dream-skin")
    for label, marker in CSS_SURFACES.items():
        if marker not in css:
            errors.append(f"theme.css does not cover {label}")

    decoration = theme.get("decoration")
    if decoration:
        if Path(decoration).name != decoration:
            errors.append("decoration must be a basename")
        elif not (theme_dir / decoration).is_file():
            errors.append("declared decoration asset is missing")
        if ".dream-skin-decoration" not in css:
            errors.append("decoration is declared but not themed")
    else:
        warnings.append("no independent decoration; confirm that the concept intentionally omits one")

    result = {
        "ok": not errors,
        "packDir": str(pack_dir),
        "themeId": theme.get("id"),
        "errors": errors,
        "warnings": warnings,
        "manualChecks": [
            "wallpaper contains no unintended objects, logos, UI, or generation defects",
            "sidebar, task page, cards, composer, project selector, and top status share one visual language",
            "repeated card avatars are visibly distinct in a live screenshot when differentiation is intended",
            "selected, hover, disabled, and active icons remain distinguishable without obscuring native controls",
            "decoration is fully visible, pointer-inert, responsive, and does not cover composer controls",
            "home and task screenshots pass at current, narrow, and short window sizes",
            "theme and pet persist after a normal Codex relaunch without a restart loop",
        ],
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
