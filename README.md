# Dotfiles

dotfiles for my sway + waybar setup on ArchLinux

I use this configuration for my laptop which runs **[Sway, an i3-compatible Wayland compositor based on wlroots](https://swaywm.org/)** on
**[Arch Linux](https://www.archlinux.org/)**.

## Dependencies
*Note: I hope I've covered all dependencies here, but some dependencies might be missing*

This setup is intended for regular [Sway](https://swaywm.org/), no gurantees it would work with other Sway-like compositors like **[SwayFX](https://github.com/WillPower3309/swayfx)**. Only tested on ArchLinux-- I can't make any guarantees about its compatibility with other distros.

* `clipman` -- A basic clipboard manager for Wayland, with support for persisting copy buffers after an application exits | [aur link](https://aur.archlinux.org/packages/clipman)
* `dropbox-cli` -- Command line interface for dropbox
* `ii` -- A minimalist FIFO and filesystem-based IRC client, from [suckless](https://tools.suckless.org/ii/)
* `kitty` -- A modern, hackable, featureful, OpenGL-based terminal emulator
* `mako` -- A lightweight notification daemon for Wayland
* `mpc` -- Minimalist command line interface to MPD
* `mpd` -- Flexible, powerful, server-side application for playing music with `ncmpcpp` as client
* `msmtp` -- A mini smtp client
* `multitail` -- View one or multiple files like the original tail program | [aur link](https://aur.archlinux.org/packages/multitail)
* `mutt` -- Small but very powerful text-based mail client
* `offlineimap` -- Synchronizes emails between two repositories
* `pamixer` -- Pulseaudio command-line mixer like amixer
* `pass` -- Stores, retrieves, generates, and synchronizes passwords securely
* `playerctl` -- mpris media player controller and lib for spotify, vlc, audacious, bmp, xmms2, and others
* `ranger` -- A simple, vim-like file manager
* `swaylock` -- a screen locking utility for Wayland compositors
* `swayshot` -- Print screen helper for sway adds keyboard shortcuts for screenshots
* `vim` -- Vi Improved, a highly configurable, improved version of the vi text editor
* `wl-clipboard` -- Wayland clipboard utilities, wl-copy and wl-paste, to copy data between the clipboard and Unix pipes, sockets, files etc
* `wofi` -- A rofi inspired menu and launcher for wlroots compositors
### ~/.fonts
* `Ubuntu` -- Ubuntu font family


## Housekeeping
1. First, install the dependencies listed in the section above.

2. `bin/` contains custom scripts. Add them to your `$PATH` and ensure that they are executable.

3. My default shell is zsh.

4. You need to have [gnupg](https://www.archlinux.org/packages/core/x86_64/gnupg/) installed and configured properly for [pass](https://www.archlinux.org/packages/community/any/pass/) to work.

### Installation
```
git clone https://github.com/okubax/dotfiles.git
cd dotfiles
./dots.sh

```

### Screenshot
![screenshot](/screenshot.png)
![screenshot2](/screenshot_.png)

&nbsp;

