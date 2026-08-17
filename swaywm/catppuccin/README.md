# Catppuccin — the pastel colorscheme for the sway desktop

A full-desktop integration of [Catppuccin](https://github.com/catppuccin)
into the same per-app structure Zephyr and Harmattan use. This repo already
had Catppuccin available as flat drop-in files for kitty and vim (predating
this integration, and now removed — see below); this `catppuccin/`
directory replaces that with the same sway/mako/waybar/wofi/swaylock
coverage every other theme here gets, plus a `catppuccin-theme` switcher.

Catppuccin ships **four** official flavors (Latte, Frappé, Macchiato,
Mocha — lightest to darkest); this integration uses three of them to fit
the light/dusk/dark shape everything else here follows:

- `light` = **Latte**
- `dusk` = **Macchiato**
- `dark` = **Mocha**

Frappé (the flavor between Latte and Macchiato) isn't part of this
integration — it's still available standalone via
`bin/palette_wallpaper.py --palette frappe` for wallpaper generation.

## Where the colors come from

Every value is upstream Catppuccin's own, unmodified — nothing here is
interpolated or invented, unlike Zephyr's `border` or Harmattan's warm
neutrals.

**Important difference from every other theme in this repo**: Zephyr,
Harmattan, Solarized and Nord all hold their accent hues constant across
light/dusk/dark and only vary the neutrals. Catppuccin does not — Mocha,
Macchiato and Latte each have **genuinely different accent hues** upstream
(Mocha's blue `#89B4FA` vs. Latte's blue `#1E66F5`, for example), not just
different backgrounds. This port stays faithful to that rather than
flattening it for cross-theme consistency — see each variant's
`palette.md` for the full swatch list and official Catppuccin role names
(`base`/`mantle`/`surface0-2`/`text`/`subtext0`/`overlay0`/accent names).

## Wallpapers

Desktop wallpaper and swaylock's lock-screen background are
Catppuccin-matched, generated with `~/dotfiles/bin/palette_wallpaper.py`
using its existing `mocha`/`macchiato`/`latte` palettes (already present
before this integration) and stored in
`~/.img/wallpapers/catppuccin_{light,dusk,dark}_{desktop,lockscreen}.png`.
Wired per-variant: `catppuccin/{light,dusk,dark}/sway.conf` sets
`output * bg ...`, `catppuccin/{light,dusk,dark}/swaylock.conf` sets
`image=...` — so `catppuccin-theme light|dusk|dark` switches the wallpaper
along with everything else.

## Layout

```
catppuccin/
  light/   — one file per app, Latte values, in that app's native syntax
  dusk/    — same, Macchiato values
  dark/    — same, Mocha values
  active -> light | dusk | dark   (symlink; this is what every app config points at)
```

Same wiring as Zephyr/Harmattan/Solarized/Nord — `sway/config`,
`mako/config`, `waybar/style.css`, `wofi/style.css` each include/`@import`
`<theme>/active/...`; `swaylock` has no include mechanism so
`catppuccin-theme` copies the variant's config over
`swaywm/swaylock/config` directly; kitty and vim pick their colorscheme
independently as ordinary toggle options
(`kitty/colors/catppuccin_{light,dusk,dark}.conf`,
`vim/colors/catppuccin_{light,dusk,dark}.vim`).

## Coexisting with other themes

Only one theme family drives sway/mako/waybar/wofi's chrome at a time —
whichever of `zephyr-theme`/`harmattan-theme`/`solarized-theme`/
`nord-theme`/`catppuccin-theme` ran most recently. Each script rewrites the
shared `swaywm/<family>/active/...` include paths to point at itself. kitty
and vim are unaffected — every theme's variants sit side by side as
ordinary flat toggle/colorscheme options.

## Switching

```
catppuccin-theme light    # switch everything (except vim) to Latte
catppuccin-theme dusk     # switch everything (except vim) to Macchiato
catppuccin-theme dark     # switch everything (except vim) to Mocha
catppuccin-theme toggle   # cycle light -> dusk -> dark -> light
catppuccin-theme status   # show which variant is active
```

Reloads sway (`swaymsg reload`), mako (`makoctl reload`) and waybar
(`SIGUSR2`) itself; kitty picks up the new include on next launch, or press
ctrl+shift+F5 in an open kitty window to reload it live. For vim, run
`:colorscheme catppuccin_dusk` (or `_light`/`_dark`) in a running session,
or change the `colorscheme` line in `vimrc` if you want it to be the new
default.

## What replaced the old flat integration

Before this, Catppuccin was four standalone drop-in files for kitty
(`kitty/colors/{latte,frappe,macchiato,mocha}.conf`) and vim
(`vim/colors/catppuccin_{latte,frappe,macchiato,mocha}.vim`), with no
sway/waybar/mako/wofi/swaylock coverage. Those files have been removed —
`kitty/colors/catppuccin_{light,dusk,dark}.conf` and
`vim/colors/catppuccin_{light,dusk,dark}.vim` (this directory's Latte/
Macchiato/Mocha mapping) replace them. The ZSH syntax-highlighting plugin
(`zsh/plugins/catppuccin_*-zsh-syntax-highlighting.zsh`) is unrelated
shell-syntax-color infrastructure, not a desktop colorscheme, and was left
untouched.
