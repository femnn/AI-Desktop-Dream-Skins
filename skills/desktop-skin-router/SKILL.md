---
name: desktop-skin-router
description: Route desktop skin requests to the correct platform-specific workflow for Codex, Tencent WorkBuddy, or TRAE Work. Use when a user asks generally for an AI desktop theme, mentions several platforms, wants the same subject adapted across platforms, or the target app is ambiguous. Prevents mixing Codex theme-and-pet packs, WorkBuddy CodeDrobe posters, and TRAE Work presets.
---

# Desktop Skin Router

Identify the host before generating any asset. Read [references/platform-matrix.md](references/platform-matrix.md), then use exactly the matching platform skill:

- Codex → `codex-theme-pet-studio`
- WorkBuddy/Coddy → `workbuddy-theme-studio`
- TRAE Work/TRAE SOLO → `trae-work-dream-skin`

If one request targets multiple platforms, create separate projects and run each platform workflow independently. Reuse research and palette, but regenerate/crop artwork to each measured slot and write separate DOM contracts and CSS. Never share selectors, manifests, launch ports, restart logic, or package formats across platforms.

Ask for clarification only when the app cannot be inferred from the request or local installation. Otherwise route and proceed.

## Relaunch persistence

Use `scripts/install_persistence_guard_macos.sh` to register the active TRAE or WorkBuddy theme. The native guard observes launch events, never polls, and never opens an app after the user quits. Because normal Dock/Finder launches omit CDP, it may perform exactly one controlled recovery restart; per-platform locks and cooldowns suppress the recovery launch and failures.

Check registrations and recovery counts with `scripts/status_persistence_guard_macos.sh`.

At every app launch, prefer this order: verify the active theme, hot-reapply through an existing loopback endpoint, verify again, and only then allow one controlled recovery restart when the endpoint is absent. Never restart Codex, TRAE, or WorkBuddy while producing assets or editing CSS. Finish all files first and reserve restart verification for the final acceptance pass.

Tell the user that a normal first launch may briefly recover once, that they should wait for the themed window instead of opening the app repeatedly, and that the status script is the first diagnostic when a theme does not appear.
