# 🏠 Dotfiles - Modern Wayland Desktop with Sway

> A complete, keyboard-driven desktop environment built for productivity and aesthetics

This repository contains my personal dotfiles for a modern Linux desktop setup featuring **Sway** (Wayland compositor), **Waybar** (status bar), and carefully curated applications. Everything is designed to work harmoniously for a clean, efficient workflow.

## ✨ What You Get

- **🪟 Window Manager**: Sway (i3-compatible, Wayland-native)
- **📊 Status Bar**: Waybar with custom modules
- **🖥️ Terminal**: Kitty with optimized configuration  
- **🎨 Notifications**: Mako notification daemon
- **🔒 Security**: Swaylock + pass password manager
- **📧 Email**: Complete mutt + offlineimap setup
- **🎵 Music**: MPD + ncmpcpp configuration
- **📁 File Management**: Ranger terminal file manager
- **⌨️ Shell**: ZSH with custom aliases and functions

## 📸 Preview

![Desktop Screenshot](screenshot.png)
![Desktop Screenshot with Vim](screenshot2.png)

*Clean, minimal desktop with Waybar status bar and Sway window management*

---

## 🚀 Quick Installation

### 1. Prerequisites

**Recommended System**: Arch Linux (other distributions may work with modifications)

### 2. Clone and Install

```bash
# Clone the repository
git clone https://github.com/okubax/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Preview what will be installed (recommended first step)
./dotfiles.sh status

# Install everything automatically
./dotfiles.sh install
```

That's it! The script handles all the symlink creation and backups automatically.

---

## 📋 Installation Options

The `dotfiles.sh` script provides several commands for different scenarios:

### Basic Commands
```bash
./dotfiles.sh install          # Install all dotfiles (creates backups)
./dotfiles.sh status           # Check current installation status
./dotfiles.sh uninstall        # Remove all symlinks safely
./dotfiles.sh validate         # Check for missing files
```

### Advanced Options
```bash
./dotfiles.sh install --dry-run    # Preview installation without changes
./dotfiles.sh install --force      # Overwrite existing files
./dotfiles.sh backup               # Create backup only
./dotfiles.sh clean                # Remove broken symlinks
```

### Safety Features
- **Automatic backups**: Existing files are backed up before replacement
- **Dry-run mode**: See what will happen before making changes
- **Interactive prompts**: Choose what to do with existing files
- **Validation**: Checks all source files exist before installation

---

## 📦 Required Packages

### Install Core Dependencies

**On Arch Linux:**
```bash
# Essential packages
sudo pacman -S sway waybar mako swaylock wofi kitty zsh

# File management and utilities  
sudo pacman -S ranger vim wl-clipboard

# Audio and media
sudo pacman -S mpd ncmpcpp mpc pipewire pipewire-pulse

# Email and communication (optional)
sudo pacman -S mutt offlineimap msmtp

# Security
sudo pacman -S gnupg pass
```

**AUR Packages** (using yay or your preferred AUR helper):
```bash
yay -S clipman multitail swayshot
```

### For Other Distributions
Package names may differ. Look for equivalent packages in your distribution's repositories.

---

## 🔧 Post-Installation Setup

After running the installation script, you'll need to configure a few things:

### 1. Set ZSH as Default Shell
```bash
chsh -s $(which zsh)
```

### 2. Configure Email (Optional)
If you want to use the email setup:
- Edit `~/.offlineimaprc` with your email credentials
- Configure `~/.msmtprc` for sending emails
- Set up GPG keys for password encryption

### 3. Set Up Password Manager
```bash
# Initialize pass
pass init "your-gpg-key-id"
```

### 4. Configure Sway
- Log out of your current session
- Choose "Sway" from your display manager
- Or start with: `exec sway` from a TTY

---

## 🎨 Customization

### Key Files to Customize

| Component | Configuration File | Purpose |
|-----------|-------------------|---------|
| Window Manager | `swaywm/sway/config` | Keybindings, workspaces, appearance |
| Status Bar | `swaywm/waybar/config` | Modules, styling, behavior |
| Terminal | `kitty/kitty.conf` | Colors, fonts, key mappings |
| Shell | `zsh/zshrc` | Aliases, functions, prompt |
| File Manager | `ranger/rc.conf` | Key bindings, previews |

### Quick Customizations
- **Colors**: Most apps inherit from the Sway color scheme
- **Fonts**: Install your preferred fonts and update configs
- **Keybindings**: Modify `swaywm/sway/config` for shortcuts
- **Status Bar**: Enable/disable modules in `swaywm/waybar/config`

---

## 🗂️ What Gets Installed

The script creates symlinks for these configurations:

### Shell & Aliases
- `~/.aliases*` - Command shortcuts and functions
- `~/.zshrc`, `~/.zshenv`, `~/.zprofile` - ZSH configuration

### Applications  
- `~/.config/sway/` - Window manager settings
- `~/.config/waybar/` - Status bar configuration
- `~/.config/kitty/` - Terminal settings
- `~/.config/ranger/` - File manager configuration
- `~/.vimrc`, `~/.vim/` - Text editor setup

### Utilities
- `~/bin/` - Custom scripts and utilities
- `~/.gitconfig` - Git configuration
- Email, music, and other app configurations

---

## 🆘 Troubleshooting

### Common Issues

**"Source file not found" errors:**
```bash
# Check what's missing
./dotfiles.sh validate

# Some files might be optional - check the dotfiles.sh script
```

**Permission issues:**
```bash
# Make sure the script is executable
chmod +x ./dotfiles.sh
```

**Existing files blocking installation:**
```bash
# Use interactive mode to choose what to do
./dotfiles.sh install

# Or force overwrite (careful!)
./dotfiles.sh install --force
```

**Want to undo everything:**
```bash
# Remove all symlinks
./dotfiles.sh uninstall

# Restore from backup if needed
./dotfiles.sh restore
```

---

## 🤝 Contributing & Customization

### Making It Yours
1. **Fork this repository** to your own GitHub account
2. **Modify configurations** to match your preferences
3. **Update the dotfiles map** in `dotfiles.sh` if you add/remove files
4. **Test thoroughly** with `--dry-run` before applying changes

### Sharing Improvements
- Open issues for bugs or questions
- Submit pull requests for enhancements
- Share screenshots of your customizations!

---

## 📄 License & Credits

These dotfiles are provided freely for personal and educational use. Feel free to adapt, modify, and share.

**Special thanks to:**
- The [Sway](https://swaywm.org/) development team
- The [Arch Linux](https://archlinux.org/) community  
- All the open-source projects that make this setup possible

---

## 🔗 Quick Links

- **[Sway Documentation](https://github.com/swaywm/sway/wiki)**
- **[Waybar Configuration](https://github.com/Alexays/Waybar/wiki)**
- **[Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)**

---

*Happy customizing! 🎉*
