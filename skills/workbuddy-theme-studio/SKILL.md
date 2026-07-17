---
name: workbuddy-theme-studio
description: Create, package, apply, verify, repair, and restore complete Tencent WorkBuddy desktop themes with CodeDrobe Core on macOS. Use when a user asks for a WorkBuddy skin, WorkBuddy poster or hero, themed WorkBuddy icons/cards/composer, transparent cartridge/controller decorations, a .codedrobe-theme package, DOM compatibility repair, or hot theme switching. Do not use Codex wallpaper dimensions, Codex pets, or TRAE selectors for WorkBuddy.
---

# WorkBuddy Theme Studio

Build a WorkBuddy-specific `.codedrobe-theme`. Keep the project in `~/Documents/WorkBuddy/<Theme Name>/` and use `scripts/workbuddy-theme.sh` for deterministic operations.

## Dependencies

Read and follow the built-in `imagegen` skill before generating artwork. Read [references/platform-contract.md](references/platform-contract.md) before designing and [references/completeness-checklist.md](references/completeness-checklist.md) before activation.

Use CodeDrobe Core `0.3.0`. Prefer `/Users/kangkang/Documents/WorkBuddy/CodeDrobe-core`; never copy its JavaScript runtime into this skill.

## Workflow

1. Research the subject from primary sources. Record palette, materials, signature hardware/characters, separate accessory ideas, and prohibited elements.
2. Create a new Documents project. Capture a read-only native DOM snapshot before writing CSS:

```bash
scripts/workbuddy-theme.sh snapshot /absolute/project
```

3. Measure the actual `.wb-home-header` slot from the snapshot. Generate a dedicated WorkBuddy poster, not a Codex 16:9 wallpaper. The currently verified wide hero source is 1792 × 512; preserve the measured ratio when the current app differs. Keep important objects on the right and the title/composer reading lane quiet.
4. Generate independent transparent assets for every requested slot: cartridge, controller, sticker, photo, or charm. Do not bake accessories into the hero when CSS must position them separately. Verify alpha edges and remove unintended backgrounds.
5. Write `theme.json` and `workbuddy.css`. Use named images and `--codedrobe-image-<id>`. Scope every rule under `html.codedrobe-workbuddy-skin` or the runtime theme attribute. Preserve native controls and disable pointer events on decoration.
6. Declare theme-specific DOM verification for sidebar, workspace, composer, home hero, mode tabs, quick actions, accessory slots, and conversation context. Prefer stable semantic classes from the snapshot; reject localized text selectors, positional selectors, generated hashes, and deep wrapper chains.
7. Pack and inspect offline:

```bash
scripts/workbuddy-theme.sh pack /absolute/project
```

8. Finish all artwork, CSS, manifest, and offline checks before touching the live app. If WorkBuddy already has a valid CDP endpoint, hot-apply. Never restart it during production. If a restart is genuinely required, stop and ask the user to save work and authorize one final restart.
9. Apply, verify, and inspect the screenshot:

```bash
scripts/workbuddy-theme.sh apply /absolute/project
scripts/workbuddy-theme.sh verify /absolute/project
```

10. Retain source assets, package, DOM snapshot, verification JSON, and screenshots inside the project. Successful `apply` registers the package with the event-driven persistence guard. Register an already-applied package with `scripts/workbuddy-theme.sh persist /absolute/project`. Restore with `scripts/workbuddy-theme.sh restore /absolute/project`.

## Relaunch persistence

The persistence guard listens for WorkBuddy launch events. It verifies the registered package first, hot-reapplies when port 9336 is already available, and permits exactly one controlled recovery restart only when the endpoint is absent. The relaunch caused by recovery is ignored by an operation lock and cooldown. The guard never launches WorkBuddy after the user quits and never polls for the process. Do not replace it with a periodic LaunchAgent.

Every delivered project must include a short Chinese/English launch guide stating: launch WorkBuddy normally from Dock/Finder; wait for a possible one-time recovery instead of opening it repeatedly; use `persist` after changing the package path; use `status` before repair; save work before any manually authorized restart. Preflight validation must inspect the package and native DOM contract without requiring runtime-only injected markers such as a theme root class.

## Acceptance

- The poster fits WorkBuddy's measured hero slot without stretching or Codex-style cropping.
- Sidebar, Work/Code/Design or current navigation, hero, tabs, cards, composer, workspace selector, conversation page, icons, hover/selected/disabled states, and narrow layout form one system.
- Every requested accessory is a separate correctly keyed transparent asset.
- Text remains readable on both white native surfaces and dark themed surfaces.
- DOM probe and screenshot verification pass; decorative layers are pointer-inert and no controls overlap.
- Apply and restore do not modify `WorkBuddy.app` or `app.asar`.
- Close → normal open restores the registered theme once without a restart loop.
