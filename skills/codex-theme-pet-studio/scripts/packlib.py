#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from PIL import Image

ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
PET_SIZES = {1: (1536, 1872), 2: (1536, 2288)}


class PackError(ValueError):
    pass


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise PackError(f"missing file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise PackError(f"invalid JSON in {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise PackError(f"expected JSON object: {path}")
    return value


def safe_relative_dir(root: Path, value: Any, label: str) -> Path:
    if not isinstance(value, str) or not value.strip():
        raise PackError(f"{label} must be a non-empty relative path")
    raw = Path(value)
    if raw.is_absolute():
        raise PackError(f"{label} must be relative")
    resolved = (root / raw).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError as exc:
        raise PackError(f"{label} escapes the pack") from exc
    if not resolved.is_dir():
        raise PackError(f"{label} directory is missing: {resolved}")
    return resolved


def validate_pack(pack_dir: Path) -> dict[str, Any]:
    pack_dir = pack_dir.resolve()
    manifest = read_json(pack_dir / "pack.json")
    errors: list[str] = []
    warnings: list[str] = []

    if manifest.get("schemaVersion") != 1:
        errors.append("pack schemaVersion must be 1")
    pack_id = manifest.get("id")
    if not isinstance(pack_id, str) or not ID_RE.fullmatch(pack_id):
        errors.append("pack id must use lowercase letters, digits, and hyphens")
    for key in ("name", "description"):
        if not isinstance(manifest.get(key), str) or not manifest[key].strip():
            errors.append(f"pack {key} must be non-empty")

    try:
        theme_dir = safe_relative_dir(pack_dir, manifest.get("theme", {}).get("path"), "theme.path")
        theme = read_json(theme_dir / "theme.json")
        if theme.get("schemaVersion") != 1:
            errors.append("theme schemaVersion must be 1")
        image_name = theme.get("image")
        if not isinstance(image_name, str) or Path(image_name).name != image_name:
            errors.append("theme image must be a basename")
        else:
            image_path = theme_dir / image_name
            if image_path.suffix.lower() not in IMAGE_EXTENSIONS:
                errors.append("theme image format must be PNG, JPEG, or WebP")
            elif not image_path.is_file() or not (0 < image_path.stat().st_size <= 16 * 1024 * 1024):
                errors.append("theme image must be non-empty and no larger than 16 MB")
        decoration_name = theme.get("decoration")
        if decoration_name is not None:
            if not isinstance(decoration_name, str) or Path(decoration_name).name != decoration_name:
                errors.append("theme decoration must be a basename")
            else:
                decoration_path = theme_dir / decoration_name
                if decoration_path.suffix.lower() not in IMAGE_EXTENSIONS:
                    errors.append("theme decoration format must be PNG, JPEG, or WebP")
                elif not decoration_path.is_file() or not (0 < decoration_path.stat().st_size <= 16 * 1024 * 1024):
                    errors.append("theme decoration must be non-empty and no larger than 16 MB")
        css_path = theme_dir / "theme.css"
        if css_path.exists():
            if not css_path.is_file() or css_path.stat().st_size > 256 * 1024:
                errors.append("theme.css must be a file no larger than 256 KB")
            else:
                css_path.read_text(encoding="utf-8")
    except (PackError, UnicodeDecodeError) as exc:
        errors.append(str(exc))
        theme_dir = None
        theme = {}

    pet_spec = manifest.get("pet")
    if not isinstance(pet_spec, dict):
        errors.append("pet must be an object")
        pet_spec = {}
    pet_id = pet_spec.get("id")
    if not isinstance(pet_id, str) or not ID_RE.fullmatch(pet_id):
        errors.append("pet id must use lowercase letters, digits, and hyphens")
    if pet_spec.get("selectedAvatarId") != f"custom:{pet_id}":
        errors.append("pet.selectedAvatarId must equal custom:<pet.id>")

    try:
        pet_dir = safe_relative_dir(pack_dir, pet_spec.get("path"), "pet.path")
        pet = read_json(pet_dir / "pet.json")
        declared_id = pet.get("id")
        if declared_id not in (None, pet_id):
            errors.append("pet.json id does not match pack pet id")
        version = pet.get("spriteVersionNumber", 1)
        if version not in PET_SIZES:
            errors.append("pet spriteVersionNumber must be 1 or 2")
        sprite_name = pet.get("spritesheetPath", "spritesheet.webp")
        if not isinstance(sprite_name, str) or Path(sprite_name).name != sprite_name:
            errors.append("pet spritesheetPath must be a basename")
        else:
            sprite_path = pet_dir / sprite_name
            if not sprite_path.is_file():
                errors.append("pet spritesheet is missing")
            elif version in PET_SIZES:
                with Image.open(sprite_path) as image:
                    if image.size != PET_SIZES[version]:
                        errors.append(
                            f"pet atlas is {image.size[0]}x{image.size[1]}, expected "
                            f"{PET_SIZES[version][0]}x{PET_SIZES[version][1]} for v{version}"
                        )
                    if image.format not in {"PNG", "WEBP"}:
                        errors.append("pet atlas must be PNG or WebP")
        if version == 1:
            warnings.append("imported v1 pet accepted; new pets should use v2")
    except (PackError, OSError) as exc:
        errors.append(str(exc))
        pet_dir = None
        pet = {}

    compatibility = manifest.get("compatibility")
    if not isinstance(compatibility, dict) or compatibility.get("platform") != "darwin":
        errors.append("compatibility.platform must be darwin")
    if not isinstance(compatibility, dict) or not isinstance(compatibility.get("minSkinVersion"), str):
        errors.append("compatibility.minSkinVersion must be a string")

    return {
        "ok": not errors,
        "packDir": str(pack_dir),
        "id": pack_id,
        "name": manifest.get("name"),
        "themeDir": str(theme_dir) if theme_dir else None,
        "themeId": theme.get("id"),
        "petDir": str(pet_dir) if pet_dir else None,
        "petId": pet_id,
        "petVersion": pet.get("spriteVersionNumber", 1) if pet else None,
        "errors": errors,
        "warnings": warnings,
        "manifest": manifest,
    }
