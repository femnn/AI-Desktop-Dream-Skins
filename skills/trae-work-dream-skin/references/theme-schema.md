# Theme preset reference

Read this file only when creating or editing a bundled preset.

## Directory

```text
presets/<preset-name>/
├── theme.json
└── <image>.png
```

Use lowercase letters, numbers, and hyphens for the preset name. Keep the image beside `theme.json`. Supported runtime formats are PNG, JPEG, and WebP; keep the prepared image at or below 16 MB.

## Configuration

```json
{
  "schemaVersion": 1,
  "id": "pixel-8bit",
  "name": "PIXEL WORK 8-BIT",
  "visualStyle": "pixel-8bit",
  "brandSubtitle": "TRAE WORK · PIXEL MODE",
  "tagline": "把大任务拆成小关卡，一个一个完成。",
  "statusText": "STAGE 1 · READY",
  "quote": "PRESS START",
  "image": "pixel-8bit-demo.png",
  "colors": {
    "background": "#758df1",
    "panel": "#fff8db",
    "panelAlt": "#ffd080",
    "accent": "#e86f25",
    "accentAlt": "#ff9847",
    "secondary": "#2fba16",
    "highlight": "#ffb34d",
    "text": "#141414",
    "muted": "#484848",
    "line": "rgba(20, 20, 20, .52)"
  }
}
```

`visualStyle` selects CSS scoped by `data-trae-dream-theme`. Reuse `arcade-modern` when only the image, text, and colors change. Add a new scoped CSS section only when the layout changes materially.

## Workflow

1. Scaffold an editable engine copy.
2. Add an image that may legally be redistributed.
3. Record its source and license in `NOTICE.md`.
4. Add `theme.json` and narrowly scoped CSS if needed.
5. Keep decorative layers at `pointer-events: none`.
6. Extend `tests/run-tests.sh`.
7. Run tests, apply the preset, and verify a live screenshot.
8. Build and inspect a preset-specific ZIP.

For current TRAE Work China builds, the preset is incomplete until the Work/Code/Design tabs, nested title spans, sidebar children, composer workspace strip, quick-action tabs, and cases panel have been visually checked. A wallpaper plus palette is not a complete preset.

Never claim third-party artwork is covered by the software license.
