#!/bin/bash

# BTRFS Simplified Snapshot and Backup Script for Laptop - Enhanced Version
# Usage: ./btrfs-snapshot-backup.sh [backup|cleanup|status|health|validate|list|delete|
#                          restore|scrub|exclude-caches] [--dry-run]
#                          [--force-new-parent] [--recovery]
# Version: 2.4 - Robustness + space efficiency: reclaimable preflight, recovery
#          mode, staleness/scrub/restore, external compression, chain mode option

set -euo pipefail

# Global variables
DRY_RUN=false
FORCE_NEW_PARENT=false
RECOVERY_MODE=false
LOCK_FILE="/var/run/btrfs_backup.lock"
LOCK_FD=200
SCRIPT_PID=$$
OPERATION_FAILED=false

# Configuration
BTRFS_POOL="/mnt/btr_pool"              # Main BTRFS pool mount point
ROOT_SUBVOLUME="$BTRFS_POOL/@"          # Root subvolume path
HOME_SUBVOLUME="$BTRFS_POOL/@home"      # Home subvolume path
SNAPSHOT_DIR="$BTRFS_POOL/.snapshots"   # Local snapshot directory
EXTERNAL_MOUNT="/run/media/USERNAME/00000000-0000-0000-0000-000000000000"  # External drive mount point
EXTERNAL_BACKUP_DIR="$EXTERNAL_MOUNT/btrfs_backups"
LOG_FILE="/var/log/btrfs_backup.log"

# Subvolumes to backup (add more if needed)
declare -a SUBVOLUMES=("root:$ROOT_SUBVOLUME" "home:$HOME_SUBVOLUME")

# Device identification for external drive
EXTERNAL_DEVICE_UUID="00000000-0000-0000-0000-000000000000"  # Your external drive UUID
EXTERNAL_DEVICE_LABEL=""                # Or set device label here if preferred

# Retention settings (optimized for single-parent + incrementals strategy)
LOCAL_SNAPSHOT_KEEP_DAYS=30              # Keep local snapshots for 30 days
INCREMENTAL_KEEP_DAYS=30                 # Keep incrementals for 30 days
MAX_INCREMENTAL_CHAIN_LENGTH=90          # Warn when chain exceeds this (consider new parent)

# Parent backup strategy: SINGLE PARENT ONLY
# - Only ONE parent backup exists at any time
# - New parent created ONLY when: (1) no parent exists, (2) --force-new-parent flag used
# - When creating new parent, ALL old backups are deleted first (maximum space efficiency)

# Advanced settings
DISK_SPACE_WARNING_THRESHOLD=80         # Warn when disk usage exceeds this percentage
DISK_SPACE_CRITICAL_THRESHOLD=90        # Critical threshold for disk usage
DISK_SPACE_REQUIRED_PERCENT=15          # Minimum free space required for parent backup
BACKUP_VERIFICATION_ENABLED=true        # Enable backup verification
MOUNT_TIMEOUT=10                        # Timeout for mount point checks (seconds)
ENABLE_BANDWIDTH_LIMIT=false            # Enable bandwidth limiting for send/receive
BANDWIDTH_LIMIT_MB=50                   # Bandwidth limit in MB/s (if enabled)
ENABLE_NOTIFICATIONS=true               # Enable notification system

# Staleness / freshness
STALE_BACKUP_WARN_DAYS=14               # Warn if the newest external backup is older than this
PARENT_REFRESH_SUGGEST_DAYS=90         # Suggest --force-new-parent when the parent is older than this

# External drive compression. btrfs send streams uncompressed logical data, so
# even though the source pool uses zstd, the external stores it uncompressed
# unless the receiving filesystem compresses on write. Remounting the external
# with compress-force reclaims significant space on a small backup drive.
ENABLE_EXTERNAL_COMPRESSION=true        # Remount external with compression before backup
EXTERNAL_COMPRESSION="zstd:3"           # algorithm:level passed to compress-force

# Incremental strategy:
#   parent = every incremental diffs from the single parent snapshot. Simple and
#            robust: restore needs only parent + the newest incremental, and any
#            incremental can be deleted independently. Each incremental is a
#            cumulative diff from the parent, so overlapping changes cost space.
#   chain  = every incremental diffs from the PREVIOUS snapshot. Smaller
#            incrementals (only each period's delta), but restore needs the whole
#            chain in order and the chain must never lose a link.
# Default "parent" preserves the original v2.3 behaviour; switch deliberately.
INCREMENTAL_MODE="parent"

# =============================================================================
# SIGNAL HANDLING AND CLEANUP
# =============================================================================

# Cleanup function called on script exit
cleanup_on_exit() {
    local exit_code=$?

    # Release lock if we hold it
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ "$lock_pid" == "$SCRIPT_PID" ]]; then
            rm -f "$LOCK_FILE"
            log "Released lock file"
        fi
    fi

    # Report final status
    if [[ $exit_code -eq 0 ]] && [[ "$OPERATION_FAILED" == "false" ]]; then
        log "Script completed successfully"
    else
        log "Script exited with errors (exit code: $exit_code)"
    fi

    exit $exit_code
}

# Handle interrupt signals
handle_signal() {
    local signal=$1
    log "Received signal $signal - cleaning up and exiting"
    OPERATION_FAILED=true
    exit 130
}

# Setup signal traps
trap cleanup_on_exit EXIT
trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM

# =============================================================================
# LOCKING MECHANISM
# =============================================================================

# Acquire exclusive lock to prevent concurrent runs
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")

        # Check if process is still running
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            error_exit "Another instance is already running (PID: $lock_pid). Lock file: $LOCK_FILE"
        else
            log "Removing stale lock file (PID: $lock_pid)"
            rm -f "$LOCK_FILE"
        fi
    fi

    # Create lock file with our PID
    echo "$SCRIPT_PID" > "$LOCK_FILE" || error_exit "Failed to create lock file: $LOCK_FILE"
    log "Acquired lock file: $LOCK_FILE"
}

# =============================================================================
# LOGGING AND ERROR HANDLING
# =============================================================================

# Logging function (outputs to stderr to not interfere with function returns)
log() {
    local prefix=""
    if [[ "$DRY_RUN" == "true" ]]; then
        prefix="[DRY-RUN] "
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${prefix}$1" | tee -a "$LOG_FILE" >&2
}

# Error handling with exit
error_exit() {
    log "ERROR: $1"
    OPERATION_FAILED=true
    exit 1
}

# Error handling that allows continuation
error_continue() {
    log "ERROR: $1 - continuing with remaining operations"
    OPERATION_FAILED=true
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate UUID format
validate_uuid() {
    local uuid="$1"
    if [[ -z "$uuid" ]]; then
        return 0  # Empty UUID is allowed (will use label or mountpoint)
    fi

    if [[ ! "$uuid" =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$ ]]; then
        error_exit "Invalid UUID format: $uuid"
    fi
}

# Validate configuration on startup
validate_configuration() {
    log "Validating configuration..."

    # Validate UUID format
    validate_uuid "$EXTERNAL_DEVICE_UUID"

    # Check BTRFS pool exists
    if [[ ! -d "$BTRFS_POOL" ]]; then
        error_exit "BTRFS pool not found at $BTRFS_POOL"
    fi

    # Verify BTRFS pool is actually a BTRFS filesystem
    if ! btrfs filesystem show "$BTRFS_POOL" >/dev/null 2>&1; then
        error_exit "$BTRFS_POOL is not a BTRFS filesystem"
    fi

    # Validate retention settings
    if [[ $LOCAL_SNAPSHOT_KEEP_DAYS -lt 1 ]]; then
        error_exit "LOCAL_SNAPSHOT_KEEP_DAYS must be at least 1"
    fi

    if [[ $INCREMENTAL_KEEP_DAYS -lt 1 ]]; then
        error_exit "INCREMENTAL_KEEP_DAYS must be at least 1"
    fi

    log "Configuration validation passed"
}

# =============================================================================
# NOTIFICATION SYSTEM
# =============================================================================

# Send notifications for critical events
send_notification() {
    local level="$1"  # INFO, WARNING, ERROR, CRITICAL
    local message="$2"

    # Always log it
    log "[$level] $message"

    # Send notification for ERROR and CRITICAL levels
    if [[ "$ENABLE_NOTIFICATIONS" != "true" ]]; then
        return 0
    fi

    if [[ "$level" == "CRITICAL" || "$level" == "ERROR" ]]; then
        # Method 1: systemd journal
        logger -t btrfs_backup -p "user.err" "[$level] $message" 2>/dev/null || true

        # Method 2: Wall message (if users logged in)
        echo "BTRFS Backup $level: $message" | wall 2>/dev/null || true

        # Method 3: Desktop notification (if X session available for user USERNAME)
        if [[ -n "${DISPLAY:-}" ]]; then
            sudo -u USERNAME DISPLAY="$DISPLAY" notify-send -u critical \
                "BTRFS Backup $level" "$message" 2>/dev/null || true
        fi
    fi
}

# =============================================================================
# SPACE MANAGEMENT FUNCTIONS
# =============================================================================

# Get the size of a path in bytes, preferring btrfs-aware exclusive size.
# btrfs filesystem du reports real allocation (accounting for compression and
# reflinks) instead of du's apparent size, which over-estimates on btrfs.
get_path_size_bytes() {
    local path="$1"
    [[ -d "$path" ]] || { echo "0"; return; }

    # 'btrfs filesystem du -s --raw' prints a header then a row whose first
    # column is the total (referenced) size in bytes.
    local size
    size=$(btrfs filesystem du -s --raw "$path" 2>/dev/null | awk 'NR==2 {print $1}')
    if [[ -n "$size" && "$size" =~ ^[0-9]+$ ]]; then
        echo "$size"
    else
        du -sb "$path" 2>/dev/null | awk '{print $1}' || echo "0"
    fi
}

# Total size (GB) of all existing backups for a subvolume. This is the space
# that will be reclaimed if we delete them before creating a new parent.
get_existing_backup_size_gb() {
    local subvol_name="$1"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"
    [[ -d "$backup_dir" ]] || { echo "0"; return; }

    local total_bytes=0
    while IFS= read -r backup; do
        if [[ -n "$backup" ]]; then
            local sz
            sz=$(get_path_size_bytes "$backup")
            total_bytes=$((total_bytes + sz))
        fi
    done < <(find "$backup_dir" -maxdepth 1 \( -name "parent_*" -o -name "incremental_*" \) -type d 2>/dev/null)

    echo $((total_bytes / 1024 / 1024 / 1024))
}

# Pre-flight space check before operations.
#   $1 operation      - "parent" or "incremental"
#   $2 target_path    - filesystem to check
#   $3 reclaimable_gb - (optional) space that will be freed by deleting existing
#                       backups before this operation (credited to availability).
#                       Fixes the bug where force-new-parent aborted on a
#                       near-full drive because the check ran before the delete.
preflight_space_check() {
    local operation="$1"  # "parent" or "incremental"
    local target_path="$2"
    local reclaimable_gb="${3:-0}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD CHECK: Disk space for $operation operation"
        return 0
    fi

    log "Performing pre-flight space check for $operation operation..."

    local required_gb=0
    local available_gb=0

    if [[ "$operation" == "parent" ]]; then
        # For parent backup, estimate based on source subvolume size + 20% buffer
        local source_size_bytes=0
        for subvol_entry in "${SUBVOLUMES[@]}"; do
            local path="${subvol_entry##*:}"
            if [[ -d "$path" ]]; then
                local size
                size=$(get_path_size_bytes "$path")
                source_size_bytes=$((source_size_bytes + size))
            fi
        done

        required_gb=$(( (source_size_bytes * 12 / 10) / 1024 / 1024 / 1024 + 5 ))  # +20% buffer +5GB extra
        log "Estimated space needed for parent backup: ${required_gb}GB"
    else
        # For incremental, need much less space (estimate 5GB for changes)
        required_gb=5
        log "Estimated space needed for incremental backup: ${required_gb}GB"
    fi

    # Check available space, then credit space that will be freed by deleting
    # existing backups first (single-parent policy deletes before it re-sends).
    available_gb=$(df --output=avail -BG "$target_path" 2>/dev/null | tail -1 | sed 's/G//' || echo "0")
    local effective_available_gb=$((available_gb + reclaimable_gb))

    if [[ $reclaimable_gb -gt 0 ]]; then
        log "Available on target: ${available_gb}GB + ${reclaimable_gb}GB reclaimable = ${effective_available_gb}GB effective"
    else
        log "Available space on target: ${available_gb}GB"
    fi

    if [[ $effective_available_gb -lt $required_gb ]]; then
        send_notification "CRITICAL" "Insufficient space for $operation: need ${required_gb}GB, have ${effective_available_gb}GB (incl. ${reclaimable_gb}GB reclaimable)"
        error_exit "Insufficient disk space for $operation operation: need ${required_gb}GB, have ${effective_available_gb}GB effective"
    fi

    # Also check percentage-based requirement, crediting reclaimable space so a
    # legitimate parent refresh isn't blocked on a nearly-full drive.
    local usage=$(check_disk_space "$target_path" "target" 2>/dev/null || echo "100")
    local total_gb=$(df --output=size -BG "$target_path" 2>/dev/null | tail -1 | sed 's/G//' || echo "0")
    local free_percent=$((100 - usage))
    if [[ $total_gb -gt 0 ]]; then
        free_percent=$(( (effective_available_gb * 100) / total_gb ))
    fi

    if [[ "$operation" == "parent" ]] && [[ $free_percent -lt $DISK_SPACE_REQUIRED_PERCENT ]]; then
        send_notification "CRITICAL" "Insufficient free space percentage: ${free_percent}% (need ${DISK_SPACE_REQUIRED_PERCENT}%)"
        error_exit "Insufficient free space percentage for parent backup: ${free_percent}% free (need at least ${DISK_SPACE_REQUIRED_PERCENT}%)"
    fi

    log "Pre-flight space check passed: ${effective_available_gb}GB effective available (${free_percent}% free)"
    return 0
}

# Delete all backups for a subvolume (for creating new parent)
delete_all_backups_for_subvolume() {
    local subvol_name="$1"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"

    if [[ ! -d "$backup_dir" ]]; then
        log "No backup directory exists for $subvol_name - nothing to delete"
        return 0
    fi

    log "=== DELETING ALL BACKUPS FOR $subvol_name TO SAVE SPACE ==="

    # Find all backups (parents and incrementals)
    local all_backups=()
    while IFS= read -r backup; do
        if [[ -n "$backup" ]]; then
            all_backups+=("$backup")
        fi
    done < <(find "$backup_dir" -maxdepth 1 \( -name "parent_*" -o -name "incremental_*" \) -type d 2>/dev/null | sort)

    if [[ ${#all_backups[@]} -eq 0 ]]; then
        log "No existing backups found for $subvol_name"
        return 0
    fi

    log "Found ${#all_backups[@]} backup(s) to delete for $subvol_name"

    # Delete each backup
    local delete_failed=false
    for backup in "${all_backups[@]}"; do
        local backup_name=$(basename "$backup")
        log "Deleting: $backup_name"

        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD DELETE: $backup"
        else
            if ! btrfs subvolume delete "$backup" >> "$LOG_FILE" 2>&1; then
                error_continue "Failed to delete $backup_name"
                delete_failed=true
                # Continue trying to delete others, but mark as failed
            else
                log "Successfully deleted: $backup_name"
            fi
        fi
    done

    if [[ "$delete_failed" == "true" ]]; then
        send_notification "ERROR" "Some backups failed to delete for $subvol_name - check logs"
        error_exit "Failed to delete all backups for $subvol_name - aborting to prevent partial cleanup"
    fi

    log "Successfully deleted all ${#all_backups[@]} backup(s) for $subvol_name"
    return 0
}

# Enforce single-parent policy (validation check)
enforce_single_parent_policy() {
    local subvol_name="$1"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"

    if [[ ! -d "$backup_dir" ]]; then
        return 0  # No backups yet
    fi

    # Count existing parents
    local parent_count=$(find "$backup_dir" -maxdepth 1 -name "parent_*" -type d 2>/dev/null | wc -l)

    if [[ $parent_count -gt 1 ]]; then
        log "WARNING: POLICY VIOLATION - Found $parent_count parents for $subvol_name (should be 1)"
        send_notification "WARNING" "Multiple parent backups detected for $subvol_name: $parent_count (expected 1)"
        return 1
    fi

    if [[ $parent_count -eq 1 ]]; then
        log "Single-parent policy verified: exactly 1 parent backup for $subvol_name"
    else
        log "No parent backup found for $subvol_name (will create one)"
    fi

    return 0
}

# Get incremental chain length for a subvolume
get_incremental_chain_length() {
    local subvol_name="$1"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"

    if [[ ! -d "$backup_dir" ]]; then
        echo "0"
        return
    fi

    # Get current parent
    local parent=$(get_latest_parent_backup "$subvol_name")
    if [[ -z "$parent" ]]; then
        echo "0"
        return
    fi

    # Extract parent timestamp
    local parent_timestamp=$(parse_timestamp "$(basename "$parent")")
    if [[ $parent_timestamp -eq 0 ]]; then
        echo "0"
        return
    fi

    local parent_timestamp_str=$(date -d "@$parent_timestamp" '+%Y%m%d_%H%M%S')

    # Count incrementals for this parent
    find "$backup_dir" -maxdepth 1 -name "incremental_${parent_timestamp_str}_*" -type d 2>/dev/null | wc -l
}

# Check if incremental chain is getting too long
check_chain_length() {
    local subvol_name="$1"
    local chain_length=$(get_incremental_chain_length "$subvol_name")

    log "Incremental chain length for $subvol_name: $chain_length"

    if [[ $chain_length -ge $MAX_INCREMENTAL_CHAIN_LENGTH ]]; then
        log "WARNING: Incremental chain for $subvol_name has $chain_length backups (threshold: $MAX_INCREMENTAL_CHAIN_LENGTH)"
        log "RECOMMENDATION: Consider creating a new parent backup with: --force-new-parent"
        send_notification "WARNING" "Long incremental chain for $subvol_name: $chain_length backups. Consider refreshing parent."

        # Return 1 to indicate warning condition
        return 1
    fi

    return 0
}

# Check if a local snapshot is referenced by external parent backup
is_snapshot_referenced_by_external_parent() {
    local subvol_name="$1"
    local snapshot_name="$2"

    if ! is_external_drive_mounted; then
        return 1  # Can't check, assume not referenced
    fi

    # Get latest parent backup
    local parent=$(get_latest_parent_backup "$subvol_name")
    if [[ -z "$parent" ]]; then
        return 1  # No parent, not referenced
    fi

    # Extract timestamp from parent name
    local parent_timestamp_str=$(basename "$parent" | grep -oP '\d{8}_\d{6}' | head -1 || echo "")
    if [[ -z "$parent_timestamp_str" ]]; then
        return 1
    fi

    # Extract timestamp from snapshot name
    local snapshot_timestamp_str=$(echo "$snapshot_name" | grep -oP '\d{8}_\d{6}' || echo "")
    if [[ -z "$snapshot_timestamp_str" ]]; then
        return 1
    fi

    # Check if timestamps match
    if [[ "$parent_timestamp_str" == "$snapshot_timestamp_str" ]]; then
        log "Snapshot $snapshot_name is referenced by external parent backup"
        return 0  # This snapshot is the parent reference
    fi

    return 1
}

# Check if a local snapshot backs ANY external backup (parent OR incremental).
# In chain mode every such snapshot is a link in the send chain and must not be
# pruned, or newer incrementals become unrestorable.
is_snapshot_referenced_by_any_external() {
    local subvol_name="$1"
    local snapshot_name="$2"

    is_external_drive_mounted || return 1

    local snap_ts
    snap_ts=$(echo "$snapshot_name" | grep -oP '\d{8}_\d{6}' | head -1)
    [[ -n "$snap_ts" ]] || return 1

    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"
    [[ -d "$backup_dir" ]] || return 1

    while IFS= read -r b; do
        [[ -n "$b" ]] || continue
        local bts
        bts=$(basename "$b" | grep -oP '\d{8}_\d{6}' | tail -1)
        if [[ "$bts" == "$snap_ts" ]]; then
            return 0
        fi
    done < <(find "$backup_dir" -maxdepth 1 \( -name "parent_*" -o -name "incremental_*" \) -type d 2>/dev/null)

    return 1
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Parse timestamp from backup name and return unix epoch
# Arguments: backup_name (format: backup_YYYYMMDD_HHMMSS, parent_YYYYMMDD_HHMMSS, or incremental_...)
# Returns: unix timestamp or 0 if parsing fails
parse_timestamp() {
    local name="$1"

    # Extract timestamp from name - handle all backup formats
    # Matches: backup_20241230_143022, parent_20241230_143022, incremental_20241230_143022_20250101_120000
    if [[ $name =~ ([0-9]{8})_([0-9]{6}) ]]; then
        local date_part="${BASH_REMATCH[1]}"
        local time_part="${BASH_REMATCH[2]}"

        # Convert to ISO format for date command (more portable)
        local iso_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2}"
        local iso_time="${time_part:0:2}:${time_part:2:2}:${time_part:4:2}"

        # Get unix timestamp (returns 0 on failure)
        date -d "$iso_date $iso_time" +%s 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Safe command execution without eval
execute_command() {
    local description="$1"
    shift
    local cmd=("$@")
    local allow_failure="${!#}"  # Last argument

    # Check if last arg is true/false for allow_failure
    if [[ "$allow_failure" == "true" || "$allow_failure" == "false" ]]; then
        unset 'cmd[-1]'  # Remove allow_failure from command array
    else
        allow_failure="false"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD EXECUTE: ${cmd[*]}"
        log "DESCRIPTION: $description"
        return 0
    else
        log "EXECUTING: $description"
        log "COMMAND: ${cmd[*]}"

        if "${cmd[@]}"; then
            log "SUCCESS: $description"
            return 0
        else
            if [[ "$allow_failure" == "true" ]]; then
                error_continue "FAILED: $description - Command was: ${cmd[*]}"
                return 1
            else
                error_exit "FAILED: $description - Command was: ${cmd[*]}"
            fi
        fi
    fi
}

# Check disk space and return usage percentage
check_disk_space() {
    local path="$1"
    local description="$2"

    if [[ ! -d "$path" ]]; then
        log "Cannot check disk space for $description - path does not exist: $path"
        return 1
    fi

    local usage_info=$(df "$path" | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$usage_info"
}

# Disk space warning system with pre-flight check
check_and_warn_disk_space() {
    local path="$1"
    local description="$2"
    local require_minimum="${3:-false}"

    local usage=$(check_disk_space "$path" "$description")

    if [[ -z "$usage" ]]; then
        log "WARNING: Could not determine disk usage for $description"
        return 1
    fi

    log "Disk usage for $description: ${usage}%"

    # Check if we have minimum required free space
    if [[ "$require_minimum" == "true" ]]; then
        local free_percent=$((100 - usage))
        if [[ $free_percent -lt $DISK_SPACE_REQUIRED_PERCENT ]]; then
            error_exit "Insufficient disk space for $description: ${free_percent}% free (need at least ${DISK_SPACE_REQUIRED_PERCENT}%)"
        fi
    fi

    if [[ $usage -ge $DISK_SPACE_CRITICAL_THRESHOLD ]]; then
        log "CRITICAL: Disk usage for $description is ${usage}% (threshold: ${DISK_SPACE_CRITICAL_THRESHOLD}%)"
        log "CRITICAL: Immediate action required - consider cleaning up old backups"
        return 2
    elif [[ $usage -ge $DISK_SPACE_WARNING_THRESHOLD ]]; then
        log "WARNING: Disk usage for $description is ${usage}% (threshold: ${DISK_SPACE_WARNING_THRESHOLD}%)"
        log "WARNING: Consider cleaning up old backups soon"
        return 1
    else
        log "Disk usage for $description is healthy: ${usage}%"
        return 0
    fi
}

# Enhanced backup verification function
verify_backup() {
    local backup_path="$1"
    local description="$2"

    if [[ "${BACKUP_VERIFICATION_ENABLED}" != "true" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD VERIFY: backup integrity for $description"
        return 0
    fi

    log "Verifying backup integrity for $description..."

    # Check if backup exists and is a valid subvolume
    if ! btrfs subvolume show "$backup_path" >/dev/null 2>&1; then
        log "ERROR: Backup verification failed for $description - not a valid subvolume"
        return 1
    fi

    # Check if the backup is readable
    if ! [[ -r "$backup_path" ]]; then
        log "ERROR: Backup verification failed for $description - not readable"
        return 1
    fi

    # Check a few key directories exist (basic sanity check)
    local key_paths=()
    if [[ "$description" =~ "root" ]]; then
        key_paths=("$backup_path/etc" "$backup_path/usr" "$backup_path/var")
    elif [[ "$description" =~ "home" ]]; then
        key_paths=("$backup_path")  # Just check the home path itself
    fi

    for key_path in "${key_paths[@]}"; do
        if [[ -n "$key_path" ]] && [[ ! -d "$key_path" ]]; then
            log "WARNING: Expected directory missing in backup: $key_path"
        fi
    done

    log "SUCCESS: Backup verification passed for $description"
    return 0
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Check if BTRFS pool and subvolumes exist
check_subvolumes() {
    if [[ ! -d "$BTRFS_POOL" ]]; then
        error_exit "BTRFS pool not found at $BTRFS_POOL"
    fi

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local path="${subvol_entry##*:}"

        if [[ ! -d "$path" ]]; then
            error_exit "Subvolume $name not found at $path"
        fi

        # Verify it's actually a subvolume
        if ! btrfs subvolume show "$path" >/dev/null 2>&1; then
            error_exit "$path is not a valid BTRFS subvolume"
        fi

        log "Verified subvolume $name at $path"
    done
}

# Ensure snapshot directory exists
ensure_snapshot_dir() {
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD CREATE: snapshot directory $SNAPSHOT_DIR"
        else
            mkdir -p "$SNAPSHOT_DIR"
            log "Created snapshot directory: $SNAPSHOT_DIR"
        fi
    else
        log "Snapshot directory exists: $SNAPSHOT_DIR"
    fi
}

# Check if external drive is available (connected and can be mounted)
is_external_drive_available() {
    local device_found=false

    # Check by UUID if provided
    if [[ -n "$EXTERNAL_DEVICE_UUID" ]]; then
        if blkid | grep -q "UUID=\"$EXTERNAL_DEVICE_UUID\""; then
            device_found=true
        fi
    fi

    # Check by label if provided and UUID check didn't find it
    if [[ "$device_found" == false && -n "$EXTERNAL_DEVICE_LABEL" ]]; then
        if blkid | grep -q "LABEL=\"$EXTERNAL_DEVICE_LABEL\""; then
            device_found=true
        fi
    fi

    # If no UUID or label specified, check if anything is mounted at the mount point
    if [[ "$device_found" == false && -z "$EXTERNAL_DEVICE_UUID" && -z "$EXTERNAL_DEVICE_LABEL" ]]; then
        if timeout "$MOUNT_TIMEOUT" mountpoint -q "$EXTERNAL_MOUNT" 2>/dev/null; then
            device_found=true
        fi
    fi

    echo "$device_found"
}

# Check if external drive is mounted and accessible
is_external_drive_mounted() {
    if timeout "$MOUNT_TIMEOUT" mountpoint -q "$EXTERNAL_MOUNT" 2>/dev/null && [[ -w "$EXTERNAL_MOUNT" ]]; then
        return 0
    else
        return 1
    fi
}

# Verify external drive is BTRFS filesystem
verify_external_is_btrfs() {
    if ! is_external_drive_mounted; then
        return 1
    fi

    if ! btrfs filesystem show "$EXTERNAL_MOUNT" >/dev/null 2>&1; then
        log "ERROR: External drive is not a BTRFS filesystem"
        log "External backup requires BTRFS filesystem for btrfs send/receive"
        return 1
    fi

    return 0
}

# Ensure the external drive is mounted with compression. btrfs send does NOT
# carry the source's compression, so a received stream lands uncompressed unless
# the receiving filesystem compresses on write. Remounting with compress-force
# affects NEW writes only; existing backups shrink only when rewritten (e.g. by
# --force-new-parent). Best made permanent via /etc/udisks2/mount_options.conf.
ensure_external_compression() {
    [[ "$ENABLE_EXTERNAL_COMPRESSION" == "true" ]] || return 0
    is_external_drive_mounted || return 0

    local opts
    opts=$(findmnt -no OPTIONS "$EXTERNAL_MOUNT" 2>/dev/null || echo "")

    if echo "$opts" | grep -q "compress"; then
        log "External drive already mounted with compression ($(echo "$opts" | grep -o 'compress[^,]*' | head -1))"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD REMOUNT: $EXTERNAL_MOUNT with compress-force=$EXTERNAL_COMPRESSION"
        return 0
    fi

    log "Remounting external drive with compress-force=$EXTERNAL_COMPRESSION (new writes will be compressed)"
    if mount -o "remount,compress-force=$EXTERNAL_COMPRESSION" "$EXTERNAL_MOUNT" 2>>"$LOG_FILE"; then
        log "External drive remounted with compression"
    else
        log "WARNING: Could not remount external with compression - continuing without it"
        log "TIP: install the provided /etc/udisks2/mount_options.conf so compression is applied at mount time"
    fi
    return 0
}

# Remove stray subvolumes left in the external backup dirs by an interrupted
# btrfs receive. A completed receive is immediately renamed to parent_*/
# incremental_*; anything still named backup_* (the original snapshot name) is a
# partial/failed receive that only wastes space.
cleanup_orphaned_receives() {
    is_external_drive_mounted || return 0
    [[ -d "$EXTERNAL_BACKUP_DIR" ]] || return 0

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local backup_dir="$EXTERNAL_BACKUP_DIR/$name"
        [[ -d "$backup_dir" ]] || continue

        while IFS= read -r orphan; do
            [[ -n "$orphan" ]] || continue
            log "Found orphaned partial receive: $(basename "$orphan")"
            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD DELETE orphaned receive: $orphan"
            else
                if btrfs subvolume delete "$orphan" >>"$LOG_FILE" 2>&1; then
                    log "Removed orphaned receive: $(basename "$orphan")"
                else
                    log "WARNING: could not remove orphaned receive: $(basename "$orphan")"
                fi
            fi
        done < <(find "$backup_dir" -maxdepth 1 -name "backup_*" -type d 2>/dev/null)
    done
}

# Epoch (seconds) of the newest external backup for a subvolume, or 0 if none.
# Uses the send timestamp (the last YYYYMMDD_HHMMSS component of the name).
get_newest_external_backup_epoch() {
    local subvol_name="$1"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"
    [[ -d "$backup_dir" ]] || { echo "0"; return; }

    local newest=0
    while IFS= read -r b; do
        [[ -n "$b" ]] || continue
        local ts_str
        ts_str=$(basename "$b" | grep -oP '\d{8}_\d{6}' | tail -1)
        [[ -n "$ts_str" ]] || continue
        local ep
        ep=$(parse_timestamp "backup_${ts_str}")
        [[ $ep -gt $newest ]] && newest=$ep
    done < <(find "$backup_dir" -maxdepth 1 \( -name "parent_*" -o -name "incremental_*" \) -type d 2>/dev/null)
    echo "$newest"
}

# =============================================================================
# SNAPSHOT MANAGEMENT
# =============================================================================

# Get the most recent snapshot for incremental backups
get_latest_snapshot() {
    local subvol_name="$1"
    find "$SNAPSHOT_DIR/$subvol_name" -maxdepth 1 -name "backup_*" -type d 2>/dev/null | sort | tail -1
}

# Get the most recent parent backup for incremental external backups
get_latest_parent_backup() {
    local subvol_name="$1"
    find "$EXTERNAL_BACKUP_DIR/$subvol_name" -maxdepth 1 -name "parent_*" -type d 2>/dev/null | sort | tail -1
}

# Check if we need a new parent backup (single-parent policy)
# Returns "true" only if: (1) no parent exists, OR (2) --force-new-parent flag set
need_new_parent_backup() {
    local subvol_name="$1"

    # If force flag is set, always create new parent
    if [[ "$FORCE_NEW_PARENT" == "true" ]]; then
        log "Force new parent requested via --force-new-parent flag"
        echo "true"
        return
    fi

    # Check if parent exists
    local latest_parent=$(get_latest_parent_backup "$subvol_name")

    if [[ -z "$latest_parent" ]]; then
        log "No parent backup exists for $subvol_name - will create first parent"
        echo "true"
        return
    fi

    # Verify parent is valid
    if ! btrfs subvolume show "$latest_parent" >/dev/null 2>&1; then
        log "WARNING: Parent backup exists but is invalid/corrupted - will recreate"
        send_notification "WARNING" "Parent backup for $subvol_name is corrupted - recreating"
        echo "true"
        return
    fi

    # Parent exists and is valid - always use incrementals
    log "Valid parent backup exists for $subvol_name - will create incremental"
    echo "false"
}

# Create regular backup snapshot
create_backup_snapshot() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_snapshots=()

    # Check local disk space before creating snapshots
    check_and_warn_disk_space "$BTRFS_POOL" "BTRFS pool" "true"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local path="${subvol_entry##*:}"
        local snapshot_name="backup_${timestamp}"
        local snapshot_path="$SNAPSHOT_DIR/$name/$snapshot_name"
        local snapshot_subdir="$SNAPSHOT_DIR/$name"

        # Ensure the subdirectory exists before creating snapshot
        if [[ ! -d "$snapshot_subdir" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD CREATE: snapshot subdirectory $snapshot_subdir"
            else
                log "Creating missing snapshot subdirectory: $snapshot_subdir"
                if mkdir -p "$snapshot_subdir"; then
                    log "Successfully created snapshot subdirectory: $snapshot_subdir"
                else
                    error_continue "Failed to create snapshot subdirectory: $snapshot_subdir"
                    failed_snapshots+=("$name")
                    continue
                fi
            fi
        fi

        # Find the most recent snapshot for reference
        local parent_snapshot=$(get_latest_snapshot "$name")

        log "Creating backup snapshot for $name: $snapshot_name"
        if [[ -n "$parent_snapshot" ]]; then
            log "Using parent snapshot: $(basename "$parent_snapshot")"
        else
            log "Creating first snapshot for $name (no parent found)"
        fi

        if ! execute_command "Create backup snapshot $snapshot_name for $name subvolume" \
                            btrfs subvolume snapshot -r "$path" "$snapshot_path" "true"; then
            failed_snapshots+=("$name")
        else
            # Verify the snapshot was created successfully
            if verify_backup "$snapshot_path" "$name backup snapshot"; then
                log "Backup snapshot verification successful for $name"
            else
                log "WARNING: Backup snapshot verification failed for $name"
            fi
        fi
    done

    # Report any failures
    if [[ ${#failed_snapshots[@]} -gt 0 ]]; then
        log "WARNING: Failed to create backup snapshots for: ${failed_snapshots[*]}"
        OPERATION_FAILED=true
    else
        log "All backup snapshots created successfully"
    fi
}

# =============================================================================
# CLEANUP OPERATIONS
# =============================================================================

# Cleanup old regular snapshots (with parent reference protection)
cleanup_regular_snapshots() {
    local retention_days="$LOCAL_SNAPSHOT_KEEP_DAYS"

    log "Cleaning up local snapshots older than $retention_days days (with parent reference protection)"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_dir="$SNAPSHOT_DIR/$name"

        if [[ ! -d "$subvol_dir" ]]; then
            continue
        fi

        log "Checking for old backup snapshots in $subvol_dir"

        local snapshots_to_delete=()
        local protected_snapshots=()
        local current_time=$(date +%s)
        local retention_seconds=$((retention_days * 86400))

        # Find all backup snapshots and check their age
        while IFS= read -r snapshot; do
            if [[ -n "$snapshot" ]]; then
                local snapshot_name=$(basename "$snapshot")
                local snapshot_timestamp=$(parse_timestamp "$snapshot_name")

                if [[ $snapshot_timestamp -gt 0 ]]; then
                    local age_seconds=$((current_time - snapshot_timestamp))
                    local age_days=$((age_seconds / 86400))

                    log "Snapshot $snapshot_name: created $(date -d "@$snapshot_timestamp" '+%Y-%m-%d %H:%M:%S'), age: $age_days days"

                    if [[ $age_seconds -gt $retention_seconds ]]; then
                        # Protect snapshots still needed as a 'btrfs send -p'
                        # reference: the parent's snapshot in parent mode, or any
                        # link of the send chain in chain mode.
                        local is_referenced=false
                        if [[ "$INCREMENTAL_MODE" == "chain" ]]; then
                            is_snapshot_referenced_by_any_external "$name" "$snapshot_name" && is_referenced=true
                        else
                            is_snapshot_referenced_by_external_parent "$name" "$snapshot_name" && is_referenced=true
                        fi

                        if [[ "$is_referenced" == "true" ]]; then
                            protected_snapshots+=("$snapshot")
                            log "PROTECTED: $snapshot_name backs an external backup - keeping despite age"
                        else
                            snapshots_to_delete+=("$snapshot")
                            log "Will delete: $snapshot_name (older than $retention_days days)"
                        fi
                    else
                        log "Will keep: $snapshot_name (within retention period)"
                    fi
                else
                    log "Could not parse timestamp from $snapshot_name, skipping"
                fi
            fi
        done < <(find "$subvol_dir" -maxdepth 1 -name "backup_*" -type d 2>/dev/null || true)

        if [[ ${#protected_snapshots[@]} -gt 0 ]]; then
            log "Protected ${#protected_snapshots[@]} snapshot(s) referenced by external parent"
        fi

        if [[ ${#snapshots_to_delete[@]} -eq 0 ]]; then
            log "No old backup snapshots to clean up for $name"
        else
            log "Deleting ${#snapshots_to_delete[@]} old snapshot(s) for $name"
            for snapshot in "${snapshots_to_delete[@]}"; do
                execute_command "Remove old backup snapshot $(basename "$snapshot") for $name" \
                               btrfs subvolume delete "$snapshot" "true"
            done
        fi
    done
}

# =============================================================================
# EXTERNAL BACKUP OPERATIONS
# =============================================================================
#
# PARENT BACKUP PROTECTION LOGIC:
# --------------------------------
# Parent backups are protected from deletion if they have dependent incrementals,
# even if they are older than REGULAR_KEEP_DAYS. This ensures backup chains remain
# valid and restorable. Parent backups are only deleted when:
#
# 1. Creating a new parent backup (force_cleanup=true) - deletes oldest parent
# 2. Parent has no dependent incrementals AND is older than REGULAR_KEEP_DAYS
# 3. Disk space is above warning threshold AND parent has no incrementals
#
# This space-aware cleanup ensures:
# - Valid backup chains are never broken
# - Disk space is managed proactively
# - Parent backups are retained as long as they're useful
# =============================================================================

# Setup external backup directory
setup_external_backup_dir() {
    if [[ ! -d "$EXTERNAL_BACKUP_DIR" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD CREATE: external backup directory $EXTERNAL_BACKUP_DIR"
        else
            mkdir -p "$EXTERNAL_BACKUP_DIR"
            log "Created external backup directory: $EXTERNAL_BACKUP_DIR"
        fi
    else
        log "External backup directory exists: $EXTERNAL_BACKUP_DIR"
    fi

    # Create subdirectories for each subvolume
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subdir="$EXTERNAL_BACKUP_DIR/$name"

        if [[ ! -d "$subdir" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD CREATE: external backup subdirectory $subdir"
            else
                mkdir -p "$subdir"
                log "Created external backup subdirectory: $subdir"
            fi
        fi
    done
}

# Get all incrementals for a specific parent backup
get_incrementals_for_parent() {
    local subvol_name="$1"
    local parent_timestamp_str="$2"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"

    find "$backup_dir" -maxdepth 1 -name "incremental_${parent_timestamp_str}_*" -type d 2>/dev/null || true
}

# Check if a parent backup has any incrementals dependent on it
has_dependent_incrementals() {
    local subvol_name="$1"
    local parent_timestamp_str="$2"

    local incremental_count=$(get_incrementals_for_parent "$subvol_name" "$parent_timestamp_str" | wc -l)
    [[ $incremental_count -gt 0 ]]
}

# Delete old parent and incrementals - only when space is needed or parent is very old
cleanup_old_parent_chain() {
    local subvol_name="$1"
    local force_cleanup="${2:-false}"  # Force cleanup when creating new parent
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"

    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi

    # Check available disk space
    local disk_usage=$(check_disk_space "$EXTERNAL_MOUNT" "External drive" 2>/dev/null || echo "0")
    local needs_space=false

    if [[ $disk_usage -ge $DISK_SPACE_WARNING_THRESHOLD ]]; then
        needs_space=true
        log "Disk space at ${disk_usage}% - cleanup may be needed"
    fi

    log "Evaluating parent backup chains for $subvol_name (force=$force_cleanup, needs_space=$needs_space)"

    # Get all parent backups sorted by age (oldest first)
    local parents=()
    while IFS= read -r parent; do
        if [[ -n "$parent" ]]; then
            parents+=("$parent")
        fi
    done < <(find "$backup_dir" -maxdepth 1 -name "parent_*" -type d 2>/dev/null | sort || true)

    if [[ ${#parents[@]} -eq 0 ]]; then
        log "No parent backups found for cleanup"
        return 0
    fi

    log "Found ${#parents[@]} parent backup(s) for $subvol_name"

    # If we have only one parent, never delete it unless forced and it has no incrementals
    if [[ ${#parents[@]} -eq 1 ]] && [[ "$force_cleanup" == "false" ]]; then
        log "Only one parent backup exists - keeping it"
        return 0
    fi

    # Process each parent (oldest first)
    local current_time=$(date +%s)
    local deleted_count=0
    local remaining_parents=${#parents[@]}

    for parent in "${parents[@]}"; do
        local parent_name=$(basename "$parent")
        local parent_timestamp=$(parse_timestamp "$parent_name")

        if [[ $parent_timestamp -eq 0 ]]; then
            log "Invalid parent backup name format: $parent_name - skipping"
            continue
        fi

        local parent_timestamp_str=$(date -d "@$parent_timestamp" '+%Y%m%d_%H%M%S')
        local age_seconds=$((current_time - parent_timestamp))
        local age_days=$((age_seconds / 86400))

        log "Evaluating $parent_name: age=$age_days days"

        # Find all incrementals for this parent
        local incrementals=()
        while IFS= read -r incremental; do
            if [[ -n "$incremental" ]]; then
                incrementals+=("$incremental")
            fi
        done < <(get_incrementals_for_parent "$subvol_name" "$parent_timestamp_str")

        local has_incrementals=$([[ ${#incrementals[@]} -gt 0 ]] && echo "true" || echo "false")

        if [[ "$has_incrementals" == "true" ]]; then
            log "  Parent has ${#incrementals[@]} dependent incremental(s)"
        else
            log "  Parent has no dependent incrementals"
        fi

        # Determine if we should delete this parent
        local should_delete=false
        local reason=""

        # Safety check: never delete the last parent backup
        if [[ $remaining_parents -le 1 ]]; then
            log "SAFETY: Cannot delete last remaining parent backup"
            should_delete=false
        elif [[ "$force_cleanup" == "true" ]] && [[ ${#parents[@]} -gt 1 ]]; then
            # When creating new parent and we have multiple parents, delete oldest
            should_delete=true
            reason="making space for new parent backup"
        elif [[ "$has_incrementals" == "false" ]] && [[ $age_days -gt $REGULAR_KEEP_DAYS ]]; then
            # Parent has no incrementals and is older than retention period
            should_delete=true
            reason="no incrementals and older than $REGULAR_KEEP_DAYS days"
        elif [[ "$needs_space" == "true" ]] && [[ "$has_incrementals" == "false" ]]; then
            # Need space and this parent has no incrementals
            should_delete=true
            reason="reclaiming disk space (${disk_usage}% used)"
        fi

        if [[ "$should_delete" == "true" ]]; then
            log "DECISION: Delete $parent_name - $reason"

            # Delete incrementals first (should be none, but be safe)
            local incremental_delete_failed=false
            for incremental in "${incrementals[@]}"; do
                if ! execute_command "Remove incremental backup $(basename "$incremental") for $subvol_name" \
                                    btrfs subvolume delete "$incremental" "true"; then
                    incremental_delete_failed=true
                fi
            done

            # Delete parent if all incrementals deleted successfully
            if [[ "$incremental_delete_failed" == "false" ]]; then
                if execute_command "Remove parent backup $parent_name for $subvol_name" \
                               btrfs subvolume delete "$parent" "true"; then
                    log "Successfully deleted parent chain: $parent_name with ${#incrementals[@]} incremental(s)"
                    deleted_count=$((deleted_count + 1))
                    remaining_parents=$((remaining_parents - 1))
                else
                    log "WARNING: Failed to delete parent backup $parent_name"
                fi
            else
                log "WARNING: Some incrementals failed to delete, keeping parent backup $parent_name"
            fi
        else
            log "DECISION: Keep $parent_name - protected (age=$age_days days, incrementals=${has_incrementals})"
        fi

        # If we're forcing cleanup and deleted at least one, we're done
        if [[ "$force_cleanup" == "true" ]] && [[ $deleted_count -gt 0 ]]; then
            break
        fi
    done

    if [[ $deleted_count -eq 0 ]]; then
        log "No parent backups deleted for $subvol_name"
    else
        log "Deleted $deleted_count parent backup chain(s) for $subvol_name"
    fi
}

# Send backup with optional bandwidth limiting (no eval - safer)
send_backup() {
    local source="$1"
    local dest_dir="$2"
    local parent="${3:-}"  # Optional parent for incremental

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ -n "$parent" ]]; then
            log "WOULD EXECUTE: btrfs send -p '$parent' '$source' | btrfs receive '$dest_dir'"
        else
            log "WOULD EXECUTE: btrfs send '$source' | btrfs receive '$dest_dir'"
        fi
        return 0
    fi

    log "Sending backup from $source to $dest_dir"
    if [[ -n "$parent" ]]; then
        log "Using parent: $parent"
    fi

    # Execute without eval for security
    if [[ "$ENABLE_BANDWIDTH_LIMIT" == "true" ]] && command -v pv >/dev/null 2>&1; then
        log "Using bandwidth limit: ${BANDWIDTH_LIMIT_MB}MB/s"
        if [[ -n "$parent" ]]; then
            btrfs send -p "$parent" "$source" | pv -L "${BANDWIDTH_LIMIT_MB}m" | btrfs receive "$dest_dir"
        else
            btrfs send "$source" | pv -L "${BANDWIDTH_LIMIT_MB}m" | btrfs receive "$dest_dir"
        fi
    else
        if [[ -n "$parent" ]]; then
            btrfs send -p "$parent" "$source" | btrfs receive "$dest_dir"
        else
            btrfs send "$source" | btrfs receive "$dest_dir"
        fi
    fi
}

# Create a full parent backup for a subvolume (deletes existing backups first).
# Returns 0 on success, 1 on failure.
create_parent_backup() {
    local name="$1"
    local latest_snapshot="$2"
    local timestamp="$3"

    log "=== CREATING NEW PARENT BACKUP for $name ==="

    # Pre-flight space check, crediting the space that deleting existing backups
    # will free (single-parent policy deletes before it re-sends).
    local reclaimable_gb
    reclaimable_gb=$(get_existing_backup_size_gb "$name")
    preflight_space_check "parent" "$EXTERNAL_MOUNT" "$reclaimable_gb"

    # Single-parent policy deletes the ONLY backup before re-sending a full copy.
    # If the send is interrupted, this subvolume is left with no valid backup.
    local existing
    existing=$(find "$EXTERNAL_BACKUP_DIR/$name" -maxdepth 1 \( -name "parent_*" -o -name "incremental_*" \) -type d 2>/dev/null | wc -l)
    if [[ $existing -gt 0 ]]; then
        log "WARNING: About to delete the existing backup for $name, then send a fresh parent."
        log "WARNING: If this is interrupted, $name will have NO valid backup until it finishes."
        send_notification "WARNING" "Refreshing parent for $name: old backup removed before re-send (interruption = no backup for $name)"
    fi

    delete_all_backups_for_subvolume "$name"

    local parent_name="parent_${timestamp}"
    local parent_path="$EXTERNAL_BACKUP_DIR/$name/$parent_name"

    log "Creating full parent backup: $parent_name"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD EXECUTE: btrfs send '$latest_snapshot' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
        log "WOULD RENAME: received snapshot to $parent_name"
        return 0
    fi

    log "Sending parent backup (this may take a while)..."
    if send_backup "$latest_snapshot" "$EXTERNAL_BACKUP_DIR/$name"; then
        local received_path="$EXTERNAL_BACKUP_DIR/$name/$(basename "$latest_snapshot")"
        if [[ -d "$received_path" ]] && mv "$received_path" "$parent_path"; then
            log "Successfully created parent backup: $parent_path"
            if verify_backup "$parent_path" "$name parent backup"; then
                send_notification "INFO" "Parent backup created for $name: $parent_name"
                return 0
            fi
            send_notification "ERROR" "Parent backup verification failed for $name"
            return 1
        fi
        error_continue "Failed to rename parent backup for $name"
        send_notification "ERROR" "Failed to rename parent backup for $name"
        return 1
    fi
    error_continue "Failed to send parent backup for $name"
    send_notification "ERROR" "Failed to create parent backup for $name"
    return 1
}

# Create an incremental backup for a subvolume.
# Returns: 0 success, 1 failure, 2 "cannot do incremental - needs a parent"
create_incremental_backup() {
    local name="$1"
    local latest_snapshot="$2"
    local timestamp="$3"

    log "=== CREATING INCREMENTAL BACKUP for $name (mode: $INCREMENTAL_MODE) ==="

    check_chain_length "$name" || true
    preflight_space_check "incremental" "$EXTERNAL_MOUNT"

    local current_parent
    current_parent=$(get_latest_parent_backup "$name")
    if [[ -z "$current_parent" ]]; then
        log "ERROR: No parent backup found - cannot create incremental"
        return 2
    fi

    local parent_timestamp
    parent_timestamp=$(parse_timestamp "$(basename "$current_parent")")
    if [[ $parent_timestamp -eq 0 ]]; then
        log "ERROR: Could not parse parent timestamp from $(basename "$current_parent")"
        return 1
    fi
    local parent_timestamp_str
    parent_timestamp_str=$(date -d "@$parent_timestamp" '+%Y%m%d_%H%M%S')

    # Which local snapshot do we diff against (the 'btrfs send -p' reference)?
    #   parent mode: the snapshot that backs the parent (cumulative diffs)
    #   chain mode : the snapshot that backs the NEWEST external backup (deltas)
    local ref_timestamp_str="$parent_timestamp_str"
    if [[ "$INCREMENTAL_MODE" == "chain" ]]; then
        local newest_epoch
        newest_epoch=$(get_newest_external_backup_epoch "$name")
        if [[ $newest_epoch -gt 0 ]]; then
            ref_timestamp_str=$(date -d "@$newest_epoch" '+%Y%m%d_%H%M%S')
        fi
    fi

    local local_ref="$SNAPSHOT_DIR/$name/backup_${ref_timestamp_str}"
    if [[ ! -d "$local_ref" ]] || ! btrfs subvolume show "$local_ref" >/dev/null 2>&1; then
        log "ERROR: Local reference snapshot not found or invalid: $local_ref"
        log "ERROR: Cannot create incremental without a local reference for 'btrfs send -p'"
        return 2
    fi

    # Nothing newer to send (e.g. snapshot creation failed this run)
    if [[ "$(basename "$local_ref")" == "$(basename "$latest_snapshot")" ]]; then
        log "Latest snapshot equals the reference snapshot - no new data to back up for $name"
        return 0
    fi

    log "Incremental reference (send -p): $(basename "$local_ref")"
    local incremental_name="incremental_${parent_timestamp_str}_${timestamp}"
    local incremental_path="$EXTERNAL_BACKUP_DIR/$name/$incremental_name"

    log "Creating incremental backup: $incremental_name"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD EXECUTE: btrfs send -p '$local_ref' '$latest_snapshot' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
        log "WOULD RENAME: received snapshot to $incremental_name"
        return 0
    fi

    log "Sending incremental backup..."
    if send_backup "$latest_snapshot" "$EXTERNAL_BACKUP_DIR/$name" "$local_ref"; then
        local received_path="$EXTERNAL_BACKUP_DIR/$name/$(basename "$latest_snapshot")"
        if [[ -d "$received_path" ]] && mv "$received_path" "$incremental_path"; then
            log "Successfully created incremental backup: $incremental_path"
            if verify_backup "$incremental_path" "$name incremental backup"; then
                log "Incremental backup verified successfully"
            else
                log "WARNING: Incremental backup verification failed"
            fi
            return 0
        fi
        error_continue "Failed to rename incremental backup for $name"
        return 1
    fi
    error_continue "Failed to send incremental backup for $name"
    return 1
}

# Create external backup (parent or incremental) - Single-parent policy
create_external_backup() {
    if ! is_external_drive_mounted; then
        log "External drive not mounted - skipping external backups"
        log "Local snapshots created successfully. Connect external drive and run again for external backups."
        return 0
    fi

    # Verify external drive is BTRFS before proceeding
    if ! verify_external_is_btrfs; then
        log "External backup skipped - drive is not BTRFS"
        return 1
    fi

    # Compress new writes, and clear any partial receives from a prior failure
    ensure_external_compression
    cleanup_orphaned_receives

    setup_external_backup_dir

    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_backups=()

    # Check external drive disk space (general check)
    check_and_warn_disk_space "$EXTERNAL_MOUNT" "External drive" "false"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"

        log "================================================"
        log "Processing external backup for $name subvolume"
        log "================================================"

        # Enforce single-parent policy check
        enforce_single_parent_policy "$name" || true

        # Find the most recent snapshot for this subvolume
        local latest_snapshot
        latest_snapshot=$(get_latest_snapshot "$name")

        if [[ -z "$latest_snapshot" ]]; then
            log "ERROR: No local snapshot found for $name - cannot create backup"
            send_notification "ERROR" "No local snapshot for $name - backup skipped"
            failed_backups+=("$name")
            continue
        fi

        log "Latest local snapshot: $(basename "$latest_snapshot")"

        if [[ "$(need_new_parent_backup "$name")" == "true" ]]; then
            create_parent_backup "$name" "$latest_snapshot" "$timestamp" || failed_backups+=("$name")
        else
            local rc=0
            create_incremental_backup "$name" "$latest_snapshot" "$timestamp" || rc=$?
            if [[ $rc -eq 2 ]]; then
                # Incremental impossible (missing parent or local reference snapshot)
                if [[ "$RECOVERY_MODE" == "true" || "$FORCE_NEW_PARENT" == "true" ]]; then
                    log "RECOVERY: incremental not possible for $name - creating a fresh parent backup"
                    send_notification "WARNING" "Recovery for $name - recreating parent backup"
                    create_parent_backup "$name" "$latest_snapshot" "$timestamp" || failed_backups+=("$name")
                else
                    log "ERROR: Cannot create incremental for $name (missing parent or local reference)"
                    log "SOLUTION: re-run with --recovery (auto-recreate parent) or --force-new-parent"
                    send_notification "ERROR" "Incremental impossible for $name - run with --recovery or --force-new-parent"
                    failed_backups+=("$name")
                fi
            elif [[ $rc -ne 0 ]]; then
                failed_backups+=("$name")
            fi
        fi

        log "Completed processing for $name subvolume"
        log ""
    done

    # Report final status
    if [[ ${#failed_backups[@]} -gt 0 ]]; then
        log "WARNING: Failed to create external backups for: ${failed_backups[*]}"
        send_notification "ERROR" "Backup failed for: ${failed_backups[*]}"
        OPERATION_FAILED=true
    else
        log "=== ALL EXTERNAL BACKUPS COMPLETED SUCCESSFULLY ==="
        send_notification "INFO" "All external backups completed successfully"
    fi
}

# Cleanup old external backups (incrementals only - parent is never auto-deleted)
cleanup_external_backups() {
    if ! is_external_drive_mounted; then
        log "External drive not mounted - skipping external cleanup"
        return 0
    fi

    # In chain mode every incremental is a link the newer ones depend on, so
    # age-based deletion would break the chain. Reclaim space with a new parent
    # (--force-new-parent) instead.
    if [[ "$INCREMENTAL_MODE" == "chain" ]]; then
        log "Incremental chain mode: skipping age-based incremental cleanup (would break the chain)"
        log "To reclaim space in chain mode, refresh the parent with --force-new-parent"
        return 0
    fi

    local retention_days="$INCREMENTAL_KEEP_DAYS"

    log "Cleaning up external incremental backups older than $retention_days days"
    log "NOTE: Parent backups are NEVER auto-deleted (single-parent policy)"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_backup_dir="$EXTERNAL_BACKUP_DIR/$name"

        if [[ ! -d "$subvol_backup_dir" ]]; then
            continue
        fi

        log "Checking for old incremental backups in $subvol_backup_dir"

        # Verify single-parent policy
        enforce_single_parent_policy "$name" || true

        local backups_to_delete=()
        local current_time=$(date +%s)
        local retention_seconds=$((retention_days * 86400))

        # Find all incremental backups and check their age
        while IFS= read -r backup; do
            if [[ -n "$backup" ]]; then
                local backup_name=$(basename "$backup")

                # Extract timestamp from incremental backup name
                if [[ $backup_name =~ incremental_[0-9]{8}_[0-9]{6}_([0-9]{8})_([0-9]{6}) ]]; then
                    local date_part="${BASH_REMATCH[1]}"
                    local time_part="${BASH_REMATCH[2]}"
                    local backup_timestamp=$(parse_timestamp "backup_${date_part}_${time_part}")

                    if [[ $backup_timestamp -gt 0 ]]; then
                        local age_seconds=$((current_time - backup_timestamp))
                        local age_days=$((age_seconds / 86400))

                        log "Incremental backup $backup_name: age=$age_days days"

                        if [[ $age_seconds -gt $retention_seconds ]]; then
                            backups_to_delete+=("$backup")
                            log "Will delete: $backup_name (older than $retention_days days)"
                        else
                            log "Will keep: $backup_name (within retention period)"
                        fi
                    else
                        log "Could not parse timestamp from $backup_name, skipping"
                    fi
                else
                    log "Backup name $backup_name doesn't match expected format, skipping"
                fi
            fi
        done < <(find "$subvol_backup_dir" -maxdepth 1 -name "incremental_*" -type d 2>/dev/null || true)

        if [[ ${#backups_to_delete[@]} -eq 0 ]]; then
            log "No old incremental backups to clean up for $name"
        else
            log "Deleting ${#backups_to_delete[@]} old incremental backup(s) for $name"
            for backup in "${backups_to_delete[@]}"; do
                execute_command "Remove old incremental backup $(basename "$backup") for $name" \
                               btrfs subvolume delete "$backup" "true"
            done
        fi
    done

    log "External backup cleanup completed (parent backups protected)"
}

# Keep old function name for backward compatibility
cleanup_external_incrementals() {
    cleanup_external_backups
}

# =============================================================================
# LISTING AND STATUS OPERATIONS
# =============================================================================

# List local snapshots and external backups
list_backups() {
    local list_type="${1:-all}"  # all, local, external

    echo "=== BTRFS Backup Listing ==="
    echo

    if [[ "$list_type" == "all" || "$list_type" == "local" ]]; then
        echo "Local Snapshots:"
        echo "=================="

        for subvol_entry in "${SUBVOLUMES[@]}"; do
            local name="${subvol_entry%%:*}"
            local subvol_dir="$SNAPSHOT_DIR/$name"

            echo "  $name subvolume:"
            if [[ -d "$subvol_dir" ]]; then
                local snapshots=($(find "$subvol_dir" -maxdepth 1 -name "backup_*" -type d 2>/dev/null | sort))

                if [[ ${#snapshots[@]} -eq 0 ]]; then
                    echo "    No backup snapshots found"
                else
                    for snapshot in "${snapshots[@]}"; do
                        local snapshot_name=$(basename "$snapshot")
                        local size=$(du -sh "$snapshot" 2>/dev/null | cut -f1 || echo "Unknown")
                        local timestamp=$(parse_timestamp "$snapshot_name")
                        local timestamp_str=""

                        if [[ $timestamp -gt 0 ]]; then
                            timestamp_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
                        fi

                        echo "    $snapshot_name [$size] ($timestamp_str)"
                    done
                fi
            else
                echo "    Snapshot directory does not exist"
            fi
            echo
        done
    fi

    if [[ "$list_type" == "all" || "$list_type" == "external" ]]; then
        echo "External Backups:"
        echo "=================="

        if ! is_external_drive_mounted; then
            echo "  External drive not mounted"
            echo
            return 0
        fi

        for subvol_entry in "${SUBVOLUMES[@]}"; do
            local name="${subvol_entry%%:*}"
            local backup_dir="$EXTERNAL_BACKUP_DIR/$name"

            echo "  $name backups:"
            if [[ -d "$backup_dir" ]]; then
                # List parent backups
                local parents=($(find "$backup_dir" -maxdepth 1 -name "parent_*" -type d 2>/dev/null | sort))
                local incrementals=($(find "$backup_dir" -maxdepth 1 -name "incremental_*" -type d 2>/dev/null | sort))

                echo "    Parent backups:"
                if [[ ${#parents[@]} -eq 0 ]]; then
                    echo "      None"
                else
                    for parent in "${parents[@]}"; do
                        local parent_name=$(basename "$parent")
                        local size=$(du -sh "$parent" 2>/dev/null | cut -f1 || echo "Unknown")
                        local timestamp=$(parse_timestamp "$parent_name")
                        local timestamp_str=""

                        if [[ $timestamp -gt 0 ]]; then
                            timestamp_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
                        fi

                        echo "      $parent_name [$size] ($timestamp_str)"
                    done
                fi

                echo "    Incremental backups:"
                if [[ ${#incrementals[@]} -eq 0 ]]; then
                    echo "      None"
                else
                    for incremental in "${incrementals[@]}"; do
                        local incremental_name=$(basename "$incremental")
                        local size=$(du -sh "$incremental" 2>/dev/null | cut -f1 || echo "Unknown")

                        # Extract timestamp from incremental backup name
                        local timestamp_str=""
                        if [[ $incremental_name =~ incremental_[0-9]{8}_[0-9]{6}_([0-9]{8})_([0-9]{6}) ]]; then
                            local date_part="${BASH_REMATCH[1]}"
                            local time_part="${BASH_REMATCH[2]}"
                            local timestamp=$(parse_timestamp "backup_${date_part}_${time_part}")
                            if [[ $timestamp -gt 0 ]]; then
                                timestamp_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
                            fi
                        fi

                        echo "      $incremental_name [$size] ($timestamp_str)"
                    done
                fi
            else
                echo "    No backup directory found"
            fi
            echo
        done
    fi
}

# Delete specific snapshots or backups
delete_backup() {
    local backup_type="$1"  # local or external
    local subvolume="$2"    # root or home
    local backup_name="$3"  # the snapshot/backup name

    if [[ -z "$backup_type" || -z "$subvolume" || -z "$backup_name" ]]; then
        echo "Usage: delete_backup <local|external> <root|home> <backup_name>"
        echo ""
        echo "Examples:"
        echo "  delete_backup local root backup_20241230_143022"
        echo "  delete_backup external home parent_20241230_143022"
        echo "  delete_backup external root incremental_20241230_143022_20241231_120000"
        return 1
    fi

    local backup_path=""
    local description=""

    if [[ "$backup_type" == "local" ]]; then
        backup_path="$SNAPSHOT_DIR/$subvolume/$backup_name"
        description="local snapshot $backup_name for $subvolume"

        if [[ ! -d "$backup_path" ]]; then
            echo "ERROR: Local snapshot not found: $backup_path"
            return 1
        fi

    elif [[ "$backup_type" == "external" ]]; then
        if ! is_external_drive_mounted; then
            echo "ERROR: External drive not mounted"
            return 1
        fi

        backup_path="$EXTERNAL_BACKUP_DIR/$subvolume/$backup_name"
        description="external backup $backup_name for $subvolume"

        if [[ ! -d "$backup_path" ]]; then
            echo "ERROR: External backup not found: $backup_path"
            return 1
        fi

    else
        echo "ERROR: Invalid backup type. Use 'local' or 'external'"
        return 1
    fi

    # Validate subvolume name
    local valid_subvol=false
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        if [[ "$name" == "$subvolume" ]]; then
            valid_subvol=true
            break
        fi
    done

    if [[ "$valid_subvol" == false ]]; then
        echo "ERROR: Invalid subvolume name: $subvolume"
        echo "Valid subvolumes: $(printf '%s ' "${SUBVOLUMES[@]}" | sed 's/:[^[:space:]]*//g')"
        return 1
    fi

    # Verify it's a valid subvolume before deletion
    if ! btrfs subvolume show "$backup_path" >/dev/null 2>&1; then
        echo "ERROR: $backup_path is not a valid BTRFS subvolume"
        return 1
    fi

    # Protect local snapshots that back an external backup: deleting them breaks
    # future incremental sends (the 'btrfs send -p' reference disappears).
    local extra_confirm=false
    if [[ "$backup_type" == "local" ]]; then
        local referenced=false
        if [[ "$INCREMENTAL_MODE" == "chain" ]]; then
            is_snapshot_referenced_by_any_external "$subvolume" "$backup_name" && referenced=true
        else
            is_snapshot_referenced_by_external_parent "$subvolume" "$backup_name" && referenced=true
        fi
        if [[ "$referenced" == "true" ]]; then
            echo ""
            echo "!!! WARNING: $backup_name is the local reference for an EXTERNAL backup."
            echo "!!! Deleting it will break incremental backups until you run --force-new-parent"
            echo "!!! (which re-sends a full parent). Only proceed if you understand this."
            extra_confirm=true
        fi
    fi

    # Confirmation prompt
    echo "WARNING: About to delete $description"
    echo "Path: $backup_path"
    echo ""
    echo "This action cannot be undone!"
    if [[ "$extra_confirm" == "true" ]]; then
        echo "Type 'DELETE REFERENCE' (exactly) to confirm this protected deletion, or anything else to cancel:"
        read -r confirmation
        if [[ "$confirmation" != "DELETE REFERENCE" ]]; then
            echo "Deletion cancelled"
            return 1
        fi
        confirmation="yes"
    else
        echo "Type 'yes' to confirm deletion, or anything else to cancel:"
        read -r confirmation
    fi

    if [[ "$confirmation" == "yes" ]]; then
        if execute_command "Delete $description" btrfs subvolume delete "$backup_path" "false"; then
            echo "Successfully deleted $description"
        else
            echo "Failed to delete $description"
            return 1
        fi
    else
        echo "Deletion cancelled"
        return 1
    fi
}

# Report freshness of external backups (staleness) and parent age.
# Prints one line per subvolume; returns 1 if anything is stale.
report_backup_freshness() {
    local stale=0
    if ! is_external_drive_mounted; then
        echo "  External drive not mounted - cannot check backup freshness"
        return 1
    fi

    local now
    now=$(date +%s)
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local newest
        newest=$(get_newest_external_backup_epoch "$name")
        if [[ $newest -eq 0 ]]; then
            echo "  ✗ $name: NO external backup found"
            stale=1
            continue
        fi
        local age_days=$(( (now - newest) / 86400 ))
        local marker="✓"
        local note=""
        if [[ $age_days -ge $STALE_BACKUP_WARN_DAYS ]]; then
            marker="⚠"; note=" (STALE - older than ${STALE_BACKUP_WARN_DAYS} days)"; stale=1
        fi

        # Parent age (suggest a refresh past PARENT_REFRESH_SUGGEST_DAYS)
        local parent
        parent=$(get_latest_parent_backup "$name")
        local parent_note=""
        if [[ -n "$parent" ]]; then
            local pts
            pts=$(parse_timestamp "$(basename "$parent")")
            if [[ $pts -gt 0 ]]; then
                local pdays=$(( (now - pts) / 86400 ))
                if [[ $pdays -ge $PARENT_REFRESH_SUGGEST_DAYS ]]; then
                    parent_note="; parent is ${pdays}d old - consider --force-new-parent"
                fi
            fi
        fi
        echo "  $marker $name: last backup ${age_days}d ago${note}${parent_note}"
    done

    return $stale
}

# Show health status
show_health() {
    echo "=== BTRFS Backup System Health ==="
    echo

    # Check filesystem status
    echo "Filesystem Health:"
    if btrfs device stats "$BTRFS_POOL" 2>/dev/null | grep -q "write_io_errs.*[1-9]"; then
        echo "  WARNING: BTRFS errors detected!"
        btrfs device stats "$BTRFS_POOL" 2>/dev/null
    else
        echo "  BTRFS pool healthy"
    fi
    echo

    # Check backup counts
    echo "Backup Counts:"
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local local_count=$(find "$SNAPSHOT_DIR/$name" -maxdepth 1 -name "backup_*" -type d 2>/dev/null | wc -l)
        echo "  $name: $local_count local snapshot(s)"
    done
    echo

    # Backup freshness / staleness
    echo "Backup Freshness:"
    report_backup_freshness || true
    echo

    # Check recent activity
    echo "Recent Activity:"
    if [[ -f "$LOG_FILE" ]]; then
        echo "  Last 5 log entries:"
        tail -5 "$LOG_FILE" | sed 's/^/    /'
    else
        echo "  No log file found"
    fi
    echo

    # Disk space
    echo "Disk Space:"
    local pool_usage=$(check_disk_space "$BTRFS_POOL" "BTRFS pool" 2>/dev/null || echo "unknown")
    echo "  BTRFS pool: ${pool_usage}% used"

    if is_external_drive_mounted; then
        local ext_usage=$(check_disk_space "$EXTERNAL_MOUNT" "External drive" 2>/dev/null || echo "unknown")
        echo "  External drive: ${ext_usage}% used"
        local ext_opts
        ext_opts=$(findmnt -no OPTIONS "$EXTERNAL_MOUNT" 2>/dev/null | grep -o 'compress[^,]*' | head -1 || echo "")
        echo "  External compression: ${ext_opts:-none (run a backup to enable, or install udisks config)}"
    else
        echo "  External drive: not mounted"
    fi
    echo

    # Last scrub result for the external drive (data-integrity / bit-rot check)
    echo "External Drive Integrity:"
    if is_external_drive_mounted; then
        local scrub_status
        scrub_status=$(btrfs scrub status "$EXTERNAL_MOUNT" 2>/dev/null | grep -iE "Status|error" | sed 's/^/  /' || echo "")
        if [[ -n "$scrub_status" ]]; then
            echo "$scrub_status"
        else
            echo "  No scrub history - run: $(basename "$0") scrub"
        fi
    else
        echo "  External drive not mounted"
    fi
}

# Show status of snapshots and backups
show_status() {
    echo "=== BTRFS Simplified Snapshot Status ==="
    echo "Version: v2.4 (Single-parent policy; robustness + space-efficiency additions)"
    echo
    echo "BTRFS Pool: $BTRFS_POOL"
    echo "Subvolumes configured:"
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local path="${subvol_entry##*:}"
        if [[ -d "$path" ]]; then
            echo "  ✓ $name: $path"
        else
            echo "  ✗ $name: $path (NOT FOUND)"
        fi
    done

    echo
    echo "External drive status:"
    if [[ "$(is_external_drive_available)" == "true" ]]; then
        echo "✓ External drive detected (UUID: $EXTERNAL_DEVICE_UUID)"
        if is_external_drive_mounted; then
            echo "✓ External drive mounted at $EXTERNAL_MOUNT"
            local ext_usage=$(check_disk_space "$EXTERNAL_MOUNT" "External drive" 2>/dev/null || echo "unknown")
            echo "  External drive usage: ${ext_usage}%"

            # Check if external is BTRFS
            if verify_external_is_btrfs; then
                echo "  External filesystem: BTRFS ✓"
            else
                echo "  External filesystem: NOT BTRFS ✗"
            fi

            echo "  Backup freshness:"
            report_backup_freshness | sed 's/^/  /' || true
        else
            echo "⚠ External drive detected but not mounted"
        fi
    else
        echo "✗ External drive not detected"
    fi

    echo
    echo "Local snapshots in $SNAPSHOT_DIR:"
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_dir="$SNAPSHOT_DIR/$name"

        echo "  $name subvolume:"
        if [[ -d "$subvol_dir" ]]; then
            local backup_count=$(find "$subvol_dir" -name "backup_*" -type d 2>/dev/null | wc -l)

            echo "    Backup snapshots: $backup_count"
            if [[ $backup_count -gt 0 ]]; then
                local latest_backup=$(find "$subvol_dir" -name "backup_*" -type d 2>/dev/null | sort | tail -1)
                local latest_name=$(basename "$latest_backup" 2>/dev/null || echo "none")
                local latest_ts=$(parse_timestamp "$latest_name")
                if [[ $latest_ts -gt 0 ]]; then
                    echo "      Latest: $latest_name ($(date -d "@$latest_ts" '+%Y-%m-%d %H:%M:%S'))"
                else
                    echo "      Latest: $latest_name"
                fi
            fi
        else
            echo "    Snapshot directory does not exist"
        fi
        echo
    done

    echo "External backups:"
    if is_external_drive_mounted && [[ -d "$EXTERNAL_BACKUP_DIR" ]]; then
        for subvol_entry in "${SUBVOLUMES[@]}"; do
            local name="${subvol_entry%%:*}"
            local backup_dir="$EXTERNAL_BACKUP_DIR/$name"

            echo "  $name backups:"
            if [[ -d "$backup_dir" ]]; then
                local parent_backup_count=$(find "$backup_dir" -name "parent_*" -type d 2>/dev/null | wc -l)
                local incremental_backup_count=$(find "$backup_dir" -name "incremental_*" -type d 2>/dev/null | wc -l)

                echo "    Parent backups: $parent_backup_count"
                if [[ $parent_backup_count -gt 0 ]]; then
                    local latest_parent_backup=$(find "$backup_dir" -name "parent_*" -type d 2>/dev/null | sort | tail -1)
                    local latest_name=$(basename "$latest_parent_backup" 2>/dev/null || echo "none")
                    local latest_ts=$(parse_timestamp "$latest_name")
                    if [[ $latest_ts -gt 0 ]]; then
                        echo "      Latest: $latest_name ($(date -d "@$latest_ts" '+%Y-%m-%d %H:%M:%S'))"
                    else
                        echo "      Latest: $latest_name"
                    fi
                fi

                echo "    Incremental backups: $incremental_backup_count"
                if [[ $incremental_backup_count -gt 0 ]]; then
                    local latest_incremental_backup=$(find "$backup_dir" -name "incremental_*" -type d 2>/dev/null | sort | tail -1)
                    echo "      Latest: $(basename "$latest_incremental_backup" 2>/dev/null || echo "none")"
                fi
            else
                echo "    No backup directory found"
            fi
            echo
        done
    else
        echo "External drive not accessible"
    fi

    echo "Disk usage:"
    local pool_usage=$(check_disk_space "$BTRFS_POOL" "BTRFS pool" 2>/dev/null || echo "unknown")
    echo "  BTRFS pool: ${pool_usage}%"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_dir="$SNAPSHOT_DIR/$name"
        if [[ -d "$subvol_dir" ]]; then
            echo "  $name snapshots: $(du -sh "$subvol_dir" 2>/dev/null | cut -f1 || echo "Unknown")"
        fi
    done

    echo
    echo "Configuration (Single-Parent Strategy):"
    echo "  Local snapshot retention: $LOCAL_SNAPSHOT_KEEP_DAYS days"
    echo "  Incremental backup retention: $INCREMENTAL_KEEP_DAYS days"
    echo "  Max incremental chain length: $MAX_INCREMENTAL_CHAIN_LENGTH (warning threshold)"
    echo "  Parent backup policy: SINGLE PARENT ONLY (never auto-deleted)"
    echo "  Disk space warning threshold: ${DISK_SPACE_WARNING_THRESHOLD}%"
    echo "  Disk space critical threshold: ${DISK_SPACE_CRITICAL_THRESHOLD}%"
    echo "  Required free space for parent: ${DISK_SPACE_REQUIRED_PERCENT}%"
    echo "  Backup verification: $([ "$BACKUP_VERIFICATION_ENABLED" == "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Notifications: $([ "$ENABLE_NOTIFICATIONS" == "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Mount timeout: ${MOUNT_TIMEOUT}s"
    echo
    echo "Log file: $LOG_FILE"
    echo "Lock file: $LOCK_FILE"
}

# =============================================================================
# VALIDATE / SCRUB / RESTORE / CACHE-EXCLUSION COMMANDS
# =============================================================================

# Read-only validation of the backup system, single-parent policy, and the
# parent-reference invariant that incrementals depend on. Returns 1 on problems.
run_validate() {
    echo "=== BTRFS Backup Validation ==="
    local problems=0

    echo "[config]"
    validate_uuid "$EXTERNAL_DEVICE_UUID" && echo "  ✓ UUID format valid"
    if [[ -d "$BTRFS_POOL" ]] && btrfs filesystem show "$BTRFS_POOL" >/dev/null 2>&1; then
        echo "  ✓ BTRFS pool present: $BTRFS_POOL"
    else
        echo "  ✗ BTRFS pool missing / not btrfs: $BTRFS_POOL"; problems=$((problems+1))
    fi
    echo "  Incremental mode: $INCREMENTAL_MODE"

    echo "[subvolumes]"
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"; local path="${subvol_entry##*:}"
        if btrfs subvolume show "$path" >/dev/null 2>&1; then
            echo "  ✓ $name -> $path"
        else
            echo "  ✗ $name -> $path (missing / not a subvolume)"; problems=$((problems+1))
        fi
    done

    echo "[external drive]"
    if is_external_drive_mounted; then
        echo "  ✓ mounted at $EXTERNAL_MOUNT"
        if verify_external_is_btrfs; then echo "  ✓ external is BTRFS"; else echo "  ✗ external not BTRFS"; problems=$((problems+1)); fi
        local opts; opts=$(findmnt -no OPTIONS "$EXTERNAL_MOUNT" 2>/dev/null | grep -o 'compress[^,]*' | head -1)
        echo "  compression: ${opts:-none}"

        for subvol_entry in "${SUBVOLUMES[@]}"; do
            local name="${subvol_entry%%:*}"
            local backup_dir="$EXTERNAL_BACKUP_DIR/$name"
            local pcount=0 icount=0
            if [[ -d "$backup_dir" ]]; then
                pcount=$(find "$backup_dir" -maxdepth 1 -name "parent_*" -type d 2>/dev/null | wc -l)
                icount=$(find "$backup_dir" -maxdepth 1 -name "incremental_*" -type d 2>/dev/null | wc -l)
            fi
            echo "  [$name] parents=$pcount incrementals=$icount"

            if [[ $pcount -gt 1 ]]; then
                echo "    ✗ POLICY VIOLATION: more than one parent (should be exactly 1)"; problems=$((problems+1))
            fi

            local parent; parent=$(get_latest_parent_backup "$name")
            if [[ -n "$parent" ]]; then
                local pts; pts=$(parse_timestamp "$(basename "$parent")")
                local pstr; pstr=$(date -d "@$pts" '+%Y%m%d_%H%M%S')
                if [[ -d "$SNAPSHOT_DIR/$name/backup_${pstr}" ]]; then
                    echo "    ✓ local parent reference present (backup_${pstr})"
                else
                    echo "    ✗ local parent reference MISSING (backup_${pstr}) - incrementals will fail; run with --recovery or --force-new-parent"; problems=$((problems+1))
                fi
                if btrfs subvolume show "$parent" >/dev/null 2>&1; then echo "    ✓ parent subvolume valid"; else echo "    ✗ parent subvolume invalid/corrupt"; problems=$((problems+1)); fi
            elif [[ $pcount -eq 0 ]]; then
                echo "    ⚠ no parent yet (first backup will create one)"
            fi

            local orphans=0
            [[ -d "$backup_dir" ]] && orphans=$(find "$backup_dir" -maxdepth 1 -name "backup_*" -type d 2>/dev/null | wc -l)
            [[ $orphans -gt 0 ]] && echo "    ⚠ $orphans orphaned partial receive(s) - will be cleaned on next backup"

            local clen; clen=$(get_incremental_chain_length "$name")
            [[ $clen -ge $MAX_INCREMENTAL_CHAIN_LENGTH ]] && echo "    ⚠ chain length $clen >= $MAX_INCREMENTAL_CHAIN_LENGTH (consider --force-new-parent)"
        done

        echo "[freshness]"
        report_backup_freshness || problems=$((problems+1))

        echo "[space]"
        local usage; usage=$(check_disk_space "$EXTERNAL_MOUNT" "External" 2>/dev/null || echo "?")
        echo "  external usage: ${usage}%"
        if [[ "$usage" =~ ^[0-9]+$ ]] && [[ $usage -ge $DISK_SPACE_CRITICAL_THRESHOLD ]]; then
            echo "  ✗ above critical threshold ${DISK_SPACE_CRITICAL_THRESHOLD}%"; problems=$((problems+1))
        fi
    else
        echo "  ⚠ external drive not mounted - skipping external checks"
    fi

    echo
    if [[ $problems -eq 0 ]]; then
        echo "Validation result: OK (no problems found)"
        return 0
    fi
    echo "Validation result: $problems problem(s) found"
    return 1
}

# Data-integrity scrub (detects bit-rot). Target: external (default), pool, all.
run_scrub() {
    local target="${1:-external}"

    if [[ "$target" == "pool" || "$target" == "all" ]]; then
        echo "=== Scrubbing BTRFS pool: $BTRFS_POOL ==="
        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD RUN: btrfs scrub start -B $BTRFS_POOL"
        elif btrfs scrub start -B "$BTRFS_POOL"; then
            log "Pool scrub completed with no unrecoverable errors"
        else
            error_continue "Pool scrub reported errors - check 'btrfs scrub status $BTRFS_POOL'"
        fi
    fi

    if [[ "$target" == "external" || "$target" == "all" ]]; then
        if ! is_external_drive_mounted; then
            error_exit "External drive not mounted - cannot scrub"
        fi
        echo "=== Scrubbing external drive: $EXTERNAL_MOUNT ==="
        echo "(reads all data and verifies checksums - may take a while)"
        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD RUN: btrfs scrub start -B $EXTERNAL_MOUNT"
        elif btrfs scrub start -B "$EXTERNAL_MOUNT"; then
            log "External scrub completed with no unrecoverable errors"
            send_notification "INFO" "External drive scrub passed"
        else
            log "External scrub reported errors - check 'btrfs scrub status $EXTERNAL_MOUNT'"
            send_notification "CRITICAL" "External drive scrub found errors - backup integrity at risk"
            OPERATION_FAILED=true
        fi
    fi
    return 0
}

# Guided restore of the newest external backup into a NEW subvolume. Never
# touches the live @ / @home. Usage: restore <root|home> [target_dir]
run_restore() {
    local subvolume="${1:-}"
    local target_base="${2:-$BTRFS_POOL/restore}"

    if [[ -z "$subvolume" ]]; then
        echo "Usage: $(basename "$0") restore <root|home> [target_dir]"
        echo
        echo "Restores the newest external backup (parent + its incrementals) into a"
        echo "new subvolume under target_dir (default: $BTRFS_POOL/restore)."
        echo "It NEVER overwrites your live @ or @home - you swap it in manually."
        return 1
    fi

    local valid=false
    for e in "${SUBVOLUMES[@]}"; do [[ "${e%%:*}" == "$subvolume" ]] && valid=true; done
    [[ "$valid" == "true" ]] || { echo "ERROR: invalid subvolume '$subvolume'"; return 1; }

    is_external_drive_mounted || error_exit "External drive not mounted"
    verify_external_is_btrfs || error_exit "External drive is not BTRFS"

    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvolume"
    local parent; parent=$(get_latest_parent_backup "$subvolume")
    [[ -n "$parent" ]] || { echo "ERROR: no parent backup found for $subvolume"; return 1; }

    local parent_ts; parent_ts=$(parse_timestamp "$(basename "$parent")")
    local parent_ts_str; parent_ts_str=$(date -d "@$parent_ts" '+%Y%m%d_%H%M%S')

    local incrementals=()
    while IFS= read -r i; do [[ -n "$i" ]] && incrementals+=("$i"); done \
        < <(find "$backup_dir" -maxdepth 1 -name "incremental_${parent_ts_str}_*" -type d 2>/dev/null | sort)

    local final_state="$(basename "$parent")"
    [[ ${#incrementals[@]} -gt 0 ]] && final_state="$(basename "${incrementals[-1]}")"

    echo "=== Restore plan for $subvolume ==="
    echo "  Parent:        $(basename "$parent")"
    echo "  Incrementals:  ${#incrementals[@]}"
    for i in "${incrementals[@]}"; do echo "     - $(basename "$i")"; done
    echo "  Target dir:    $target_base"
    echo "  Restored state = subvolume '$final_state' (newest point in time)"
    echo
    echo "This does NOT touch your running system. Type 'restore' to proceed:"
    read -r confirm
    [[ "$confirm" == "restore" ]] || { echo "Cancelled"; return 1; }

    mkdir -p "$target_base" 2>/dev/null || error_exit "Cannot create target dir $target_base"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD RUN: btrfs send '$parent' | btrfs receive '$target_base'"
        local prev="$parent"
        for i in "${incrementals[@]}"; do
            if [[ "$INCREMENTAL_MODE" == "chain" ]]; then
                log "WOULD RUN: btrfs send -p '$prev' '$i' | btrfs receive '$target_base'"; prev="$i"
            else
                log "WOULD RUN: btrfs send -p '$parent' '$i' | btrfs receive '$target_base'"
            fi
        done
        echo "Dry-run only; nothing restored."
        return 0
    fi

    log "Restoring parent $(basename "$parent")..."
    btrfs send "$parent" | btrfs receive "$target_base" || error_exit "Failed to receive parent during restore"

    local prev="$parent"
    for i in "${incrementals[@]}"; do
        log "Applying incremental $(basename "$i")..."
        if [[ "$INCREMENTAL_MODE" == "chain" ]]; then
            btrfs send -p "$prev" "$i" | btrfs receive "$target_base" || error_exit "Failed to apply $(basename "$i")"
            prev="$i"
        else
            btrfs send -p "$parent" "$i" | btrfs receive "$target_base" || error_exit "Failed to apply $(basename "$i")"
        fi
    done

    echo
    echo "Restore complete. Newest state is subvolume: $target_base/$final_state"
    echo "Inspect it, then swap it in for @ / @home from a live environment if needed."
    echo "(This script deliberately does NOT auto-replace your live subvolumes.)"
    return 0
}

# Convert high-churn cache dirs into their own subvolumes so they are excluded
# from @/@home snapshots (btrfs snapshots do not descend into nested subvolumes).
# Data is COPIED then swapped; the old copy is kept until you remove it.
CACHE_EXCLUDE_PATHS=("/home/USERNAME/.cache")   # add "/var/cache" here if desired

setup_cache_exclusion() {
    echo "=== Cache exclusion setup ==="
    echo "Converts cache dirs into btrfs subvolumes so they are excluded from"
    echo "snapshots/sends. Best run from a TTY with browsers and heavy apps CLOSED."
    echo "Data is moved via copy-then-swap; the old copy is kept for safety."
    echo

    for cpath in "${CACHE_EXCLUDE_PATHS[@]}"; do
        echo "--- $cpath ---"
        if [[ ! -e "$cpath" ]]; then
            echo "  does not exist - creating as a subvolume"
            if [[ "$DRY_RUN" == "true" ]]; then log "WOULD CREATE subvolume: $cpath"; else btrfs subvolume create "$cpath" && echo "  created ✓"; fi
            continue
        fi
        if btrfs subvolume show "$cpath" >/dev/null 2>&1; then
            echo "  already a subvolume - nothing to do ✓"
            continue
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD: create ${cpath}.newsubvol, copy contents, swap dirs, keep old copy"
            continue
        fi

        echo "  Type 'convert' to convert $cpath now, anything else to skip:"
        read -r ans
        [[ "$ans" == "convert" ]] || { echo "  skipped"; continue; }

        local newsub="${cpath}.newsubvol"
        local old="${cpath}.old.$$"
        if ! btrfs subvolume create "$newsub"; then echo "  ERROR creating $newsub - skipping"; continue; fi
        if cp -a "$cpath/." "$newsub/" 2>/dev/null; then
            if mv "$cpath" "$old" && mv "$newsub" "$cpath"; then
                echo "  converted ✓  old data kept at: $old"
                echo "  remove it when satisfied:  rm -rf '$old'"
            else
                echo "  ERROR swapping directories - check state manually"
            fi
        else
            echo "  ERROR copying contents - aborting this path"
            btrfs subvolume delete "$newsub" 2>/dev/null || true
        fi
    done
    echo
    echo "Done. New cache subvolumes will be excluded from future snapshots automatically."
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS|ARGUMENTS]

Commands:
    backup    Create local snapshot and external backup (if drive available)
    cleanup   Only perform cleanup operations
    status    Show snapshot and backup status
    health    Show system health information (incl. freshness & scrub status)
    validate  Read-only integrity/policy check (safe; no changes)
    list      List snapshots and backups
    delete    Delete specific snapshots or backups
    restore   Restore newest external backup into a new subvolume (never touches live)
    scrub     Data-integrity scrub of the external drive (detects bit-rot)
    exclude-caches  Convert cache dirs to subvolumes so snapshots skip them
    help      Display comprehensive help message

Options:
    --dry-run          Show what would be done without executing any commands
    --force-new-parent Force creation of new parent backup (DELETES all existing backups!)
    --recovery         Auto-recreate the parent if the incremental reference is missing/corrupt

List command usage:
    $0 list [all|local|external]    # List all, local only, or external only

Delete command usage:
    $0 delete <local|external> <root|home> <backup_name>

Restore command usage:
    $0 restore <root|home> [target_dir]   # default target: $BTRFS_POOL/restore

Scrub command usage:
    $0 scrub [external|pool|all]    # default: external

Examples:
    $0 backup                       # Normal backup (creates incremental)
    $0 backup --dry-run             # Preview backup routine
    $0 backup --recovery            # Backup, auto-recreating parent if reference lost
    $0 backup --force-new-parent    # Create new parent (delete all old backups!)
    $0 cleanup                      # Clean up old incrementals
    $0 validate                     # Check backups/policy without changing anything
    $0 scrub                        # Verify external drive integrity
    $0 restore home                 # Restore newest home backup to a staging subvolume
    $0 list                         # List all snapshots and backups
    $0 health                       # Check system health
    $0 status                       # Show current status (always safe)

If no command is specified, 'backup' is assumed.

Single-Parent Backup Strategy (v2.3):
- ONLY ONE parent backup exists at any time (maximum space efficiency)
- All backups after the first are incremental (saves ~35% disk space)
- Parent backups are NEVER auto-deleted
- Incremental backups cleaned up after $INCREMENTAL_KEEP_DAYS days
- Local snapshots kept for $LOCAL_SNAPSHOT_KEEP_DAYS days (parent reference protected)
- Use --force-new-parent quarterly (~90 days) to refresh the parent backup

WARNING about --force-new-parent:
- This flag deletes ALL existing backups (parent + incrementals) before creating new parent
- Use this to refresh your backup chain every 90 days or when needed
- Always test with --dry-run first!

Configuration:
- Edit LOCAL_SNAPSHOT_KEEP_DAYS to change local snapshot retention (default: 30 days)
- Edit INCREMENTAL_KEEP_DAYS to change incremental retention (default: 30 days)
- Edit MAX_INCREMENTAL_CHAIN_LENGTH to set chain length warning (default: 90)
- External backups only run when drive is connected and mounted
EOF
}

# Display comprehensive help information
show_help() {
    usage
    echo
    echo "For detailed documentation, see the script comments or run '$0 status'"
    echo "Log file: $LOG_FILE"
}

# =============================================================================
# COMMAND LINE PARSING
# =============================================================================

# Parse command line arguments
parse_arguments() {
    COMMAND=""
    COMMAND_ARGS=()

    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                DRY_RUN="true"
                ;;
            --force-new-parent)
                FORCE_NEW_PARENT="true"
                log "Force new parent mode enabled - will delete all existing backups and create new parent"
                ;;
            --recovery)
                RECOVERY_MODE="true"
                log "Recovery mode enabled - will recreate parent if corrupted"
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            backup|cleanup|status|help|list|delete|health|validate|scrub|restore|exclude-caches)
                if [[ -z "$COMMAND" ]]; then
                    COMMAND="$arg"
                else
                    COMMAND_ARGS+=("$arg")
                fi
                ;;
            all|local|external|root|home|pool)
                COMMAND_ARGS+=("$arg")
                ;;
            backup_*|parent_*|incremental_*)
                COMMAND_ARGS+=("$arg")
                ;;
            *)
                if [[ -n "$arg" ]]; then
                    COMMAND_ARGS+=("$arg")
                fi
                ;;
        esac
    done

    # Set defaults
    COMMAND=${COMMAND:-backup}

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DEBUG: Dry-run mode enabled" >&2
    fi

    if [[ "$FORCE_NEW_PARENT" == "true" ]]; then
        echo "WARNING: Force new parent mode - ALL existing backups will be deleted!" >&2
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Parse arguments
    parse_arguments "$@"

    # Show dry-run status
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "=== DRY-RUN MODE - No changes will be made ==="
        echo
    fi

    # Commands that don't need root or locking
    case "$COMMAND" in
        status)
            show_status
            return 0
            ;;
        help)
            show_help
            return 0
            ;;
        list)
            local list_type="${COMMAND_ARGS[0]:-all}"
            list_backups "$list_type"
            return 0
            ;;
        health)
            show_health
            return 0
            ;;
        delete)
            if [[ ${#COMMAND_ARGS[@]} -lt 3 ]]; then
                echo "ERROR: Delete command requires 3 arguments"
                echo ""
                usage
                return 1
            fi

            local backup_type="${COMMAND_ARGS[0]}"
            local subvolume="${COMMAND_ARGS[1]}"
            local backup_name="${COMMAND_ARGS[2]}"

            delete_backup "$backup_type" "$subvolume" "$backup_name"
            return $?
            ;;
    esac

    # All other commands need root and locking
    check_root
    acquire_lock

    # Execute command. Only backup/cleanup do the strict pre-checks that
    # error-exit; validate must be able to REPORT problems instead of aborting.
    case "$COMMAND" in
        validate)
            local vrc=0
            run_validate || vrc=$?
            return $vrc
            ;;
        scrub)
            run_scrub "${COMMAND_ARGS[0]:-external}" || true
            ;;
        restore)
            local rrc=0
            run_restore "${COMMAND_ARGS[0]:-}" "${COMMAND_ARGS[1]:-}" || rrc=$?
            return $rrc
            ;;
        exclude-caches)
            setup_cache_exclusion || true
            ;;
        backup)
            validate_configuration
            ensure_snapshot_dir
            check_subvolumes
            log "Starting backup routine"
            create_backup_snapshot
            create_external_backup
            cleanup_regular_snapshots
            cleanup_external_incrementals
            log "Backup routine completed"
            ;;
        cleanup)
            validate_configuration
            log "Starting cleanup routine"
            cleanup_regular_snapshots
            if is_external_drive_mounted; then
                cleanup_external_incrementals
            fi
            log "Cleanup routine completed"
            ;;
        *)
            echo "Unknown command: $COMMAND"
            usage
            return 1
            ;;
    esac

    if [[ "$DRY_RUN" == "true" ]]; then
        echo
        echo "=== DRY-RUN COMPLETED - No actual changes were made ==="
        echo "Run without --dry-run to execute the operations shown above."
    fi

    # Return appropriate exit code
    if [[ "$OPERATION_FAILED" == "true" ]]; then
        return 1
    fi

    return 0
}

# Run main function with all arguments
main "$@"