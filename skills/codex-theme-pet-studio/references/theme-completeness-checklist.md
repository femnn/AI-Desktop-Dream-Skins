# Complete Theme Acceptance Matrix

Use this after reading `theme-contract.md`. A pack is not complete merely because its wallpaper and palette load.

## Visual inventory

- Pure 16:9 wallpaper: no baked UI, unintended props, malformed subjects, duplicate limbs, logos, or unreadable text.
- Header: theme mark, title, status, and switch entry.
- Sidebar: background, native labels, primary actions, project rows, footer, functional icon system, selected icon, hover and disabled states.
- Home: hero, all four action cards, card typography, card icons, and distinct expressions when the design calls for characters.
- Task page: readable conversation surfaces, tool/result blocks, attachments, scroll states, and background contrast.
- Composer: border, background, placeholder, project selector, permissions, model, microphone, send button, focus and disabled states.
- Independent decoration: separate asset and pointer-inert layer; fully visible; no clipping; no control obstruction; responsive placement.
- Pet: matching subject, correct v2 atlas, distinct states, clean transparency, and no unrequested anatomy.
- Contrast: inspect computed colors for nested native labels, not only their parent containers. Selected light rows need dark text; dark panels need light text; the workspace/model strip under the composer must remain legible.
- Icon identity: app, sidebar action, selected row, four cards, composer entry, and decoration must not all reuse one generic badge.

## Required verification

1. Run `validate_pack.py` and `audit_theme_completeness.py` before activation.
2. Inspect the real Codex DOM before using positional selectors such as `nth-child`; never infer wrapper structure from a screenshot.
3. Capture home and task screenshots after live injection. If repeated icons should differ, verify their computed pseudo-element content or visual output is actually distinct.
4. Check current, narrow, and short windows. Decorations must remain complete or hide safely.
5. Confirm native controls remain clickable and text contrast remains readable over the wallpaper.
5.1. Check the live-size card expressions, not just the source images; reject four faces that differ only by barely visible pupils.
6. Activate only after all production steps finish. Hot-reapply through CDP; do not close Codex during asset production.
7. Test one normal relaunch and A → B → A switching. Reject restart loops and half-switched theme/pet state.

Record screenshots, the pack audit JSON, live injector verification, pet contact sheet, and switch log in the project validation folder.
