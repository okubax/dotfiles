# Zephyr — a Breeze-matched colorscheme for the sway desktop

Zephyr exists to make the sway stack (sway, waybar, mako, wofi, swaylock,
kitty, vim) look like one coherent desktop that sits comfortably next to
KDE apps themed with Breeze, instead of the previous disjointed mix
(Catppuccin Mocha in sway/waybar/mako/wofi, Catppuccin Macchiato in kitty).

Two variants, `light` and `dark`, mirroring KDE's own BreezeLight/BreezeDark
color schemes (`/usr/share/color-schemes/Breeze{Light,Dark}.colors`).

## Where the colors come from

- **Neutrals** (backgrounds, foreground text, muted text) are lifted
  directly from `BreezeLight.colors` / `BreezeDark.colors` on this system
  (the `[Colors:View]`, `[Colors:Window]` and `[Colors:Header]` groups).
  `border` in each variant is the one hand-interpolated value (Breeze's
  flat `.colors` file doesn't ship a dedicated border color — real Plasma
  widgets compute it from the palette at runtime).
- **Accent colors** (blue, red, green, orange, purple) are Breeze's own
  semantic colors — `DecorationFocus`/`Colors:Selection` (blue #3DAEE9),
  `ForegroundNegative` (red #DA4453), `ForegroundPositive` (green #27AE60),
  `ForegroundNeutral` (orange #F67400), `ForegroundVisited` (purple #9B59B6),
  `ForegroundLink` (#2980B9 light / #1D99F3 dark).
- **Cyan/teal** (#1ABC9C / #16A085) and the "bright" ANSI companions
  (#C0392B, #2ECC71, #F1C40F, #8E44AD) are *not* in Breeze's own files —
  Breeze doesn't ship enough hues for a full 16-color terminal palette.
  They're pulled from Flat UI Colors (flatuicolors.com), the same flat
  design palette Breeze's own choices already overlap with exactly
  (#2980B9 "Belize Hole", #9B59B6 "Amethyst" and #27AE60 "Nephritis" are
  members of both sets) — so they extend the family rather than clashing
  with it.

Full swatch list: see `light/palette.md` and `dark/palette.md`.

## Wallpapers

Desktop wallpaper and swaylock's lock-screen background are also
Zephyr-matched, generated with `~/dotfiles/bin/catppuccin_wallpaper.py`
(extended with `zephyr_light`/`zephyr_dark` palettes — same provenance as
above) and stored in `~/.img/wallpapers/zephyr_{light,dark}_{desktop,
lockscreen}.png`. Wired per-variant: `zephyr/{light,dark}/sway.conf` sets
`output * bg ...`, `zephyr/{light,dark}/swaylock.conf` sets `image=...` — so
`zephyr-theme light|dark` switches the wallpaper along with everything
else. See each variant's `palette.md` for exact generation parameters.

## Layout

```
zephyr/
  light/   — one file per app, Zephyr Light values, in that app's native syntax
  dark/    — same, Zephyr Dark values
  active -> light | dark   (symlink; this is what every app config points at)
```

- `sway/config` does `include ~/dotfiles/swaywm/zephyr/active/sway.conf`
- `mako/config` does `include=~/dotfiles/swaywm/zephyr/active/mako.conf`
- `waybar/style.css` does `@import "active/waybar.css";`
- `wofi/style.css` does `@import "active/wofi.css";`
- `kitty.conf` does `include ~/dotfiles/swaywm/zephyr/active/kitty.conf`
- `swaylock` has no include directive — `zephyr-theme` copies
  `zephyr/{light,dark}/swaylock.conf` straight over `swaywm/swaylock/config`
  when you switch.
- vim doesn't use `active/` at all — `~/.vim/colors/zephyr_light.vim` and
  `zephyr_dark.vim` are two ordinary standalone colorschemes (matching how
  the existing catppuccin_* colorschemes are already structured); `vimrc`
  picks one directly.

## Switching

```
zephyr-theme light   # switch everything (except vim) to Zephyr Light
zephyr-theme dark    # switch everything (except vim) to Zephyr Dark
zephyr-theme toggle  # flip to whichever it isn't currently
zephyr-theme status  # show which variant is active
```

Reloads sway (`swaymsg reload`), mako (`makoctl reload`) and waybar
(`SIGUSR2`) itself; kitty picks up the new include on next launch, or press
ctrl+shift+F5 in an open kitty window to reload it live. For vim, run
`:colorscheme zephyr_dark` (or `_light`) in a running session, or change the
`colorscheme` line in `vimrc` if you want it to be the new default.
