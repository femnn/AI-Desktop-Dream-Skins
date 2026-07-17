# WorkBuddy platform contract

## Runtime

- Host: Tencent WorkBuddy, adapter id `workbuddy`, default CDP port `9336`.
- Engine: `@codedrobe/core@0.3.0` or the pinned local source checkout.
- Package: UTF-8 JSON `.codedrobe-theme`, maximum 30 MB, declarative CSS and embedded PNG/JPEG/WebP/GIF only. External `url(...)`, `@import`, and JavaScript are forbidden.
- Source manifest: `theme.json`; target CSS: `workbuddy.css`; output: `build/<id>-<version>.codedrobe-theme`.

## Artwork

- WorkBuddy hero is a very wide poster slot. Measure it from a native DOM snapshot; the verified reference source is 1792 × 512 (3.5:1), not Codex's 16:9 canvas.
- Keep title and composer lanes quiet. Put characters, consoles, docks, or hardware on the right unless the measured layout indicates otherwise.
- Use one named image per independent UI object. Example keys: `hero`, `cartridge`, `controller`, `photo`, `texture`.
- Transparent assets must have real alpha, complete silhouettes, safe edge padding, and no black/white matte.

## Stable landmarks

Use the current snapshot to confirm, with these known semantic fallbacks:

- Sidebar: `.conversation-sidebar`
- Workspace: `.teams-main-content`
- Composer: `.wb-home-composer` or `[role='textbox'][contenteditable='true']`
- Home: `.wb-home-page`, `.wb-home-header`, `.wb-scene-tabs`, `.quick-actions__list`
- Conversation: `.project-detail-view--task-detail`, `.project-detail-view__content`, `.project-detail-view__input-area`, and `.task-chat-topbar-breadcrumb`

Do not assume these are unchanged after an app update. Re-snapshot when required landmarks fail.

Treat home and conversation as separate route contexts. Global verification must only contain shell landmarks that exist on every route. Home-only cards are recommended when the application can legitimately hide them; they must never block persistence recovery. Conversation verification must cover the top bar, message surface, input surface, readable rich text/tables/code, and controls.

Compatibility requirements run before theme injection. Never require an injected marker such as `html.codedrobe-host-workbuddy`, a theme data attribute, or a theme-created decoration in the global/route preflight. Confirm those only through the post-apply `installed`, `themeId`, `version`, and `stylePresent` result.

## Restart boundary

Snapshot, probe, pack, inspect, and CSS work are offline or read-only. Apply hot when a verified endpoint exists. Do not pass `--restart-existing` automatically. A restart is a user-authorized recovery step after all production work is complete.

For later normal launches, the installed event-driven session guard may perform one automatic recovery restart because the user explicitly chose persistent themes. It uses a per-platform lock and cooldown and does not reopen WorkBuddy after a quit.
