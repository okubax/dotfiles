#!/usr/bin/env bash
# bootstrap.sh — link this dotfiles repo into $HOME (fresh-machine setup).
#
# On a new machine:   git clone <repo> ~/dotfiles && ~/dotfiles/bootstrap.sh
#
# Commands:
#   link      create every symlink in the map (default). Anything real that is
#             in the way is moved to ~/.dotfiles-backup-<timestamp>/ first.
#   unlink    remove only the symlinks this script manages (leaves the repo).
#   status    show LINKED / WRONG / CONFLICT / MISSING / NO-SRC for each entry.
#   check     drift check: list live ~ symlinks into this repo that are NOT in
#             the map (so the map never silently rots), plus stale map entries.
#   help
#
# Flags:  -n/--dry-run   show actions, change nothing
#         -f/--force     replace conflicting real files without keeping a backup
#         -q/--quiet     only warnings/errors
#
# The map below is the single source of truth. It was seeded from the live
# system; keep it honest by running `bootstrap.sh check` after adding dotfiles.
#
# NOTE: this is the PUBLIC subset. Secret configs (.ssh .gnupg pass .electrum),
# machine-specific bits (yams), and shell history (.zsh_history) are intentionally
# excluded — the full private set lives in a separate, non-public dotfiles repo.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
DRY=false; FORCE=false; QUIET=false

# --- link map: "<path in repo>|<path relative to $HOME>" -------------------
read -r -d '' LINKS <<'MAP' || true
aliases/aliases|.aliases
aliases/aliases_dev|.aliases_dev
aliases/aliases_personal|.aliases_personal
aliases/aliases_script|.aliases_script
aliases/aliases_system|.aliases_system
bin|bin
fontconfig|.config/fontconfig
gitconfig|.gitconfig
ii|.config/ii
img|.img
kitty|.config/kitty
mpd|.mpd
mplayer|.mplayer
multitailrc|.multitailrc
ncmpcpp|.ncmpcpp
neofetch|.config/neofetch
ranger|.config/ranger
startpage|.startpage
todo|.todo
urlview|.urlview
vim|.vim
vimrc|.vimrc
swaywm/mako|.config/mako
swaywm/sway|.config/sway
swaywm/swaylock|.config/swaylock
swaywm/swayshot.sh|.config/swayshot.sh
swaywm/waybar|.config/waybar
swaywm/wofi|.config/wofi
zsh/zprofile|.zprofile
zsh/zshenv|.zshenv
zsh/zshrc|.zshrc
zsh/config/aliases.zsh|.config/zsh/aliases.zsh
zsh/config/completion.zsh|.config/zsh/completion.zsh
zsh/config/history.zsh|.config/zsh/history.zsh
zsh/config/options.zsh|.config/zsh/options.zsh
zsh/config/plugins.zsh|.config/zsh/plugins.zsh
zsh/config/prompt.zsh|.config/zsh/prompt.zsh
zsh/plugins/catppuccin_frappe-zsh-syntax-highlighting.zsh|.local/share/zsh/plugins/catppuccin_frappe-zsh-syntax-highlighting.zsh
zsh/plugins/catppuccin_latte-zsh-syntax-highlighting.zsh|.local/share/zsh/plugins/catppuccin_latte-zsh-syntax-highlighting.zsh
zsh/plugins/catppuccin_macchiato-zsh-syntax-highlighting.zsh|.local/share/zsh/plugins/catppuccin_macchiato-zsh-syntax-highlighting.zsh
zsh/plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh|.local/share/zsh/plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh
MAP

# --- colours / logging -----------------------------------------------------
if [ -t 1 ]; then
    G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; C=$'\e[36m'; Z=$'\e[0m'
else G=''; Y=''; R=''; B=''; C=''; Z=''; fi
info() { $QUIET || printf '%s\n' "$*"; }
ok()   { $QUIET || printf '  %s✓%s %s\n' "$G" "$Z" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$Z" "$*" >&2; }
err()  { printf '  %s✗%s %s\n' "$R" "$Z" "$*" >&2; }

# run a mutating command, or just print it under --dry-run
run() { if $DRY; then printf '    would: %s\n' "$*"; else "$@"; fi; }

# move a real file/dir out of the way, preserving its path under the backup dir
backup() {
    local target="$1" rel dest
    rel="${target#"$HOME"/}"
    dest="$BACKUP_DIR/$rel"
    run mkdir -p "$(dirname "$dest")"
    run mv "$target" "$dest"
    info "    backed up ${rel} -> ${BACKUP_DIR/#$HOME/~}/"
}

# iterate the map, calling $1 with (src_rel, dst_rel) for each non-empty line
each_link() {
    local fn="$1" src dst
    while IFS='|' read -r src dst; do
        [ -n "${src:-}" ] || continue
        case "$src" in \#*) continue ;; esac
        "$fn" "$src" "$dst"
    done <<< "$LINKS"
}

# --- actions ---------------------------------------------------------------
do_link() {
    local src="$1" dst="$2" s="$REPO/$1" d="$HOME/$2"
    if [ ! -e "$s" ]; then warn "no source in repo: $src (skipped — restore it first?)"; return; fi
    if [ -L "$d" ] && [ "$(readlink "$d")" = "$s" ]; then ok "already linked: $dst"; return; fi
    run mkdir -p "$(dirname "$d")"
    if [ -L "$d" ]; then
        run rm "$d"                       # wrong-target symlink: safe to drop
    elif [ -e "$d" ]; then
        if $FORCE; then run rm -rf "$d"; else backup "$d"; fi
    fi
    run ln -sfn "$s" "$d"
    ok "linked: $dst -> ${C}$src${Z}"
}

do_unlink() {
    local src="$1" dst="$2" s="$REPO/$1" d="$HOME/$2"
    if [ -L "$d" ] && [ "$(readlink "$d")" = "$s" ]; then
        run rm "$d"; ok "unlinked: $dst"
    fi
}

do_status() {
    local src="$1" dst="$2" s="$REPO/$1" d="$HOME/$2" state col
    if [ -L "$d" ]; then
        if [ "$(readlink "$d")" = "$s" ]; then state="LINKED";   col="$G"
        else                                    state="WRONG";    col="$Y"; fi
    elif [ -e "$d" ];    then                   state="CONFLICT"; col="$R"
    elif [ ! -e "$s" ];  then                   state="NO-SRC";   col="$Y"
    else                                        state="MISSING";  col="$C"; fi
    printf '  %s%-9s%s %s\n' "$col" "$state" "$Z" "$dst"
}

# drift check: compare live ~ symlinks-into-repo against the map
do_check() {
    local mapset src dst
    # $LINKS is already the "src|dst" table — just drop blanks/comments.
    mapset="$(grep -vE '^\s*(#|$)' <<< "$LINKS")"
    info "${B}Live symlinks into the repo that are NOT in the map:${Z}"
    local found=0
    while IFS= read -r l; do
        local t; t="$(readlink "$l")"
        case "$t" in "$REPO/"*) ;; *) continue ;; esac
        src="${t#"$REPO"/}"; dst="${l#"$HOME"/}"
        if ! grep -qxF "$src|$dst" <<< "$mapset"; then
            warn "unmapped: $src -> $dst   (add to the map)"; found=1
        fi
    done < <(find "$HOME" -xdev -type l 2>/dev/null)
    [ "$found" -eq 0 ] && ok "none — map covers every live link"
    info "${B}Map entries whose repo source is missing:${Z}"
    found=0
    each_link '_chk_src'
    [ "$found" -eq 0 ] && ok "none — every map source exists"
}
_chk_src() { if [ ! -e "$REPO/$1" ]; then warn "stale: $1 (in map, absent in repo)"; found=1; fi; }

usage() { sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; }

# --- args ------------------------------------------------------------------
cmd="link"
for a in "$@"; do
    case "$a" in
        link|unlink|status|check|help) cmd="$a" ;;
        -n|--dry-run) DRY=true ;;
        -f|--force)   FORCE=true ;;
        -q|--quiet)   QUIET=true ;;
        -h|--help)    cmd="help" ;;
        *) err "unknown arg: $a"; usage; exit 1 ;;
    esac
done

case "$cmd" in
    link)   $DRY && info "${B}[dry-run]${Z}"
            info "${B}Linking dotfiles from $REPO${Z}"; each_link do_link
            $DRY || info "Done.${BACKUP_DIR:+ Any displaced files are in ${BACKUP_DIR/#$HOME/~}/}" ;;
    unlink) info "${B}Removing managed symlinks${Z}"; each_link do_unlink ;;
    status) info "${B}Dotfiles status (repo: $REPO)${Z}"; each_link do_status ;;
    check)  do_check ;;
    help)   usage ;;
esac
