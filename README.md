# 🏠 Dotfiles - Modern Wayland Desktop with Sway

> A complete, keyboard-driven desktop environment built for productivity and aesthetics

This repository contains dotfiles for a modern Linux desktop setup featuring **Sway** (Wayland compositor), **Waybar** (status bar), and carefully curated applications. Everything is designed to work harmoniously for a clean, efficient workflow.

## ✨ What You Get

- **🪟 Window Manager**: Sway (i3-compatible, Wayland-native)
- **📊 Status Bar**: Waybar with custom modules
- **🖥️ Terminal**: Kitty with optimized configuration  
- **🎨 Notifications**: Mako notification daemon
- **🔒 Security**: Swaylock configuration
- **📧 Email**: Basic mutt + offlineimap templates
- **🎵 Music**: MPD + ncmpcpp configuration
- **📁 File Management**: Ranger terminal file manager
- **⌨️ Shell**: ZSH with modular configuration and custom aliases
- **🛠️ Utilities**: Custom scripts and productivity tools

## 📸 Preview

![Desktop Screenshot](screenshot.png)
![Desktop Screenshot with Vim](screenshot2.png)

*Clean, minimal desktop with Waybar status bar and Sway window management*

---

## 🚀 Quick Installation

### Prerequisites

**Recommended System**: Arch Linux (other distributions may work with package name adjustments)

### One-Command Setup

```bash
# Clone and install in one go
git clone https://github.com/okubax/dotfiles.git ~/dotfiles && ~/dotfiles/dotfiles.sh install
```

### Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/okubax/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Preview what will be installed
./dotfiles.sh status

# 3. Install everything
./dotfiles.sh install
```

---

## 📋 Installation Commands

The `dotfiles.sh` script handles everything automatically:

### Basic Commands
```bash
./dotfiles.sh install          # Install all available dotfiles
./dotfiles.sh status           # Check current installation status
./dotfiles.sh uninstall        # Remove all symlinks safely
```

### Advanced Options
```bash
./dotfiles.sh install --dry-run    # Preview installation without changes
./dotfiles.sh install --force      # Overwrite existing files
./dotfiles.sh install --verbose    # Show detailed output
```

### Safety Features
- **Graceful handling**: Missing files show warnings but don't stop installation
- **Interactive prompts**: Choose what to do with existing files
- **Dry-run mode**: See what will happen before making changes
- **Selective installation**: Only available files are processed

---

## 📦 Required Packages

### Core Desktop Environment

**On Arch Linux:**
```bash
# Essential Sway desktop
sudo pacman -S sway waybar mako swaylock wofi wl-clipboard

# Terminal and shell
sudo pacman -S kitty zsh

# File management
sudo pacman -S ranger vim

# Fonts (recommended)
sudo pacman -S ttf-fira-code noto-fonts noto-fonts-emoji
```

### Optional Components

```bash
# Audio and media
sudo pacman -S mpd ncmpcpp mpc pipewire pipewire-pulse

# Email (if you want mail setup)
sudo pacman -S mutt offlineimap msmtp

# Additional utilities
sudo pacman -S neofetch git
```

### AUR Packages
```bash
# Using yay or your preferred AUR helper
yay -S multitail swayshot
```

---

## 🔧 Post-Installation Setup

### 1. Set ZSH as Default Shell
```bash
chsh -s $(which zsh)
```

### 2. Configure Sway Session
**Option A: Display Manager**
- Log out of your current session
- Choose "Sway" from your display manager

**Option B: Manual Start**
```bash
# From a TTY
exec sway
```

### 3. Install Additional Fonts (Optional)
```bash
# For better Unicode support and aesthetics
sudo pacman -S ttf-liberation ttf-dejavu
```

### 4. Set Up Private Configurations

Some configurations are not included in this public repository for privacy/security:

**Email Setup** (if desired):
- Copy `msmtprc` and customize with your email settings
- Set up `~/.offlineimaprc` with your email credentials
- Configure GPG for password encryption

**SSH Configuration**:
- Add your SSH keys to `~/.ssh/`
- Configure `~/.ssh/config` for your servers

**Password Management**:
```bash
# If you want to use pass
sudo pacman -S pass
pass init "your-gpg-key-id"
```

---

## 🎨 Customization Guide

### Quick Customizations

| What to Change | Configuration File | Purpose |
|----------------|-------------------|---------|
| **Keybindings** | `swaywm/sway/config` | Window management shortcuts |
| **Status Bar** | `swaywm/waybar/config` | Modules, styling, behavior |
| **Terminal Colors** | `kitty/kitty.conf` | Colors, fonts, transparency |
| **Shell Aliases** | `aliases/aliases*` | Command shortcuts |
| **File Manager** | `ranger/rc.conf` | Key bindings, previews |

### Color Schemes
The setup includes several color schemes:
- **Kitty**: Multiple themes in `kitty/colors/`
- **Vim**: Catppuccin variants included
- **ZSH**: Syntax highlighting themes

### Adding Your Own Configs
1. **Fork this repository**
2. **Add your files** to the appropriate directories
3. **Update the FILES array** in `dotfiles.sh` if needed
4. **Test with dry-run**: `./dotfiles.sh install --dry-run`

---

## 🗂️ Repository Structure

```
~/dotfiles/
├── dotfiles.sh              # Installation script
├── aliases/                 # Shell aliases and functions
├── bin/                     # Custom scripts and utilities
├── fontconfig/              # Font configuration
├── kitty/                   # Terminal configuration
├── mplayer/                 # Media player settings
├── mutt/                    # Email client configuration
├── ncmpcpp/                 # Music player interface
├── ranger/                  # File manager configuration
├── swaywm/                  # Window manager configs
│   ├── sway/               # Sway WM settings
│   ├── waybar/             # Status bar configuration
│   ├── mako/               # Notification daemon
│   └── wofi/               # Application launcher
├── vim/                     # Text editor configuration
├── zsh/                     # Shell configuration
│   └── config/             # Modular ZSH configs
└── README.md               # This file
```

---

## ⚠️ Important Notes

### What's NOT Included

For privacy and security, these are **not** in the public repository:

- **Private SSH keys** and server configurations
- **Email credentials** and GPG keys
- **Password manager** databases
- **Personal scripts** with sensitive information
- **System-specific** configurations

### Missing File Handling

The installation script handles missing files gracefully:
- **Warnings** are shown for missing files
- **Installation continues** for available files
- **Status command** shows what's available vs. missing

This is normal and expected for a public dotfiles repository!

---

## 🆘 Troubleshooting

### Common Issues

**"Source not found" warnings:**
```bash
# This is normal! Check what's actually available:
./dotfiles.sh status

# Install only what's available:
./dotfiles.sh install --verbose
```

**Permission errors:**
```bash
# Make script executable
chmod +x ./dotfiles.sh
```

**Sway won't start:**
```bash
# Install core dependencies first
sudo pacman -S sway waybar mako

# Check Sway logs
journalctl --user -u sway
```

**Fonts look weird:**
```bash
# Install recommended fonts
sudo pacman -S ttf-fira-code noto-fonts
```

### Getting Help

1. **Check the status**: `./dotfiles.sh status`
2. **Use verbose mode**: `./dotfiles.sh install --verbose`
3. **Try dry-run first**: `./dotfiles.sh install --dry-run`
4. **Open an issue** on GitHub for bugs or questions

---

## 🤝 Contributing

### Sharing Improvements
- **Fork the repository** and customize for your needs
- **Open issues** for bugs or feature requests
- **Submit pull requests** for improvements
- **Share screenshots** of your customizations!

### Making It Yours
1. Fork this repository to your GitHub account
2. Modify configurations to match your preferences  
3. Add your own private configs (don't commit sensitive data!)
4. Update the installation script if you add/remove files

---

## 🎯 Similar Setups

If you're looking for inspiration or alternatives:
- **[r/unixporn](https://reddit.com/r/unixporn)** - Desktop customization showcase
- **[Sway Wiki](https://github.com/swaywm/sway/wiki)** - Official documentation
- **[ArchWiki Sway](https://wiki.archlinux.org/title/Sway)** - Comprehensive setup guide

---

## 📄 License

These dotfiles are provided freely under the MIT License. Feel free to use, modify, and share!

**Special thanks to:**
- The [Sway](https://swaywm.org/) development team
- The [Arch Linux](https://archlinux.org/) community  
- All open-source projects that make this setup possible
- The dotfiles community for inspiration and ideas

---

## 🔗 Quick Links

- **[Sway Documentation](https://github.com/swaywm/sway/wiki)**
- **[Waybar Configuration](https://github.com/Alexays/Waybar/wiki)**
- **[Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)**
- **[ZSH Configuration Guide](https://wiki.archlinux.org/title/Zsh)**

---

*Happy ricing! 🎉*

> **Pro tip**: Start with the basic installation, then gradually customize each component to your liking. The modular structure makes it easy to modify individual parts without breaking the whole setup.
