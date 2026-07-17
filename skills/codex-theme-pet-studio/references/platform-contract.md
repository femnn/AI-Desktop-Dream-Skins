# Codex platform contract

## Output

- A complete Codex pack always combines one Dream Skin theme and one matching desktop pet.
- Keep pack projects and validation evidence in Documents. Installed packs live under `~/Library/Application Support/CodexDreamSkinStudio/packs/`.
- Use a pure 16:9 wallpaper for Codex. It is not interchangeable with WorkBuddy's ultra-wide poster.
- Store one optional photo, disc, sticker, or charm as a separate decoration asset with real alpha and safe padding.

## Theme surface inventory

Cover the top brand/status area, sidebar and all native icons, selected/hover/disabled rows, four home cards and their icon containers, task/conversation surfaces, composer, project/permission/model/microphone/send controls, independent decoration, and responsive states.

When character faces represent card functions, the four silhouettes and expressions must remain distinguishable at live icon size. Do not accept expression differences visible only when zoomed into the source asset.

## Pet boundary

The pet is a separate animated atlas, not a decoration. New pets use v2, 8×11, with 16 observation directions and documented state mapping. Preserve user-specified anatomy literally: do not add feet, limbs, shadows, text, or effects that were not requested.

## Runtime boundary

Complete wallpaper, CSS, icon assets, decoration, pet, pack manifest, validation, switcher, and persistence helper offline. Activate once through the transactional switcher. Never restart Codex during asset iteration. A controlled restart is only a final recovery path when no verified theme endpoint exists.
