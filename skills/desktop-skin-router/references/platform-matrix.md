# Platform matrix

| Host | Skill | Main artifact | Artwork geometry | Pet | Runtime | Default live behavior |
| --- | --- | --- | --- | --- | --- | --- |
| Codex Desktop | `codex-theme-pet-studio` | theme-and-pet pack | responsive 16:9 wallpaper plus optional separate decoration | Required for complete packs | Codex Dream Skin + pet overlay | Finish offline, then transactionally hot-switch; restart only as recovery |
| Tencent WorkBuddy | `workbuddy-theme-studio` | `.codedrobe-theme` | measured ultra-wide poster; verified reference 1792×512 | None | CodeDrobe Core, port 9336 | DOM snapshot first, hot-apply when endpoint exists |
| TRAE Work / TRAE SOLO | `trae-work-dream-skin` | preset-specific installer ZIP | horizontal ≥2000 px, usually 2560×1440, subjects right | None | TRAE Dream Skin, port 9355 | Complete offline, hot-reapply; one authorized restart only if endpoint missing |

Shared research may define palette, materials, and subjects. Platform output must remain separate because layout, package schema, CSS landmarks, validation, and restart semantics differ.

Codex uses its own native menu/session restoration. WorkBuddy and TRAE share the event source but retain separate registration, locks, cooldowns, logs, ports, and recovery commands through `DesktopSkinSessionGuard`.
