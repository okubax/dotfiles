# Nord — the arctic, north-bluish colorscheme for the sway desktop

A port of [Nord](https://www.nordtheme.com/) into the same per-app structure
Zephyr and Harmattan use. Nord is a muted, low-saturation palette organized
into four named ranges: Polar Night (dark neutrals), Snow Storm (light
neutrals), Frost (blue/cyan accents) and Aurora (red/orange/yellow/green/
purple accents).

Three variants: `dark` (classic, canonical Nord — Polar Night backgrounds,
Snow Storm text), `dusk` (a dimmer, lower-contrast dark theme, shifted one
Polar Night step lighter), `light` (unofficial — Nord ships no light
variant, so this inverts which range plays background vs. text, the same
approach several community Nord Light ports take).

## Where the colors come from

Every value is Nord's own, unmodified — nothing here is invented except
two interpolated midpoints (documented per-variant in each `palette.md`),
needed because Nord's four Polar Night / three Snow Storm shades don't
quite cover the five background roles this app set wants.

- **Backgrounds/text**: Polar Night (`nord0`–`nord3`) and Snow Storm
  (`nord4`–`nord6`), swapped between the two ranges depending on variant.
- **Accent (primary)**: `nord8`, `#88C0D0` — the signature Nordic light
  blue, held identical across all three variants.
- **Link**: Frost's other blues (`nord9`/`nord10`), weighted per variant
  for contrast — same pattern as Zephyr's `link`.
- **Red/green/yellow/purple/orange**: Aurora's five accents
  (`nord11`/`nord14`/`nord13`/`nord15`/`nord12`), held identical across all
  three variants — same discipline every theme here follows, so state
  colors (swaylock ring, mako urgency, diff colors) mean the same thing
  regardless of which variant is active.
- **Cyan**: Frost's `nord7`, held identical across all three variants.

Full swatch list: see `dark/palette.md`, `dusk/palette.md` and
`light/palette.md`.

## Wallpapers

Desktop wallpaper and swaylock's lock-screen background are Nord-matched,
generated with `~/dotfiles/bin/palette_wallpaper.py` (extended with
`nord_light`/`nord_dusk`/`nord_dark` palettes) and stored in
`~/.img/wallpapers/nord_{light,dusk,dark}_{desktop,lockscreen}.png`. Wired
per-variant: `nord/{light,dusk,dark}/sway.conf` sets `output * bg ...`,
`nord/{light,dusk,dark}/swaylock.conf` sets `image=...` — so
`nord-theme light|dusk|dark` switches the wallpaper along with everything
else.

## Layout

```
nord/
  light/   — one file per app, Nord Light values, in that app's native syntax
  dusk/    — same, Nord Dusk values
  dark/    — same, Nord Dark (classic/canonical) values
  active -> light | dusk | dark   (symlink; this is what every app config points at)
```

Same wiring as Zephyr/Harmattan/Solarized — `sway/config`, `mako/config`,
`waybar/style.css`, `wofi/style.css` each include/`@import`
`<theme>/active/...`; `swaylock` has no include mechanism so `nord-theme`
copies the variant's config over `swaywm/swaylock/config` directly; kitty
and vim pick their colorscheme independently as ordinary toggle options
(`kitty/colors/nord_{light,dusk,dark}.conf`, `vim/colors/nord_{light,dusk,
dark}.vim`).

## Coexisting with other themes

Only one theme family drives sway/mako/waybar/wofi's chrome at a time —
whichever of `zephyr-theme`/`harmattan-theme`/`solarized-theme`/
`nord-theme`/`catppuccin-theme` ran most recently. Each script rewrites the
shared `swaywm/<family>/active/...` include paths to point at itself. kitty
and vim are unaffected — every theme's variants sit side by side as
ordinary flat toggle/colorscheme options.

## Switching

```
nord-theme light    # switch everything (except vim) to Nord Light
nord-theme dusk     # switch everything (except vim) to Nord Dusk
nord-theme dark     # switch everything (except vim) to Nord Dark
nord-theme toggle   # cycle light -> dusk -> dark -> light
nord-theme status   # show which variant is active
```

Reloads sway (`swaymsg reload`), mako (`makoctl reload`) and waybar
(`SIGUSR2`) itself; kitty picks up the new include on next launch, or press
ctrl+shift+F5 in an open kitty window to reload it live. For vim, run
`:colorscheme nord_dusk` (or `_light`/`_dark`) in a running session, or
change the `colorscheme` line in `vimrc` if you want it to be the new
default.

## A note on the old `kitty/colors/nord.conf`

This repo already had a flat, standalone `nord.conf` for kitty (predating
this integration) — it's left in place as-is (the user only asked for the
old Catppuccin files to be removed, not Nord's). It's unrelated to this
`nord/` directory; the two can coexist as separate ways to get Nord colors
in kitty specifically.
