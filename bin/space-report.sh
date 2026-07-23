#!/usr/bin/env bash
# space-report.sh — disk usage & installed-package size overview
#
#   disk [PATH]        top space-users (immediate entries) under PATH (default $HOME)
#   disk /             whole root filesystem (uses sudo)
#   files [PATH]       largest individual files anywhere under PATH
#   pkgs               installed packages by size, largest first (official vs AUR)
#   ncdu [PATH]        interactive browser (if ncdu is installed)
#   all                disk ($HOME) + pkgs   [default when run with no args]
#
# Options:  disk/files/pkgs take  -n N  to set how many rows to show
#           (defaults: disk 20, files 20, pkgs = all).
#
# Deps: coreutils (du/find/sort/numfmt), pacman, expac. Optional: ncdu.

# No 'pipefail': the display pipelines below intentionally use `head`, which
# closes the pipe early and makes the upstream `printf`/`sort`/`du` die with
# SIGPIPE (exit 141) — harmless here, but pipefail+`set -e` would abort on it.
set -eu

# ---- colours (disabled if not a tty) ----
if [ -t 1 ]; then
    B=$'\e[1m'; DIM=$'\e[2m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; R=$'\e[0m'
else
    B=''; DIM=''; G=''; Y=''; C=''; R=''
fi

hr()    { printf '%s\n' "${DIM}────────────────────────────────────────────────────────${R}"; }
human() { numfmt --to=iec --suffix=B --format='%.1f' 2>/dev/null || cat; }
need()  { command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' not found" >&2; exit 1; }; }

# Echo "sudo" (and a note) if PATH can't be read as the current user — used so
# `disk /` and `files /` don't drown in permission-denied noise.
sudo_for() {
    local p="$1"
    if [ "$(id -u)" -ne 0 ] && { [ ! -r "$p" ] || [ "${p#"$HOME"}" = "$p" ]; }; then
        [ "$p" = "$HOME" ] || { echo "sudo"; echo "${DIM}(using sudo to read $p)${R}" >&2; }
    fi
}

# parse an optional  -n N  plus a single positional PATH; sets $NUM and $ARGPATH
parse_n_path() {
    NUM="$1"; shift          # caller passes the default first
    ARGPATH=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -n) NUM="$2"; shift 2 ;;
            -*) echo "unknown option: $1" >&2; return 1 ;;
            *)  ARGPATH="$1"; shift ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Largest immediate entries in a directory (depth 1)
# ---------------------------------------------------------------------------
disk_usage() {
    parse_n_path 20 "$@"
    local path top; path="${ARGPATH:-$HOME}"; top="$NUM"
    [ -d "$path" ] || { echo "error: not a directory: $path" >&2; return 1; }
    path="$(realpath "$path")"
    need du

    local SUDO; SUDO="$(sudo_for "$path")"

    echo "${B}Filesystem for $path${R}"
    df -h "$path" | sed '1s/^/  /; 2s/^/  /'
    hr
    echo "${B}Top $top space-users in ${C}$path${R} ${DIM}(directories & files, depth 1)${R}"
    # -x: stay on one filesystem so we don't wander into mounts / VM images.
    $SUDO du -x -d1 -b "$path" 2>/dev/null \
        | sort -rn \
        | head -n "$((top + 1))" \
        | while read -r bytes item; do
            [ "$item" = "$path" ] && continue      # skip the grand-total row
            printf '  %9s  %s\n' "$(printf '%s' "$bytes" | human)" "${item##*/}"
        done
    hr
    echo "${DIM}tip: 'space-report.sh files $path' for the biggest individual files${R}"
}

# ---------------------------------------------------------------------------
# Largest individual files anywhere under a directory
# ---------------------------------------------------------------------------
big_files() {
    parse_n_path 20 "$@"
    local path top; path="${ARGPATH:-$HOME}"; top="$NUM"
    [ -d "$path" ] || { echo "error: not a directory: $path" >&2; return 1; }
    path="$(realpath "$path")"
    need find

    local SUDO; SUDO="$(sudo_for "$path")"

    echo "${B}Top $top largest files under ${C}$path${R}"
    hr
    # -xdev: don't cross filesystem boundaries (skip mounted VMs / shares).
    $SUDO find "$path" -xdev -type f -printf '%s\t%p\n' 2>/dev/null \
        | sort -rn \
        | head -n "$top" \
        | while IFS=$'\t' read -r bytes file; do
            printf '  %9s  %s\n' "$(printf '%s' "$bytes" | human)" "$file"
        done
}

# ---------------------------------------------------------------------------
# Installed packages by size, official vs AUR/foreign  (single pass)
# ---------------------------------------------------------------------------
pkg_usage() {
    parse_n_path 0 "$@"       # 0 = show all
    local top="$NUM"
    need pacman; need expac

    # Foreign (-Qm) = AUR / manually installed; everything else is an official
    # repo pkg. Load into an associative array => O(1) lookup, no per-pkg grep.
    declare -A is_aur=()
    local n
    while read -r n; do [ -n "$n" ] && is_aur["$n"]=1; done < <(pacman -Qqm)

    echo "${B}Installed packages by size ${DIM}(largest first)${R}"
    hr
    printf '  %10s  %-6s %s\n' "SIZE" "SOURCE" "PACKAGE"

    local total_off=0 total_aur=0 n_off=0 n_aur=0 shown=0 bytes name tag col
    # expac '%m\t%n' = installed size (bytes) + name; one pass does both the
    # top-N display and the full totals.
    while IFS=$'\t' read -r bytes name; do
        if [ -n "${is_aur[$name]:-}" ]; then
            tag="AUR"; col="$Y"; total_aur=$((total_aur + bytes)); n_aur=$((n_aur + 1))
        else
            tag="repo"; col="$G"; total_off=$((total_off + bytes)); n_off=$((n_off + 1))
        fi
        if [ "$top" -le 0 ] || [ "$shown" -lt "$top" ]; then
            printf '  %10s  %s%-6s%s %s\n' \
                "$(printf '%s' "$bytes" | human)" "$col" "$tag" "$R" "$name"
            shown=$((shown + 1))
        fi
    done <<< "$(expac '%m\t%n' | sort -rn)"

    hr
    printf "  ${G}%-4s${R} official repo pkgs: %s\n" "$n_off" "$(printf '%s' "$total_off" | human)"
    printf "  ${Y}%-4s${R} AUR/foreign  pkgs: %s\n" "$n_aur" "$(printf '%s' "$total_aur" | human)"
    printf "  ${B}%-4s${R} total:             %s\n" \
        "$((n_off + n_aur))" "$(printf '%s' "$((total_off + total_aur))" | human)"

    # cleanup hints — the two usual space wins
    local orphans cache csz
    orphans="$(pacman -Qtdq 2>/dev/null | grep -c . || true)"
    if [ "${orphans:-0}" -gt 0 ]; then
        echo "${DIM}${orphans} orphaned pkg(s): review 'pacman -Qtdq', remove with 'pacman -Rns \$(pacman -Qtdq)'${R}"
    fi
    cache="/var/cache/pacman/pkg"
    if [ -d "$cache" ]; then
        csz="$(du -sh "$cache" 2>/dev/null | cut -f1)"
        echo "${DIM}pacman cache: ${csz:-?} in $cache — trim with 'paccache -r'${R}"
    fi
}

# ---------------------------------------------------------------------------
usage() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; }

case "${1:-all}" in
    disk)              shift; disk_usage "$@" ;;
    files|bigfiles)    shift; big_files "$@" ;;
    pkgs|packages|pkg) shift; pkg_usage "$@" ;;
    ncdu)              shift; need ncdu; ncdu "${1:-$HOME}" ;;
    all)               disk_usage; echo; pkg_usage -n 20 ;;
    -h|--help|help)    usage ;;
    *)                 echo "unknown command: $1" >&2; echo; usage; exit 1 ;;
esac
