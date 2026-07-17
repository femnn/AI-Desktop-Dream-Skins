# Theme Pack Contract

Each installed pack lives at:

```text
~/Library/Application Support/CodexDreamSkinStudio/packs/<id>/
├── pack.json
├── theme/
│   ├── theme.json
│   ├── background.png|jpg|webp
│   ├── decoration.png|jpg|webp (optional)
│   └── theme.css
└── pet/
    ├── pet.json
    └── spritesheet.webp
```

`pack.json`:

```json
{
  "schemaVersion": 1,
  "id": "example-pack",
  "name": "Example Pack",
  "description": "One short sentence.",
  "theme": {"path": "theme"},
  "pet": {
    "id": "example-pet",
    "path": "pet",
    "selectedAvatarId": "custom:example-pet"
  },
  "compatibility": {
    "platform": "darwin",
    "minSkinVersion": "1.1.1"
  }
}
```

Rules:

- IDs use lowercase letters, digits, and hyphens.
- All paths are relative, remain inside the pack, and point to directories.
- `selectedAvatarId` must equal `custom:<pet.id>`.
- Theme and pet manifests remain authoritative for their assets.
- `theme.json` may declare one optional basename-only `decoration` image. It is rendered as a separate pointer-inert layer, never baked into the wallpaper.
- Pet v1 is accepted only for imported existing packs. New pets use v2.
