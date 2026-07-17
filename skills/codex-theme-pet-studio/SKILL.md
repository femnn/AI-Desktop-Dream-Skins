---
name: codex-theme-pet-studio
description: Create, validate, install, list, and atomically switch complete macOS Codex theme packs that pair a Dream Skin interface theme with a matching animated Codex pet. Use when a user asks specifically for a Codex desktop skin, game/brand-inspired Codex interface, matching mascot or pet, reusable Codex theme-and-pet bundle, or one-click Codex appearance switching. Do not use WorkBuddy poster dimensions, CodeDrobe manifests, or TRAE Work selectors for Codex.
---

# Codex Theme Pet Studio

## Overview

Build one coherent Codex appearance as a theme pack: research the visual subject, generate and integrate the full interface theme, verify it in the live Codex app, hatch a matching animated pet, package both, install them, and test one-click switching.

This skill is Codex-only. If the request targets WorkBuddy or TRAE Work, route to their dedicated skill. Read [references/platform-contract.md](references/platform-contract.md) before producing assets.

## Required dependencies

Before visual generation, read and follow:

- `${CODEX_HOME:-$HOME/.codex}/skills/.system/imagegen/SKILL.md`
- `${CODEX_HOME:-$HOME/.codex}/skills/hatch-pet/SKILL.md`

Use the built-in image generation path. Use `hatch-pet` for every newly generated pet; new pets must be v2. Existing valid v1 pets may be preserved inside imported packs.

The macOS theme engine must exist at:

```text
${CODEX_HOME:-$HOME/.codex}/codex-dream-skin-studio
```

## Visible workflow

Maintain one visible checklist:

1. Researching `<Pack>`.
2. Designing `<Pack>`'s Codex interface.
3. Hatching `<Pack>`'s pet.
4. Packaging and switching `<Pack>`.

## Create a pack

1. Research a named game, product, or brand using official sources. Record palette, shapes, materials, atmosphere, signature objects, and avoidances. Do not copy logos, readable marks, screenshots, slogans, or promotional text.
2. Prepare a run:

```bash
PYTHON=<workspace dependency Python>
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/codex-theme-pet-studio"
"$PYTHON" "$SKILL_DIR/scripts/prepare_pack_run.py" \
  --id <pack-id> \
  --name "<Pack Name>" \
  --description "<one sentence>" \
  --output-dir <absolute-run-dir>
```

3. Generate one pure 16:9, production-quality Codex wallpaper with `$imagegen`. Compose the visual subject on the right and reserve quiet negative space on the left for Codex copy and controls. Do not generate a WorkBuddy ultra-wide poster or bake cards, icons, text, charms, or composer UI into it. Save it under the run's `pack/theme/`.
4. Write `theme/theme.json` and `theme/theme.css`. Read `references/theme-contract.md` and `references/theme-completeness-checklist.md`. Theme the complete shell: banner, task background, sidebar, cards, every icon container, selected and hover states, composer, project selector, status details, independent decoration, and responsive states. Keep native controls interactive. If the design includes a photo, disc, charm, or sticker, store it as the optional separate `decoration` asset instead of baking it into the wallpaper. When four cards use character faces, design and verify four unmistakably different expressions rather than tiny eye changes.
5. Inspect the real Codex DOM before writing wrapper-sensitive selectors. Never assume `nth-child` belongs on a button; confirm the actual repeated parent structure. Record selector counts and computed output for icons, selected rows, card faces, composer controls, and decoration. Validate and install the candidate pack without activating it. Review the hero and CSS payload offline. Do not close, restart, or switch the user's active Codex while theme or pet production is still in progress.
6. Use `hatch-pet` to create the matching pet. Use the approved theme hero as a visual reference. Copy the packaged `pet.json` and `spritesheet.webp` into the run's `pack/pet/`.
7. Write `pack.json` from `references/pack-contract.md`.
8. Validate and install the complete pack. Activate it only after the interface, pet, switcher, persistence helper, and offline checks are all complete:

```bash
"$PYTHON" "$SKILL_DIR/scripts/validate_pack.py" <run>/pack
"$PYTHON" "$SKILL_DIR/scripts/audit_theme_completeness.py" <run>/pack
"$PYTHON" "$SKILL_DIR/scripts/install_pack.py" <run>/pack
/bin/bash "$SKILL_DIR/scripts/switch_pack_macos.sh" --id <pack-id>
```

9. Capture home, task, narrow, and short screenshots. Verify repeated card icons are visibly distinct when intended, the decoration is complete and unobstructive, every native label is readable, and the composer/project/model/send rows do not overlap. Retain the wallpaper, separate decoration, screenshots, pet contact sheet, audit JSON, validation report, and switch log.

## Import an existing theme and pet

Preserve approved assets. Copy the active Dream Skin `theme.json`, image, and optional `theme.css` into `pack/theme/`; copy the pet package into `pack/pet/`; write `pack.json`; validate and install. Do not regenerate an existing asset merely to normalize its style or sprite version.

## Switch packs

Use the same transaction path for CLI, Desktop, and menu-bar switching:

```bash
/bin/bash "$SKILL_DIR/scripts/switch_pack_macos.sh" --id <pack-id>
```

The switcher must validate first, back up the active theme and Codex avatar settings, stage the theme and pet, set `[desktop].selected-avatar-id` to `custom:<pet-id>`, clear stale avatar atom state, keep the overlay open, hot-reapply Dream Skin through the existing verified CDP endpoint, verify, and roll back on failure. Never unconditionally stop a healthy themed Codex session. A controlled restart is a recovery path only when no usable theme endpoint exists.

Install the Documents-project chooser with:

```bash
/bin/bash "$SKILL_DIR/scripts/install_switcher_macos.sh"
```

Install and launch the dependency-free native menu-bar chooser with:

```bash
/bin/bash "$SKILL_DIR/scripts/install_menubar_app_macos.sh"
```

The existing Dream Skin SwiftBar plug-in also discovers packs when SwiftBar is present. Both menu-bar implementations call the same transaction script.

Install the session guard so the current pack is restored when the user later opens Codex normally:

```bash
/bin/bash "$SKILL_DIR/scripts/install_session_guard_macos.sh"
```

The native menu app observes the next Codex launch event without polling. It never launches Codex after the user quits; when the user opens a normal Codex session that lacks the loopback theme endpoint, it performs one controlled themed restart. The installer removes the legacy five-second LaunchAgent, enforces a single menu-app instance, and stale operation locks are cleared only when their recorded owner process is gone.

## Acceptance

- `validate_pack.py` reports `ok: true`.
- Theme image is readable at the current Codex window aspect ratio and all native controls remain usable.
- Optional `theme.css` is local, bounded, and loaded after the base Dream Skin CSS.
- `audit_theme_completeness.py` reports `ok: true`, and every manual check in its output has been reviewed against live screenshots.
- DOM-sensitive selectors are confirmed against the running Codex build; repeated card expressions are not accepted until their live output is visibly distinct.
- Wallpaper, independent decoration, sidebar icons, selected states, card icons, task page, composer text, and responsive behavior form one complete visual system.
- Pet atlas matches its declared v1 or v2 dimensions; newly generated pets are v2.
- Live verification confirms the expected theme id and `custom:<pet-id>`.
- Creating or repairing a pack performs no intermediate Codex restarts; live activation happens only after all offline work passes.
- Switching pack A → B → A restores both interface and pet each time.
- A forced switch failure restores the previous theme, avatar setting, and current-pack record.
