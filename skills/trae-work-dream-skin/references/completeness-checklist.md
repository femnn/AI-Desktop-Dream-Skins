# TRAE complete-theme checklist

- Background is horizontal, sharp, right-weighted, free of baked UI/text, and does not hide the central composer.
- Brand, status, title, subtitle, and theme quote are readable.
- Work/Code/Design tabs have distinct normal and selected states.
- Sidebar icons, new task, skills/automation, group titles, projects, scroll shadow, and account footer are readable.
- Composer placeholder, attachments, workspace selector, model, voice, send, focus, and disabled states are themed.
- All quick-action tabs and case cards are readable; selected light-green elements use dark text.
- White native panels use dark text; dark themed panels use light text. Inspect nested spans and SVG current color.
- Task/conversation pages receive a complete route-specific treatment: outer panel, top bar, message scroller, Markdown, tables/code, action bar, editor surface and controls are themed and readable; decorative chrome has `pointer-events: none`.
- Current, narrow, and short windows show no overlap or document overflow.
- Engine tests, payload checks, live verification, screenshot review, restore, and preset-specific ZIP inspection pass.
- Theme work causes no intermediate restarts. One final restart is allowed only with user authorization when hot-reapply is unavailable.
- Event-driven persistence is installed; close → normal open restores the current theme once without a loop.
