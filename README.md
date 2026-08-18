# Dotfiles - Sway Desktop Environment

A complete keyboard-driven desktop setup for Arch Linux featuring the Sway Wayland compositor, Waybar status bar, and productivity-focused applications. Themed with **[Zephyr](swaywm/zephyr/README.md)**, a custom light/dusk/dark colorscheme matched to KDE's Breeze theme so the sway stack looks coherent next to Breeze-themed apps, alongside four full alternative theme families with the same sway/waybar/mako/wofi/swaylock/kitty/vim coverage: **[Harmattan](swaywm/harmattan/README.md)** (an original warm, dust-toned scheme with no external source palette), **[Solarized](swaywm/solarized/README.md)** (Ethan Schoonover's precision palette, dark/light only), **[Nord](swaywm/nord/README.md)** (the arctic Polar Night/Snow Storm/Frost/Aurora palette), and **[Catppuccin](swaywm/catppuccin/README.md)** (Latte/Macchiato/Mocha, mapped to light/dusk/dark). Catppuccin's ZSH syntax-highlighting plugin ships separately (`zsh/plugins/`) and isn't tied to any one of these five.

## Screenshots

All current (Zephyr Light — Kate picks it up natively as a KDE app; Firefox's
own chrome isn't Zephyr-themed).

![Desktop](screenshot.png)
![Vim](screenshot2.png)
![Kate](screenshot3.png)
![Firefox](screenshot4.png)

## Components

**Core Desktop (all Wayland-native)**
- **Window Manager**: Sway (i3-compatible Wayland compositor)
- **Status Bar**: Waybar
- **Launcher / Menus**: Wofi (app launcher, power menu, clipboard picker)
- **Terminal**: Kitty
- **Notifications**: Mako
- **Lock Screen**: Swaylock (plain wallpaper, theme-colored indicator ring matching whichever of the five colorschemes is active — accent typing, warning-color verifying, red wrong password, purple/violet Caps Lock) with swayidle (auto-lock, lock on suspend). Uses vanilla swaylock — blur/clock require the swaylock-effects fork instead.
- **Clipboard**: cliphist + wl-clipboard (history picker bound to Alt+h)
- **Screenshots**: swayshot (full screen / window / region)
- **Shell**: ZSH with modular configuration

**Waybar modules**
- Workspace switcher (only occupied workspaces shown)
- MPD now-playing (hidden when nothing is queued; click to play/pause)
- Idle inhibitor, CPU, memory, backlight (scroll to adjust)
- PulseAudio/PipeWire volume (click to mute, scroll to adjust)
- Network (SSID + signal strength, IP in tooltip)
- Keyboard layout (gb/us, click to switch), battery, system tray, clock with calendar

**Applications**
- **Web Browsers**: Firefox, Firefox Developer Edition, Google Chrome, Tor Browser
- **File Managers**: ranger (terminal), Dolphin (GUI)
- **Text Editors**: vim (native packages, `vim/pack`), Kate
- **Music**: MPD + ncmpcpp + mpc
- **Calendar / Calculator**: gsimplecal, qalculate-qt
- **Cloud Sync**: Nextcloud client
- **IRC**: ii + stunnel + multitail (see `bin/ii-start`, `bin/ii-sway`)

**Theming**
- **Colorscheme**: [Zephyr](swaywm/zephyr/README.md) (default) — light, dusk and dark variants matched to KDE's Breeze color schemes (dusk is a hand-tuned dim mid-tone with no official Breeze equivalent), applied consistently across sway, waybar, mako, wofi, swaylock, kitty, and vim. Switch all variants at once with `zephyr-theme light|dusk|dark|toggle` (installed to `~/bin` — see `bin/zephyr-theme`), or set `vim`/`kitty` independently by editing their own config.
- **Alternative themes**, same full coverage and shape as Zephyr:
  - [Harmattan](swaywm/harmattan/README.md) — an original warm, dust-toned scheme (indigo accent, terracotta/ochre/olive/bougainvillea state colors) with no external source palette. `harmattan-theme light|dusk|dark|toggle`.
  - [Solarized](swaywm/solarized/README.md) — Ethan Schoonover's palette, unmodified. **Dark/light only** — no dusk equivalent, by design. `solarized-theme dark|light|toggle`.
  - [Nord](swaywm/nord/README.md) — the arctic Polar Night/Snow Storm/Frost/Aurora palette. No official Nord Light exists, so `light` inverts which range plays background vs. text (a common community approach); `dusk` shifts Polar Night one step lighter than classic Nord Dark. `nord-theme light|dusk|dark|toggle`.
  - [Catppuccin](swaywm/catppuccin/README.md) — Latte/Macchiato/Mocha mapped to light/dusk/dark (Frappé, the fourth official flavor, isn't part of this mapping). Unlike the other four themes here, Catppuccin's accents genuinely differ per variant upstream, not just its neutrals. `catppuccin-theme light|dusk|dark|toggle`.

  Only one theme *family* drives sway/mako/waybar/wofi's chrome at a time — whichever `<family>-theme` script ran most recently rewrites the shared include paths to point at itself. kitty and vim are unaffected: every family's variants sit side by side as ordinary toggle/colorscheme options, so kitty/vim can be on a different family than the rest of the desktop.
- **ZSH syntax highlighting**: Catppuccin-only (`zsh/plugins/`), independent of which of the five desktop themes is active.
- **Wallpaper**: Generated with `bin/palette_wallpaper.py` — supports all five themes' palettes (Catppuccin's light/dusk/dark reuse the existing `latte`/`macchiato`/`mocha`/`frappe` palettes directly). Desktop wallpapers and swaylock backgrounds for all five ship pre-generated in `img/wallpapers/`.
- **GTK**: `breeze-gtk` (Breeze widget theme for GTK2/3) — already matches Zephyr/Breeze natively, no porting needed. Set via `gtk-3.0`/`gtk-4.0` `settings.ini` (`gtk-theme-name=Breeze`, `gtk-icon-theme-name=breeze`, `gtk-cursor-theme-name=breeze_cursors`)
- **Qt**: `breeze5` (Qt5 Breeze style) via qt5ct/qt6ct
- **Icons / Cursors**: `breeze-icons`, `breeze-cursors`
- **Theme Tools**: nwg-look for GTK3/4 theme management

## Installation

### Prerequisites
Arch Linux (other distributions require package name adjustments)

### Quick Setup
```bash
git clone https://github.com/okubax/dotfiles.git ~/dotfiles && ~/dotfiles/bootstrap.sh
```

### Manual Installation
```bash
git clone https://github.com/okubax/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh status   # See what will be linked
./bootstrap.sh link     # Create the symlinks (default command)
```

**The theme system needs one manual fix after cloning.** GTK CSS's `@import`
doesn't expand `~` or `$HOME`, so `swaywm/waybar/style.css` and
`swaywm/wofi/style.css` each carry a placeholder absolute path
(`/home/YOUR_USERNAME/dotfiles/...`) that's shared by all five theme
families — which family's subdirectory it resolves into just depends on
which `<family>-theme` script last ran. Edit both `@import url(...)`
lines to point at wherever you actually cloned this repo — waybar will fail
to start (CSS parse error) until you do.

## Required Packages

### Essential
```bash
sudo pacman -S sway waybar mako swaylock swayidle wofi wl-clipboard cliphist kitty zsh ranger vim
sudo pacman -S brightnessctl playerctl ttf-ubuntu-font-family ttf-font-awesome noto-fonts noto-fonts-emoji
sudo pacman -S breeze breeze-gtk breeze5 breeze-icons breeze-cursors    # Zephyr (default theme) needs these for GTK/Qt apps to match
```

### Optional
```bash
sudo pacman -S mpd mpc ncmpcpp pipewire pipewire-pulse wireplumber   # Music / audio
sudo pacman -S gsimplecal qalculate-qt dolphin neofetch              # Desktop utilities
sudo pacman -S kate                                                  # Text editor (GUI)
sudo pacman -S qt5ct qt6ct nwg-look                                  # Theme management tools (set Qt style to breeze in qt5ct/qt6ct)
sudo pacman -S nethogs pacman-contrib trash-cli                      # netusage / sweep helpers
sudo pacman -S python-pillow python-numpy                            # palette_wallpaper.py
yay -S multitail swayshot sway-audio-idle-inhibit-git                # AUR
```

## Commands

```bash
./bootstrap.sh                 # Link all configs (default command)
./bootstrap.sh status          # Show LINKED / WRONG / CONFLICT / MISSING per entry
./bootstrap.sh check           # Drift check: warn about live symlinks missing from the map
./bootstrap.sh unlink          # Remove the symlinks it manages
./bootstrap.sh --dry-run       # Preview actions without changing anything
./bootstrap.sh --force         # Replace existing files without keeping a backup
./bootstrap.sh --quiet         # Only print warnings and errors
./bootstrap.sh help            # Full usage
```

`link` is the single source of truth for what gets symlinked; run `check` after
adding a new dotfile to confirm the map still matches reality.

```bash
zephyr-theme light|dusk|dark|toggle|status      # Switch the whole desktop to Zephyr
harmattan-theme light|dusk|dark|toggle|status   # Switch the whole desktop to Harmattan
solarized-theme dark|light|toggle|status        # Switch the whole desktop to Solarized
nord-theme light|dusk|dark|toggle|status        # Switch the whole desktop to Nord
catppuccin-theme light|dusk|dark|toggle|status  # Switch the whole desktop to Catppuccin
```

## Post-Installation

1. Set ZSH as default shell: `chsh -s $(which zsh)`
2. Log in on tty1 — `zsh/zprofile` starts Sway automatically (or run `sway` manually)
3. Fix the two theme-system `@import` placeholder paths described above under Installation
4. Machine-local secrets (API keys etc.) go in `~/.zshrc.local`, which is sourced by `zsh/zshrc` but not tracked here

## Configuration

### Key Files
- **Sway**: `swaywm/sway/config`
- **Waybar**: `swaywm/waybar/config` + `swaywm/waybar/style.css`
- **Mako**: `swaywm/mako/config`
- **Wofi**: `swaywm/wofi/config` + `swaywm/wofi/style.css`
- **Swaylock**: `swaywm/swaylock/config`
- **Terminal**: `kitty/kitty.conf`
- **Vim colorscheme**: set near the bottom of `vimrc`
- **Zephyr theme**: `swaywm/zephyr/` (see its own [README](swaywm/zephyr/README.md) for how the light/dusk/dark switch is wired, and how all five theme families coexist)
- **Harmattan theme**: `swaywm/harmattan/README.md`
- **Solarized theme**: `swaywm/solarized/README.md`
- **Nord theme**: `swaywm/nord/README.md`
- **Catppuccin theme**: `swaywm/catppuccin/README.md`
- **Shell**: `aliases/aliases*`
- **ZSH**: `zsh/config/`

### Directory Structure
```
~/dotfiles/
├── bootstrap.sh         # Symlink manager (link/unlink/status/check)
├── aliases/             # Shell aliases (system/dev/personal/scripts)
├── bin/                 # Custom scripts (see below)
├── ii/                  # ii IRC credentials template
├── img/wallpapers/      # Desktop + swaylock wallpapers, all five themes
├── kitty/               # Terminal config (colors/ has all five themes' flavors)
├── mpd/                 # Music Player Daemon
├── ncmpcpp/             # Music player client
├── ranger/              # File manager
├── startpage/           # Browser start page
├── swaywm/              # Sway, Waybar, Mako, Swaylock, Wofi configs
│   ├── zephyr/          # Zephyr colorscheme: light/, dusk/, dark/, active -> one of them
│   ├── harmattan/       # Harmattan colorscheme: light/, dusk/, dark/, active -> one of them
│   ├── solarized/       # Solarized colorscheme: dark/, light/, active -> one of them
│   ├── nord/            # Nord colorscheme: light/, dusk/, dark/, active -> one of them
│   └── catppuccin/      # Catppuccin colorscheme: light/, dusk/, dark/, active -> one of them
├── vim/                 # Editor configuration (native packages; colors/ has all five themes)
└── zsh/                 # Shell configuration
    ├── config/          # Modular ZSH configs
    └── plugins/         # Catppuccin syntax highlighting themes
```

`swaywm/{zephyr,harmattan,solarized,nord,catppuccin}/` are deliberately
**not** in `bootstrap.sh`'s symlink map — sway/mako/waybar/wofi reference
whichever family is active directly at
`~/dotfiles/swaywm/{zephyr,harmattan,solarized,nord,catppuccin}/...` rather
than through a `$HOME` symlink, so all five only work correctly if the
repo is cloned to `~/dotfiles` (as the Installation section above does).

### Adding a dotfile / keeping the map honest
The symlink map lives in a single `LINKS` block inside `bootstrap.sh`. When you
add a new config, drop the file in the repo, add one `repo/path|$HOME/path` line
to that block, then run `./bootstrap.sh check`. It compares the map against the
symlinks actually present in `$HOME` and flags anything missing (so the map can
never silently drift from reality), plus any map entry whose repo source is gone.
Follow with `./bootstrap.sh link` to create the new symlink.

### Notable Scripts in `bin/`
- `zephyr-theme` - switch the whole desktop between Zephyr Light, Dusk and Dark in one command
- `harmattan-theme` - switch the whole desktop between Harmattan Light, Dusk and Dark in one command
- `solarized-theme` - switch the whole desktop between Solarized Dark and Light in one command
- `nord-theme` - switch the whole desktop between Nord Light, Dusk and Dark in one command
- `catppuccin-theme` - switch the whole desktop between Catppuccin Light (Latte), Dusk (Macchiato) and Dark (Mocha) in one command
- `palette_wallpaper.py` - wallpaper generator for all five themes' palettes, or any of the four standalone Catppuccin flavors
- `ii-start` / `ii-sway` - manage the ii IRC client and its Sway/wofi integration
- `deploy_websites.sh` / `godaddy-server-backup.sh` - static site deployment and full server-home backup (configured via config file/env vars)
- `btrfs-snapshot-backup.sh` / `borg-system-backup.sh` - btrfs snapshot+send backups and Borg full-system backups
- `filesearch.py` - file search tool
- `sysglance.sh` - system overview at a glance (host/CPU/memory/GPU/storage/network/power)
- `space-report.sh` - disk usage (top dirs/files) + installed-package sizes (repo vs AUR)
- `netusage` - who's using the network: overall + live up/down, plus per-process rates (via nethogs)
- `sweep` - safe cleaner for caches / trash / journal / pacman cache (dry-run by default; system parts use sudo)
- `news_reader.py` - terminal RSS reader

## ZSH Configuration

Modular setup with separate configuration files:
- `history.zsh` - Command history settings
- `options.zsh` - Shell behavior options
- `completion.zsh` - Tab completion system
- `prompt.zsh` - Command prompt
- `aliases.zsh` - ZSH-specific aliases
- `plugins.zsh` - Plugin management

Includes Catppuccin syntax highlighting themes (frappe, latte, macchiato, mocha) — independent of the sway/kitty/vim colorscheme, not yet ported to the other four themes.

## Backup System

`bootstrap.sh link` never clobbers your data. Anything real that is in the way of
a symlink is first moved into a timestamped `~/.dotfiles-backup-<timestamp>/`
directory (preserving its relative path), then the symlink is created. Wrong-target
symlinks are simply replaced. To undo an install, run `./bootstrap.sh unlink` and,
if needed, move the originals back from that backup directory. Pass `--force` to
skip the backup and overwrite in place, or `--dry-run` to preview first.

## What's Not Included

For security reasons, the following are excluded:
- SSH keys and server configurations
- Email setup, credentials and GPG keys
- Password manager databases
- Personal scripts with sensitive information

Files like `ii/credentials`, `gitconfig`, and the server-related scripts ship with placeholder values — fill in your own.

## Troubleshooting

**Missing file warnings**: Normal for public repositories. Run `./bootstrap.sh status` (a missing source shows as `NO-SRC`) or `./bootstrap.sh check` to audit the map.

**Undo installation**: Run `./bootstrap.sh unlink`, then restore any originals from `~/.dotfiles-backup-<timestamp>/`

**Sway won't start**: Check dependencies and logs with `journalctl --user -u sway`

**Waybar fails to start / CSS parse error**: You likely haven't fixed the two `@import` placeholder paths in `swaywm/waybar/style.css` and `swaywm/wofi/style.css` yet — see Installation above.

**Waybar shows no icons**: Install `ttf-font-awesome` (the bar uses Font Awesome 6 glyphs)

**Permission errors**: Run `chmod +x ./bootstrap.sh`

## Customization

Fork the repository and modify configurations to your needs. The modular structure allows easy customization of individual components without affecting the entire setup.

## License

MIT License. Use, modify, and distribute freely.

## Links

- [Zephyr colorscheme README](swaywm/zephyr/README.md) - palette provenance and how the light/dusk/dark switch works
- [Harmattan colorscheme README](swaywm/harmattan/README.md) - design rationale and how the light/dusk/dark switch works
- [Solarized colorscheme README](swaywm/solarized/README.md) - palette provenance and how the dark/light switch works
- [Nord colorscheme README](swaywm/nord/README.md) - palette provenance and how the light/dusk/dark switch works
- [Catppuccin colorscheme README](swaywm/catppuccin/README.md) - flavor mapping and how the light/dusk/dark switch works
- [Sway Documentation](https://github.com/swaywm/sway/wiki)
- [Waybar Configuration](https://github.com/Alexays/Waybar/wiki)
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Improved ii IRC Setup](https://okubax.co.uk/2025/06/16/improved-ii-irc-setup/) - Guide for setting up ii IRC client
