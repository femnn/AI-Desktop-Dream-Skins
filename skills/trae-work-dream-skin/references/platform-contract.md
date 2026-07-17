# TRAE Work platform contract

## Host and runtime

- macOS global apps: `com.trae.solo.app` and `com.trae.work.app`.
- macOS China app: `cn.trae.solo.app`, commonly `/Applications/TRAE SOLO CN.app`.
- Default Dream Skin port: `9355` on loopback.
- Verify the official signature and expected team ID; never weaken signature checks to add a new app variant.
- Never modify the `.app`, `app.asar`, Resources, or signature.

## Artwork

- Use a horizontal image at least 2000 px wide; 2560 × 1440 is the preferred working canvas.
- Put important subjects on the right. Keep left and central reading lanes low-detail because the current Work page centers the title and composer.
- Do not bake UI, small text, logos, icons, card labels, or composer controls into the background.

## Current page inventory

Support the current Work/Code/Design page as well as legacy home structures. Inspect current semantic classes and computed styles for:

- Top mode tabs and selected mode.
- New task, skills/automation, group headings, project rows, scroll shadows, and account footer.
- Main title including split nested spans such as `Work` and `with TRAE`.
- Composer, placeholder, attachment controls, workspace strip, model, voice, and send.
- Quick-action mode tabs, selected state, cases panel, cards, and hover overlays.
- Conversation/task pages and narrow/short windows.

Treat landing and conversation pages as separate visual contexts. For conversation pages, explicitly style `.solo-lite-chat-panel-container`, the session/message scroller, rich Markdown, tables/code, action bars, and `.chat-input-v2-editor-part`; the native conversation container and editor can stay white even when the outer shell is dark.

Never infer text color from a parent. Native child spans frequently carry their own color declarations and require verified scoped overrides.

## Restart boundary

Tests, packaging, payload validation, and DOM inspection happen before activation. Hot-reapply when a verified endpoint exists. If TRAE is running without CDP, ask the user to save work and authorize one final restart. Do not repeatedly close TRAE while iterating.

After the user opts into persistent themes, the event-driven session guard may recover one later normal launch automatically. It uses a lock and cooldown, ignores the recovery relaunch, and never reopens TRAE after a user quit.
