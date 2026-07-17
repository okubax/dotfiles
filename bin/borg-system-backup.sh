#!/bin/bash
# ---------------------------------------------------------------------------
# borg-system-backup.sh  --  Versioned full-system backup to the external drive
#                      using BorgBackup (deduplicating, compressed, verified).
#
# Source of truth is the read-only btrfs snapshots created by btrfs-snapshot-backup.sh
# (/mnt/btr_pool/.snapshots/{root,home}/backup_*). This script NEVER creates or
# deletes those snapshots -- it locates the newest of each, bind-mounts them
# into a unified tree, and backs up from that frozen image. Run
# btrfs-snapshot-backup.sh first if no snapshot exists.
#
# Must be run as root.
#
# Usage:
#   sudo ./borg-system-backup.sh [backup] [--dry-run] [--verify]
#   sudo ./borg-system-backup.sh list
#   sudo ./borg-system-backup.sh info [ARCHIVE]
#   sudo ./borg-system-backup.sh check [--verify]
#   sudo ./borg-system-backup.sh prune-dry
#   sudo ./borg-system-backup.sh mount   <dir> [ARCHIVE]
#   sudo ./borg-system-backup.sh umount  <dir>
# ---------------------------------------------------------------------------

set -euo pipefail

VERSION="2.0"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
MOUNT_POINT="/run/media/USERNAME/11111111-1111-1111-1111-111111111111"
BORG_REPO="$MOUNT_POINT/borg-arch"          # Borg repository (separate from the old rsync arch-backup/)

SNAPSHOT_DIR="/mnt/btr_pool/.snapshots"     # Where btrfs-snapshot-backup.sh keeps its snapshots
ROOT_SNAP_DIR="$SNAPSHOT_DIR/root"          # Snapshots of @      (newest = highest timestamp)
HOME_SNAP_DIR="$SNAPSHOT_DIR/home"          # Snapshots of @home

STAGING="/run/arch-backup-src"              # tmpfs mountpoint for the unified bind-mounted tree
LOCK_FILE="/run/arch-backupr.lock"
LOG_FILE="/var/log/arch-backup.log"
LOG_MAX_BYTES=$((10 * 1024 * 1024))         # rotate log past 10 MiB

# Borg tunables
BORG_ENCRYPTION="none"                      # drive is LUKS; borg still checksums chunks for bit-rot detection
COMPRESSION="zstd,6"
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=6

# Paths excluded from the archive (relative to the backup root '.').
EXCLUDES=(
    'sh:home/*/.cache'
    'sh:home/*/.local/share/Trash'
    'sh:home/*/.Trash'
    'root/.cache'
    'var/cache/pacman/pkg'
    'var/tmp'
    'var/lib/systemd/coredump'
    'lost+found'
)

# Borg needs this to use an unencrypted repo without an interactive prompt.
export BORG_REPO
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

# ---------------------------------------------------------------------------
# Colors (disabled automatically when not a tty)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
err()     { echo -e "${RED}${BOLD}[ERR ]${RESET}  $*" >&2; }
banner()  { echo -e "${BOLD}$*${RESET}"; }
divider() { echo -e "${BOLD}══════════════════════════════════════════${RESET}"; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
COMMAND="backup"
DRY_RUN=0
VERIFY=0
MOUNT_TARGET=""
ARCHIVE_ARG=""

POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --verify)     VERIFY=1 ;;
        -*)           err "Unknown option: $arg"; exit 1 ;;
        *)            POSITIONAL+=("$arg") ;;
    esac
done

if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    COMMAND="${POSITIONAL[0]}"
fi
case "$COMMAND" in
    backup|list|check|prune-dry|info|mount|umount) ;;
    *) err "Unknown command: $COMMAND"; exit 1 ;;
esac
# Second positional is the mount dir (mount/umount) or an archive name (info).
if [[ ${#POSITIONAL[@]} -gt 1 ]]; then
    case "$COMMAND" in
        mount|umount) MOUNT_TARGET="${POSITIONAL[1]}" ;;
        info)         ARCHIVE_ARG="${POSITIONAL[1]}" ;;
    esac
fi

# ---------------------------------------------------------------------------
# Logging: tee to $LOG_FILE, rotating first if it has grown too large.
# ---------------------------------------------------------------------------
rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(stat -c '%s' "$LOG_FILE" 2>/dev/null || echo 0)
        if [[ "$size" -gt "$LOG_MAX_BYTES" ]]; then
            mv -f "$LOG_FILE" "$LOG_FILE.1"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
require_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Run this script as root: sudo $0 $*"
        exit 1
    fi
}

require_borg() {
    if ! command -v borg >/dev/null 2>&1; then
        err "borg is not installed. Install it with:  sudo pacman -S borg"
        exit 1
    fi
}

require_mount() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        err "External drive is not mounted at $MOUNT_POINT"
        exit 1
    fi
}

acquire_lock() {
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        err "Another arch-backupr run holds the lock ($LOCK_FILE). Aborting."
        exit 1
    fi
}

# Newest snapshot dir under $1, or empty string if none.
newest_snapshot() {
    find "$1" -maxdepth 1 -mindepth 1 -name 'backup_*' -type d 2>/dev/null | sort | tail -1
}

init_repo_if_needed() {
    if [[ -d "$BORG_REPO" && -f "$BORG_REPO/config" ]]; then
        return 0
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: repository $BORG_REPO does not exist; it would be created (borg init --encryption=$BORG_ENCRYPTION)."
        return 0
    fi
    info "Initializing new Borg repository: $BORG_REPO"
    borg init --encryption="$BORG_ENCRYPTION" "$BORG_REPO"
    ok "Repository created."
}

# ---------------------------------------------------------------------------
# Staging: bind-mount the newest root + home snapshots into a unified tree.
# ---------------------------------------------------------------------------
STAGING_UP=0
teardown_staging() {
    [[ $STAGING_UP -eq 1 ]] || return 0
    # Unmount in reverse order; fall back to lazy unmount if busy.
    if mountpoint -q "$STAGING/home" 2>/dev/null; then
        umount "$STAGING/home" 2>/dev/null || umount -l "$STAGING/home" 2>/dev/null || true
    fi
    if mountpoint -q "$STAGING" 2>/dev/null; then
        umount "$STAGING" 2>/dev/null || umount -l "$STAGING" 2>/dev/null || true
    fi
    rmdir "$STAGING" 2>/dev/null || true
    STAGING_UP=0
}
trap teardown_staging EXIT INT TERM

setup_staging() {
    local root_snap="$1" home_snap="$2"
    mkdir -p "$STAGING"
    STAGING_UP=1
    mount --bind "$root_snap" "$STAGING"
    if [[ ! -d "$STAGING/home" ]]; then
        err "The root snapshot has no /home mountpoint to bind onto: $root_snap"
        exit 1
    fi
    mount --bind "$home_snap" "$STAGING/home"
}

# ---------------------------------------------------------------------------
# backup
# ---------------------------------------------------------------------------
do_backup() {
    local root_snap home_snap
    root_snap="$(newest_snapshot "$ROOT_SNAP_DIR")"
    home_snap="$(newest_snapshot "$HOME_SNAP_DIR")"

    if [[ -z "$root_snap" ]]; then
        err "No root snapshot found in $ROOT_SNAP_DIR. Run btrfs-snapshot-backup.sh first."
        exit 1
    fi
    if [[ -z "$home_snap" ]]; then
        err "No home snapshot found in $HOME_SNAP_DIR. Run btrfs-snapshot-backup.sh first."
        exit 1
    fi

    local start_epoch start_time
    start_epoch=$(date +%s)
    start_time=$(date '+%Y-%m-%d %H:%M:%S')

    divider
    banner " Arch Linux System Backup (Borg v$VERSION)"
    divider
    info "Started    : $start_time"
    info "Root snap  : $root_snap"
    info "Home snap  : $home_snap"
    info "Repository : $BORG_REPO"
    info "Log        : $LOG_FILE"
    [[ $DRY_RUN -eq 1 ]] && warn "Mode       : DRY RUN — nothing will be written to the repo"
    divider

    init_repo_if_needed
    setup_staging "$root_snap" "$home_snap"

    # Build exclude args
    local exclude_args=()
    local e
    for e in "${EXCLUDES[@]}"; do
        exclude_args+=("--exclude" "$e")
    done

    local create_opts=(--stats --compression "$COMPRESSION" --exclude-caches)
    # No --one-file-system: /home is a bind mount inside the staging tree and
    # must be traversed. Nothing else is mounted under staging (the snapshot's
    # pseudo-fs dirs are empty), so there is nowhere else for borg to wander.
    [[ -t 1 ]] && create_opts+=(--progress)
    [[ $DRY_RUN -eq 1 ]] && create_opts+=(--dry-run --list)

    local archive="::system-{now:%Y%m%d-%H%M%S}"
    info "Creating archive $archive ..."

    # Backup from inside the staging tree so stored paths are clean (home/…, etc/…).
    local rc=0
    ( cd "$STAGING" && borg create "${create_opts[@]}" "${exclude_args[@]}" "$archive" . ) || rc=$?

    if [[ $rc -ne 0 ]]; then
        err "borg create failed (exit $rc)."
        _finish "$start_epoch" "$rc"
        return $rc
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        ok "DRY RUN complete — no archive was written, pruning/verification skipped."
        _finish "$start_epoch" 0
        return 0
    fi

    ok "Archive created."

    # Prune old archives, then reclaim space.
    info "Pruning old archives (keep ${KEEP_DAILY}d / ${KEEP_WEEKLY}w / ${KEEP_MONTHLY}m) ..."
    borg prune --list --stats \
        --glob-archives 'system-*' \
        --keep-daily "$KEEP_DAILY" \
        --keep-weekly "$KEEP_WEEKLY" \
        --keep-monthly "$KEEP_MONTHLY" \
        "$BORG_REPO" || warn "Prune reported a problem."

    info "Compacting repository to free space ..."
    borg compact "$BORG_REPO" || warn "Compact reported a problem (older borg without 'compact'?)."

    # Integrity check: quick every run, deep only with --verify.
    if [[ $VERIFY -eq 1 ]]; then
        info "Verifying repository AND data (borg check --verify-data) ..."
        borg check --verify-data "$BORG_REPO" || warn "Verification reported a problem."
    else
        info "Checking repository consistency (borg check --repository-only) ..."
        borg check --repository-only "$BORG_REPO" || warn "Repository check reported a problem."
    fi

    _finish "$start_epoch" 0
}

_finish() {
    local start_epoch="$1" rc="$2"
    local end_epoch end_time elapsed elapsed_fmt
    end_epoch=$(date +%s)
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    elapsed=$(( end_epoch - start_epoch ))
    elapsed_fmt=$(printf '%02dh %02dm %02ds' \
        $(( elapsed / 3600 )) $(( (elapsed % 3600) / 60 )) $(( elapsed % 60 )))
    divider
    info "Finished   : $end_time"
    info "Elapsed    : $elapsed_fmt"
    if [[ "$rc" -eq 0 ]]; then
        ok "Status     : SUCCESS"
    else
        err "Status     : FAILED (exit $rc)"
    fi
    divider
}

# ---------------------------------------------------------------------------
# Other commands
# ---------------------------------------------------------------------------
do_list() {
    borg list "$BORG_REPO"
}

do_info() {
    if [[ -n "$ARCHIVE_ARG" ]]; then
        borg info "$BORG_REPO::$ARCHIVE_ARG"
    else
        borg info "$BORG_REPO"
    fi
}

do_check() {
    if [[ $VERIFY -eq 1 ]]; then
        info "borg check --verify-data (reads every chunk; slow) ..."
        borg check --verify-data "$BORG_REPO"
    else
        info "borg check --repository-only ..."
        borg check --repository-only "$BORG_REPO"
    fi
    ok "Check complete."
}

do_prune_dry() {
    info "Prune preview (keep ${KEEP_DAILY}d / ${KEEP_WEEKLY}w / ${KEEP_MONTHLY}m) — nothing will be deleted:"
    borg prune --dry-run --list \
        --glob-archives 'system-*' \
        --keep-daily "$KEEP_DAILY" \
        --keep-weekly "$KEEP_WEEKLY" \
        --keep-monthly "$KEEP_MONTHLY" \
        "$BORG_REPO"
}

do_mount() {
    if [[ -z "$MOUNT_TARGET" ]]; then
        err "Usage: $0 mount <dir> [ARCHIVE]"
        exit 1
    fi
    mkdir -p "$MOUNT_TARGET"
    if [[ -n "$ARCHIVE_ARG" ]]; then
        borg mount "$BORG_REPO::$ARCHIVE_ARG" "$MOUNT_TARGET"
    else
        borg mount "$BORG_REPO" "$MOUNT_TARGET"
    fi
    ok "Mounted at $MOUNT_TARGET. Browse it, then: $0 umount $MOUNT_TARGET"
}

do_umount() {
    if [[ -z "$MOUNT_TARGET" ]]; then
        err "Usage: $0 umount <dir>"
        exit 1
    fi
    borg umount "$MOUNT_TARGET"
    ok "Unmounted $MOUNT_TARGET"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
main() {
    require_root "$@"
    require_borg
    require_mount
    rotate_log

    case "$COMMAND" in
        backup)
            acquire_lock
            do_backup 2>&1 | tee -a "$LOG_FILE"
            exit "${PIPESTATUS[0]}"
            ;;
        list)      do_list ;;
        info)      do_info ;;
        check)     do_check ;;
        prune-dry) do_prune_dry ;;
        mount)     do_mount ;;
        umount)    do_umount ;;
    esac
}

main "$@"
