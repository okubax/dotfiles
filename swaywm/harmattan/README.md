# Harmattan — an original colorscheme for the sway desktop

Harmattan is a from-scratch companion to [Zephyr](../zephyr/README.md), for
when you want a genuinely different look rather than another Breeze-matched
variant. Where Zephyr is cool-toned and traces every value back to KDE's
BreezeLight/BreezeDark, Harmattan has no external source — it's a warm,
dust-toned scheme named for the dry, hazy trade wind that blows south across
West Africa each winter, carrying Saharan dust as far as the Gulf of Guinea.

Three variants, same shape as Zephyr: `light` (sun-bleached sand and dust
haze), `dusk` (a dim, warm mid-tone for low-light work), `dark` (near-black
with the same warm undertone, for full-contrast evening use).

## Where the colors come from

Nowhere but this scheme — there's no upstream palette to track. The design
brief was: warm neutrals instead of the blue-gray family almost every dev
colorscheme reaches for, one confident primary accent instead of many
competing ones, and every accent hue held constant across all three
variants (only the neutrals and `link` shift) so state colors mean the same
thing regardless of which variant is active — the same discipline Zephyr
uses for its own accents.

- **Neutrals** run from sun-bleached ivory (Light) through dusty umber
  (Dusk) to near-black with a warm undertone (Dark) — sand and earth tones
  rather than the cool grays most terminal themes default to.
- **Accent (primary)** is a deep indigo, `#4C5FA6` — a nod to *adire*, the
  Yoruba resist-dye indigo cloth tradition. It's the one color used for
  focus rings, borders, selection, and the swaylock typing-state ring in
  every variant.
- **Red** is terracotta (`#C1502E`), not a stop-sign red — reads as
  "attention" without the alarm-clock urgency.
- **Green** is a muted acacia/olive green (`#6E8C4E`) rather than a bright
  lime, echoing sparse Sahel vegetation instead of a generic "success"
  green.
- **Yellow/orange** is ochre (`#D98A2B`) — dust-in-sunlight, used for the
  neutral/warning/verifying state.
- **Purple** is bougainvillea (`#8B5A8C`) — the flowering vine is common
  across Nigerian gardens and compound walls.
- **Cyan/teal** (`#3E8E8A`) is the rare cool note: the clear sky that
  briefly reappears when the harmattan haze lifts.
- **`link`** is the one role that isn't held constant — it's a darker
  indigo in Light (for contrast against a pale background) and progressively
  lighter in Dusk/Dark, same approach Zephyr takes with `ForegroundLink`.

Full swatch list: see `light/palette.md`, `dusk/palette.md` and
`dark/palette.md`.

## Wallpapers

Desktop wallpaper and swaylock's lock-screen background are Harmattan-matched,
generated with `~/dotfiles/bin/palette_wallpaper.py` (extended with
`harmattan_light`/`harmattan_dusk`/`harmattan_dark` palettes) and stored in
`~/.img/wallpapers/harmattan_{light,dusk,dark}_{desktop,lockscreen}.png`.
Wired per-variant: `harmattan/{light,dusk,dark}/sway.conf` sets
`output * bg ...`, `harmattan/{light,dusk,dark}/swaylock.conf` sets
`image=...` — so `harmattan-theme light|dusk|dark` switches the wallpaper
along with everything else. See each variant's `palette.md` for exact
generation parameters.

## Layout

```
harmattan/
  light/   — one file per app, Harmattan Light values, in that app's native syntax
  dusk/    — same, Harmattan Dusk values
  dark/    — same, Harmattan Dark values
  active -> light | dusk | dark   (symlink; this is what every app config points at)
```

- `sway/config` includes `<theme>/active/sway.conf`
- `mako/config` includes `<theme>/active/mako.conf`
- `waybar/style.css` `@import`s `<theme>/active/waybar.css`
- `wofi/style.css` `@import`s `<theme>/active/wofi.css`
- `kitty.conf` includes `./colors/harmattan_<variant>.conf` (a flat toggle
  alongside the zephyr_*/nord/macchiato/paradise options already there —
  kitty and vim pick their colorscheme independently of the WM chrome).
- `swaylock` has no include directive — `harmattan-theme` copies
  `harmattan/{light,dusk,dark}/swaylock.conf` straight over
  `swaywm/swaylock/config` when you switch.
- vim doesn't use `active/` at all — `~/.vim/colors/harmattan_light.vim`,
  `harmattan_dusk.vim` and `harmattan_dark.vim` are ordinary standalone
  colorschemes; `vimrc` picks one directly.

## Coexisting with Zephyr

`sway/config`, `mako/config`, `waybar/style.css` and `wofi/style.css` each
include a single `<theme>/active/...` path — only one theme *family* (Zephyr
or Harmattan) drives the WM chrome at a time. Running `harmattan-theme`
rewrites those four include paths from `zephyr/active/...` to
`harmattan/active/...` (and back again if you run `zephyr-theme`
afterwards); whichever script you ran most recently wins. kitty and vim are
unaffected by this — both themes' colorschemes sit side by side as ordinary
toggle options, so kitty/vim can be on a different family than the rest of
the desktop if you want that.

## Switching

```
harmattan-theme light   # switch everything (except vim) to Harmattan Light
harmattan-theme dusk    # switch everything (except vim) to Harmattan Dusk
harmattan-theme dark    # switch everything (except vim) to Harmattan Dark
harmattan-theme toggle  # cycle light -> dusk -> dark -> light
harmattan-theme status  # show which variant is active
```

Reloads sway (`swaymsg reload`), mako (`makoctl reload`) and waybar
(`SIGUSR2`) itself; kitty picks up the new include on next launch, or press
ctrl+shift+F5 in an open kitty window to reload it live. For vim, run
`:colorscheme harmattan_dusk` (or `_light`/`_dark`) in a running session, or
change the `colorscheme` line in `vimrc` if you want it to be the new
default.
