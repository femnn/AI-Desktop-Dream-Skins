---
name: trae-work-dream-skin
description: Install, customize, switch, verify, restore, scaffold, and package complete TRAE Work or TRAE SOLO Dream Skin themes on macOS, including the China app. Use when a user asks for a TRAE Work skin, horizontal TRAE hero, Work/Code/Design page styling, readable TRAE sidebar/cards/composer, reusable preset, verification screenshot, restore workflow, or installation ZIP. Do not use Codex pets, WorkBuddy CodeDrobe packages, or another app's DOM selectors.
---

# TRAE Work Dream Skin

Use `scripts/trae-work-skin.sh` for routine operations.

This skill is TRAE-only. Read [references/platform-contract.md](references/platform-contract.md) before generating assets. Read [references/completeness-checklist.md](references/completeness-checklist.md) before applying a new preset.

## Safety

- Support macOS only.
- Ask the user to save unsent TRAE Work input before a possible restart.
- Never modify the official `.app`, `app.asar`, resources, or signature.
- Let the engine request restart confirmation; do not force a restart over unsaved work.
- Treat the loopback debugging port as sensitive and recommend Restore when the theme is not in use.
- Treat supplied artwork as user-owned or third-party material. Do not imply redistribution rights.
- Finish research, image generation, CSS, manifest, tests, and packaging before any restart. Prefer live hot-reapply. Never create a restart loop; at most one final user-authorized restart may be used when no verified endpoint exists.

## Inspect

Run:

```bash
scripts/trae-work-skin.sh doctor
```

Use the result to confirm app identity, signature, version, active theme, and live status. If the user asks only for diagnosis, report the evidence without changing anything.

## Apply a bundled style

```bash
scripts/trae-work-skin.sh apply-preset pixel-8bit
scripts/trae-work-skin.sh apply-preset electric-forest
scripts/trae-work-skin.sh apply-preset sky-friends
scripts/trae-work-skin.sh apply-preset retro-2007
scripts/trae-work-skin.sh apply-default
```

## Customize with an image

Open the file picker:

```bash
scripts/trae-work-skin.sh customize
```

Or pass an image directly:

```bash
scripts/trae-work-skin.sh customize \
  --image "/absolute/path/to/image.png" \
  --name "我的 TRAE 主题" \
  --accent "#e25563" \
  --secondary "#36b8c8" \
  --highlight "#f3c96a"
```

Prefer a horizontal image around 2560 × 1440, at least 2000 px wide, and at most 50 MB. Put main subjects on the right and keep the left/center reading lane quiet. Accepted source formats include PNG, JPEG, HEIC, TIFF, and macOS-readable WebP. Do not reuse a WorkBuddy 3.5:1 poster or a Codex decoration asset as this background.

## Create a new preset

Read [references/theme-schema.md](references/theme-schema.md) completely. Scaffold an editable copy instead of changing the installed Skill:

```bash
scripts/trae-work-skin.sh scaffold "/absolute/workspace/path/TRAE-Work-Dream-Skin"
```

Add the preset and scoped CSS in that copy. Capture a native DOM snapshot or inspect the live DOM before writing selectors. Cover both legacy landing pages and the current China `Work/Code/Design` home: top tabs, new task, sidebar groups, main title, composer, workspace strip, quick-action tabs, case panel, conversation pages, selected/hover/disabled states, and narrow windows. Preserve unrelated changes, run tests, finish packaging offline, then hot-apply and verify visually.

## Verify

Always verify after installation, customization, or a preset change:

```bash
scripts/trae-work-skin.sh verify "/absolute/path/trae-work-theme.png"
```

Inspect the screenshot and confirm readable contrast for nested native labels, visible native controls, a clickable composer, no overflow, and decorative layers with `pointer-events: none`. A JSON pass is insufficient when text is dark-on-dark, light-on-light, clipped, or covered. Verify the main title, all sidebar rows, active mode, composer placeholder, workspace/model strip, and all quick-action labels at live size.

## Restore

```bash
scripts/trae-work-skin.sh restore
```

Clarify that Restore does not delete tasks, projects, chats, or desktop launchers.

## Relaunch persistence

Successful install, start, preset, and customize commands register TRAE with the event-driven desktop skin guard. Register the current installed theme explicitly with:

```bash
scripts/trae-work-skin.sh persist
```

The guard listens for a real TRAE launch. It hot-reapplies first when the configured loopback endpoint is available. A normal Dock/Finder launch without that endpoint receives one controlled theme recovery restart. The recovery launch is ignored by a per-platform lock and cooldown. The guard never launches TRAE after the user quits and never polls.

Every delivered project must include a short Chinese/English launch guide stating: launch TRAE normally from Dock/Finder; wait for a possible one-time recovery instead of opening it repeatedly; run `persist` after changing the installed theme; run `doctor` before repair; save work before any manually authorized restart. Verify both the landing page and a real conversation page, including white editor text, visible placeholder text, caret contrast, nested labels, and controls.

## Build an installation ZIP

```bash
scripts/trae-work-skin.sh build-zip "/absolute/path/TRAE Work Dream Skin.zip"
scripts/trae-work-skin.sh build-zip "/absolute/path/Pixel 8-Bit.zip" pixel-8bit
```

Inspect the archive and report its SHA-256 checksum.

## Validate

Run after changing scripts, CSS, presets, packaging, or Skill structure:

```bash
scripts/trae-work-skin.sh test
python3 /path/to/skill-creator/scripts/quick_validate.py .
```
