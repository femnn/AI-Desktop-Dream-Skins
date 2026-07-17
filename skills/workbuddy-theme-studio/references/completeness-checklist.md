# WorkBuddy complete-theme checklist

Review every item against a live screenshot.

- Hero uses the measured WorkBuddy poster ratio and has no baked UI or unintended text.
- Top bar and sidebar have readable labels, native icons, selected, hover, disabled, project, and account states.
- Home title, subtitle, status, mode tabs, all quick-action cards, and their icons are visually distinct.
- Composer includes placeholder, attachment, workspace, permission/model, voice, send, focus, and disabled states.
- Accessory slots use separate transparent assets and remain fully visible without covering controls.
- Conversation route has its own complete theme treatment: top bar, message surface, rich text, tables/code, tool/results, attachments, input, model/permission controls, and disabled states remain readable.
- Verify home and conversation as separate route contexts. A missing optional home card must not make persistence recovery fail on another valid route.
- Preflight requirements contain only native application landmarks; injected root classes and theme-created elements are checked only after apply.
- Current, narrow, and short window screenshots show no clipping or overlap.
- Theme verification declares required and contextual landmarks.
- `codedrobe theme inspect` has no unresolved errors; lint warnings are reviewed, not ignored blindly.
- `codedrobe verify` passes and `codedrobe restore` returns the native interface.
- Event-driven persistence is registered to the final absolute package path; a close/open test produces one recovery and no loop.
