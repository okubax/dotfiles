#!/bin/bash
# Full system backup to external hard drive using rsync.
# Must be run as root for a complete backup.
#
# Usage: sudo ./arch-backupr.sh [--dry-run]

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors (disabled automatically when not a tty)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
err()     { echo -e "${RED}${BOLD}[ERR ]${RESET}  $*" >&2; }
banner()  { echo -e "${BOLD}$*${RESET}"; }
divider() { echo -e "${BOLD}══════════════════════════════════════════${RESET}"; }

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
DRY_RUN=""
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN="--dry-run" ;;
        *) err "Unknown argument: $arg"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DEST="/run/media/ajibola/c61b8c20-ac19-47ec-ab27-bc14e4d0cbcf/arch-backup"
LOG_FILE="/var/log/rsync_backup.log"

# ---------------------------------------------------------------------------
# Exclusions
# Files/dirs matching these patterns are:
#   • never transferred to $DEST
#   • removed from $DEST if they were previously backed up (--delete-excluded)
# ---------------------------------------------------------------------------
EXCLUDES=(
    "/dev/*"
    "/proc/*"
    "/sys/*"
    "/tmp/*"
    "/run/*"
    "/mnt/*"                           # all mounts under /mnt (includes btr_pool)
    "/mnt/btr_pool/.snapshots"         # btrfs snapshot subvolumes
    "/media/*"
    "/lost+found"
    "/var/tmp/*"
    "/var/cache/pacman/pkg/*"          # re-downloadable; skip to save space
    "/home/*/.cache/*"                 # application caches
    "/home/*/.Trash/*"                 # trash bins
    "/swapfile"
    "/.snapshots/*"                    # snapper / timeshift snapshots at root
)

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Run this script as root: sudo $0"
    exit 1
fi

MOUNT_POINT="/run/media/ajibola/c61b8c20-ac19-47ec-ab27-bc14e4d0cbcf"
if ! mountpoint -q "$MOUNT_POINT"; then
    err "External drive is not mounted at $MOUNT_POINT"
    exit 1
fi

mkdir -p "$DEST"

# ---------------------------------------------------------------------------
# Build --exclude flags
# ---------------------------------------------------------------------------
EXCLUDE_ARGS=()
for excl in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=("--exclude=$excl")
done

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
START_EPOCH=$(date +%s)
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

{
    divider
    banner " Arch Linux System Backup"
    divider
    info "Started    : $START_TIME"
    info "Source     : /"
    info "Destination: $DEST"
    info "Log        : $LOG_FILE"
    [[ -n "$DRY_RUN" ]] && warn "Mode       : DRY RUN — no changes will be written"
    divider
} | tee -a "$LOG_FILE"

# Flags:
#   -a / --archive        recursive + preserve permissions, timestamps, symlinks, owner, group
#   -A / --acls           preserve ACLs
#   -X / --xattrs         preserve extended attributes (capabilities, SELinux labels, etc.)
#   -H / --hard-links     preserve hard links
#   --numeric-ids         store numeric UID/GID rather than mapping by name
#   --delete              remove destination files no longer in source
#   --delete-excluded     also remove destination files that match the exclusion list
#   --itemize-changes     print one line per changed/deleted entry (unchanged files are silent)
#   --info=progress2      single-line running total: bytes transferred, speed, ETA
#   --human-readable      print sizes in K/M/G
rsync \
    -aAXH \
    --numeric-ids \
    --delete \
    --delete-excluded \
    --itemize-changes \
    --info=progress2 \
    --human-readable \
    $DRY_RUN \
    "${EXCLUDE_ARGS[@]}" \
    / "$DEST/" \
    2>&1 | tee -a "$LOG_FILE"
RSYNC_EXIT=${PIPESTATUS[0]}

END_EPOCH=$(date +%s)
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
ELAPSED=$(( END_EPOCH - START_EPOCH ))
ELAPSED_FMT=$(printf '%02dh %02dm %02ds' \
    $(( ELAPSED / 3600 )) \
    $(( (ELAPSED % 3600) / 60 )) \
    $(( ELAPSED % 60 )))

{
    divider
    info "Finished   : $END_TIME"
    info "Elapsed    : $ELAPSED_FMT"
    if [[ $RSYNC_EXIT -eq 0 ]]; then
        ok "Status     : SUCCESS"
    elif [[ $RSYNC_EXIT -eq 24 ]]; then
        warn "Status     : SUCCESS (some files vanished during transfer — this is normal)"
    else
        err "Status     : FAILED (rsync exit code $RSYNC_EXIT)"
    fi
    divider
} | tee -a "$LOG_FILE"

exit $RSYNC_EXIT
