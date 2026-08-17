# Solarized — Ethan Schoonover's precision colorscheme for the sway desktop

A port of [Solarized](https://ethanschoonover.com/solarized/) into the same
per-app structure Zephyr and Harmattan use. Solarized is one of the most
widely ported terminal/editor colorschemes ever made, precisely because its
sixteen values were derived mathematically (via CIELAB colorspace) so a
fixed set of eight accent hues reads correctly against two different
neutral tone ranges — light and dark. **Two variants only** — `dark` and
`light` — there's no official Solarized "dusk"-equivalent mid-tone, and
inventing one would go against the whole point of a deliberately
minimal, precisely-tuned 16-value palette.

## Where the colors come from

Every value here is Ethan Schoonover's own, unmodified:

- **Neutrals**: the eight `base03`–`base3` content tones. Dark mode uses
  `base03`/`base02` for backgrounds and `base0`/`base1` for text; Light
  mode inverts this, using `base3`/`base2` for backgrounds and
  `base00`/`base1` for text. This swap — not a separate palette — is the
  entire mechanism behind Solarized's light/dark switch.
- **Accents**: all eight hues (yellow, orange, red, magenta, violet, blue,
  cyan, green) are held identical between Dark and Light, unlike Zephyr's
  `link` or Harmattan's neutral-only variation — this consistency is
  Solarized's signature design property, not something added here.
- The two values with no official Solarized name (`bg-panel`, `bg-header`
  in this port's schema) are hand-interpolated midpoints, since Solarized
  only defines two canonical background shades per mode and this app set
  needs a few more layers than that.

Full swatch list: see `dark/palette.md` and `light/palette.md`.

## Wallpapers

Desktop wallpaper and swaylock's lock-screen background are
Solarized-matched, generated with `~/dotfiles/bin/palette_wallpaper.py`
(extended with `solarized_dark`/`solarized_light` palettes) and stored in
`~/.img/wallpapers/solarized_{dark,light}_{desktop,lockscreen}.png`. Wired
per-variant: `solarized/{dark,light}/sway.conf` sets `output * bg ...`,
`solarized/{dark,light}/swaylock.conf` sets `image=...` — so
`solarized-theme dark|light` switches the wallpaper along with everything
else.

## Layout

```
solarized/
  dark/    — one file per app, Solarized Dark values, in that app's native syntax
  light/   — same, Solarized Light values
  active -> dark | light   (symlink; this is what every app config points at)
```

Same wiring as Zephyr/Harmattan — `sway/config`, `mako/config`,
`waybar/style.css`, `wofi/style.css` each include/`@import`
`<theme>/active/...`; `swaylock` has no include mechanism so
`solarized-theme` copies the variant's config over `swaywm/swaylock/config`
directly; kitty and vim pick their colorscheme independently as ordinary
toggle options (`kitty/colors/solarized_{dark,light}.conf`,
`vim/colors/solarized_{dark,light}.vim`).

## Coexisting with other themes

Only one theme family drives sway/mako/waybar/wofi's chrome at a time —
whichever of `zephyr-theme`/`harmattan-theme`/`solarized-theme`/
`nord-theme`/`catppuccin-theme` ran most recently. Each script rewrites the
shared `swaywm/<family>/active/...` include paths to point at itself. kitty
and vim are unaffected — every theme's variants sit side by side as
ordinary flat toggle/colorscheme options.

## Switching

```
solarized-theme dark    # switch everything (except vim) to Solarized Dark
solarized-theme light   # switch everything (except vim) to Solarized Light
solarized-theme toggle  # flip dark <-> light
solarized-theme status  # show which variant is active
```

Reloads sway (`swaymsg reload`), mako (`makoctl reload`) and waybar
(`SIGUSR2`) itself; kitty picks up the new include on next launch, or press
ctrl+shift+F5 in an open kitty window to reload it live. For vim, run
`:colorscheme solarized_dark` (or `_light`) in a running session, or change
the `colorscheme` line in `vimrc` if you want it to be the new default.
