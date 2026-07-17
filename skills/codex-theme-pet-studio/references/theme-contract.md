# Dream Skin Theme Contract

`theme/theme.json` uses schema version 1 and includes:

- `id`, `name`
- `brandSubtitle`, `tagline`, `projectPrefix`, `projectLabel`, `statusText`, `quote`
- `image`: a basename inside the theme directory
- `decoration`: an optional basename for one transparent or rectangular independent decoration asset
- `colors`: `background`, `panel`, `panelAlt`, `accent`, `accentAlt`, `secondary`, `highlight`, `text`, `muted`, `line`

Theme images must be PNG, JPEG, or WebP and no larger than 16 MB. The optional decoration is rendered in a pointer-inert responsive layer and must never be baked into the wallpaper or overlap the composer.

`theme/theme.css` is optional, UTF-8, and no larger than 256 KB. It loads after the shared Dream Skin stylesheet. Scope rules under `html.codex-dream-skin` and theme-specific selectors such as:

```css
html.codex-dream-skin[data-dream-theme="astro-bot"] { ... }
```

Do not hide, replace, or intercept native controls. Prefer CSS variables, color, border, radius, background, shadow, and pseudo-element decoration. Theme every icon container coherently while preserving distinct selected, hover, disabled, and active states. Keep task pages readable and support narrow windows.
