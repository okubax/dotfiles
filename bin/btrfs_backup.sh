#!/bin/bash

# BTRFS Simplified Snapshot and Backup Script for Laptop - Enhanced Version
# Usage: ./btrfs_backup.sh [backup|cleanup|health] [--dry-run]
# Version: 2.1 - Enhanced with security and robustness improvements

set -euo pipefail

# Global variables
DRY_RUN=false
LOCK_FILE="/var/run/btrfs_backup.lock"
LOCK_FD=200
SCRIPT_PID=$$
OPERATION_FAILED=false

# Configuration
BTRFS_POOL="/mnt/btr_pool"              # Main BTRFS pool mount point
ROOT_SUBVOLUME="$BTRFS_POOL/@"          # Root subvolume path
HOME_SUBVOLUME="$BTRFS_POOL/@home"      # Home subvolume path
SNAPSHOT_DIR="$BTRFS_POOL/.snapshots"   # Local snapshot directory
EXTERNAL_MOUNT="/run/media/ajibola/98f725b9-9e2b-4b89-8345-6e0ca03657f4"  # External drive mount point
EXTERNAL_BACKUP_DIR="$EXTERNAL_MOUNT/btrfs_backups"
LOG_FILE="/var/log/btrfs_backup.log"

# Subvolumes to backup (add more if needed)
declare -a SUBVOLUMES=("root:$ROOT_SUBVOLUME" "home:$HOME_SUBVOLUME")

# Device identification for external drive
EXTERNAL_DEVICE_UUID="98f725b9-9e2b-4b89-8345-6e0ca03657f4"  # Your external drive UUID
EXTERNAL_DEVICE_LABEL=""                # Or set device label here if preferred

# Retention settings
REGULAR_KEEP_DAYS=7                      # Keep regular snapshots for 7 days
PARENT_BACKUP_INTERVAL_DAYS=30           # Create new parent backup every 30 days
MIN_PARENT_RETENTION_DAYS=30             # Keep at least one parent backup for 30 days

# Advanced settings
DISK_SPACE_WARNING_THRESHOLD=85         # Warn when disk usage exceeds this percentage
DISK_SPACE_CRITICAL_THRESHOLD=95        # Critical threshold for disk usage
DISK_SPACE_REQUIRED_PERCENT=10          # Minimum free space required to start backup
BACKUP_VERIFICATION_ENABLED=true        # Enable backup verification
MOUNT_TIMEOUT=5                         # Timeout for mount point checks (seconds)
ENABLE_BANDWIDTH_LIMIT=false            # Enable bandwidth limiting for send/receive
BANDWIDTH_LIMIT_MB=50                   # Bandwidth limit in MB/s (if enabled)

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

# Logging function
log() {
    local prefix=""
    if [[ "$DRY_RUN" == "true" ]]; then
        prefix="[DRY-RUN] "
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${prefix}$1" | tee -a "$LOG_FILE"
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
    if [[ $REGULAR_KEEP_DAYS -lt 1 ]]; then
        error_exit "REGULAR_KEEP_DAYS must be at least 1"
    fi

    if [[ $PARENT_BACKUP_INTERVAL_DAYS -lt 1 ]]; then
        error_exit "PARENT_BACKUP_INTERVAL_DAYS must be at least 1"
    fi

    log "Configuration validation passed"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Parse timestamp from backup name and return unix epoch
# Arguments: backup_name (format: backup_YYYYMMDD_HHMMSS or parent_YYYYMMDD_HHMMSS)
# Returns: unix timestamp or 0 if parsing fails
parse_timestamp() {
    local name="$1"

    # Extract timestamp from name (format: PREFIX_YYYYMMDD_HHMMSS)
    if [[ $name =~ (backup|parent|incremental)_?([0-9]{8})_([0-9]{6}) ]]; then
        local date_part="${BASH_REMATCH[2]}"
        local time_part="${BASH_REMATCH[3]}"

        local year="${date_part:0:4}"
        local month="${date_part:4:2}"
        local day="${date_part:6:2}"
        local hour="${time_part:0:2}"
        local minute="${time_part:2:2}"
        local second="${time_part:4:2}"

        # Get unix timestamp
        local timestamp=$(date -d "$year-$month-$day $hour:$minute:$second" +%s 2>/dev/null || echo "0")
        echo "$timestamp"
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

# Check if we need a new parent backup (older than configured days)
need_new_parent_backup() {
    local subvol_name="$1"
    local latest_parent=$(get_latest_parent_backup "$subvol_name")

    if [[ -z "$latest_parent" ]]; then
        echo "true"  # No parent exists
        return
    fi

    local parent_name=$(basename "$latest_parent")
    local parent_timestamp=$(parse_timestamp "$parent_name")

    if [[ $parent_timestamp -eq 0 ]]; then
        echo "true"  # Invalid parent name format, create new one
        return
    fi

    local current_time=$(date +%s)
    local age_seconds=$((current_time - parent_timestamp))
    local age_days=$((age_seconds / 86400))

    if [[ $age_days -ge $PARENT_BACKUP_INTERVAL_DAYS ]]; then
        echo "true"
    else
        echo "false"
    fi
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

# Cleanup old regular snapshots
cleanup_regular_snapshots() {
    local retention_days="$REGULAR_KEEP_DAYS"
    local description="retention: $REGULAR_KEEP_DAYS days"

    log "Cleaning up backup snapshots older than $retention_days days ($description)"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_dir="$SNAPSHOT_DIR/$name"

        if [[ ! -d "$subvol_dir" ]]; then
            continue
        fi

        log "Checking for old backup snapshots in $subvol_dir"

        local snapshots_to_delete=()
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
                        snapshots_to_delete+=("$snapshot")
                        log "Will delete: $snapshot_name (older than $retention_days days)"
                    else
                        log "Will keep: $snapshot_name (within retention period)"
                    fi
                else
                    log "Could not parse timestamp from $snapshot_name, skipping"
                fi
            fi
        done < <(find "$subvol_dir" -maxdepth 1 -name "backup_*" -type d 2>/dev/null || true)

        if [[ ${#snapshots_to_delete[@]} -eq 0 ]]; then
            log "No old backup snapshots to clean up for $name"
        else
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

# Delete old parent and incrementals before creating new parent
cleanup_old_parent_chain() {
    local subvol_name="$1"
    local backup_dir="$EXTERNAL_BACKUP_DIR/$subvol_name"

    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi

    log "Cleaning up old parent backup chain for $subvol_name"

    # Find the oldest parent backup
    local oldest_parent=$(find "$backup_dir" -maxdepth 1 -name "parent_*" -type d 2>/dev/null | sort | head -1)

    if [[ -z "$oldest_parent" ]]; then
        log "No parent backups found for cleanup"
        return 0
    fi

    local parent_name=$(basename "$oldest_parent")
    log "Found oldest parent backup: $parent_name"

    local parent_timestamp=$(parse_timestamp "$parent_name")

    if [[ $parent_timestamp -gt 0 ]]; then
        local parent_timestamp_str=$(date -d "@$parent_timestamp" '+%Y%m%d_%H%M%S')

        # Find all incrementals connected to this parent
        local incrementals_to_delete=()
        local incremental_delete_failed=false

        while IFS= read -r incremental; do
            if [[ -n "$incremental" ]]; then
                incrementals_to_delete+=("$incremental")
            fi
        done < <(find "$backup_dir" -maxdepth 1 -name "incremental_${parent_timestamp_str}_*" -type d 2>/dev/null || true)

        # Delete incrementals first
        for incremental in "${incrementals_to_delete[@]}"; do
            if ! execute_command "Remove old incremental backup $(basename "$incremental") for $subvol_name" \
                                btrfs subvolume delete "$incremental" "true"; then
                incremental_delete_failed=true
            fi
        done

        # Only delete parent if all incrementals were deleted successfully
        if [[ "$incremental_delete_failed" == "false" ]]; then
            execute_command "Remove old parent backup $parent_name for $subvol_name" \
                           btrfs subvolume delete "$oldest_parent" "true"
            log "Cleaned up parent backup chain: $parent_name with ${#incrementals_to_delete[@]} incrementals"
        else
            log "WARNING: Some incrementals failed to delete, keeping parent backup $parent_name"
        fi
    else
        log "Invalid parent backup name format: $parent_name"
    fi
}

# Send backup with optional bandwidth limiting
send_backup() {
    local source="$1"
    local dest_dir="$2"
    local parent="${3:-}"  # Optional parent for incremental

    local send_cmd="btrfs send"
    if [[ -n "$parent" ]]; then
        send_cmd="$send_cmd -p '$parent'"
    fi
    send_cmd="$send_cmd '$source'"

    local receive_cmd="btrfs receive '$dest_dir'"

    if [[ "$ENABLE_BANDWIDTH_LIMIT" == "true" ]] && command -v pv >/dev/null 2>&1; then
        local full_cmd="$send_cmd | pv -L ${BANDWIDTH_LIMIT_MB}m | $receive_cmd"
        log "Using bandwidth limit: ${BANDWIDTH_LIMIT_MB}MB/s"
    else
        local full_cmd="$send_cmd | $receive_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD EXECUTE: $full_cmd"
        return 0
    fi

    eval "$full_cmd"
}

# Create external backup (parent or incremental)
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

    setup_external_backup_dir

    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_backups=()

    # Check external drive disk space
    check_and_warn_disk_space "$EXTERNAL_MOUNT" "External drive" "true"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"

        log "Creating external backup for $name"

        # Find the most recent snapshot for this subvolume
        local latest_snapshot=$(get_latest_snapshot "$name")

        if [[ -z "$latest_snapshot" ]]; then
            log "No backup snapshot found for $name backup - skipping"
            failed_backups+=("$name")
            continue
        fi

        log "Using snapshot for $name backup: $(basename "$latest_snapshot")"

        # Check if we need a new parent backup
        if [[ "$(need_new_parent_backup "$name")" == "true" ]]; then
            log "Creating new parent backup for $name (old parent expired or missing)"

            # Clean up old parent chain first to free space
            cleanup_old_parent_chain "$name"

            # Create new parent backup
            local parent_name="parent_${timestamp}"
            local parent_path="$EXTERNAL_BACKUP_DIR/$name/$parent_name"

            log "Creating full parent backup for $name: $parent_name"
            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD EXECUTE: btrfs send '$latest_snapshot' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
                log "WOULD RENAME: received snapshot to $parent_name"
            else
                if send_backup "$latest_snapshot" "$EXTERNAL_BACKUP_DIR/$name"; then
                    local received_name=$(basename "$latest_snapshot")
                    local received_path="$EXTERNAL_BACKUP_DIR/$name/$received_name"

                    if [[ -d "$received_path" ]] && mv "$received_path" "$parent_path"; then
                        log "Successfully created parent backup for $name: $parent_path"
                        verify_backup "$parent_path" "$name parent backup"
                    else
                        error_continue "Failed to rename parent backup for $name"
                        failed_backups+=("$name")
                    fi
                else
                    error_continue "Failed to create parent backup for $name"
                    failed_backups+=("$name")
                fi
            fi
        else
            log "Creating incremental backup for $name"

            # Find the current parent backup
            local current_parent=$(get_latest_parent_backup "$name")
            if [[ -z "$current_parent" ]]; then
                log "ERROR: No parent backup found for incremental backup"
                failed_backups+=("$name")
                continue
            fi

            local parent_name=$(basename "$current_parent")
            local parent_timestamp=$(parse_timestamp "$parent_name")

            if [[ $parent_timestamp -eq 0 ]]; then
                log "ERROR: Could not parse parent timestamp"
                failed_backups+=("$name")
                continue
            fi

            local parent_timestamp_str=$(date -d "@$parent_timestamp" '+%Y%m%d_%H%M%S')

            # Find corresponding local snapshot for the parent
            local local_parent="$SNAPSHOT_DIR/$name/backup_${parent_timestamp_str}"
            if [[ ! -d "$local_parent" ]] || ! btrfs subvolume show "$local_parent" >/dev/null 2>&1; then
                log "Local parent snapshot not found: $local_parent"
                log "Creating new parent backup instead"
                failed_backups+=("$name")
                continue
            fi

            # Create incremental backup
            local incremental_name="incremental_${parent_timestamp_str}_${timestamp}"
            local incremental_path="$EXTERNAL_BACKUP_DIR/$name/$incremental_name"

            log "Creating incremental backup for $name: $incremental_name"
            log "Using local parent: $(basename "$local_parent")"

            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD EXECUTE: btrfs send -p '$local_parent' '$latest_snapshot' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
                log "WOULD RENAME: received snapshot to $incremental_name"
            else
                if send_backup "$latest_snapshot" "$EXTERNAL_BACKUP_DIR/$name" "$local_parent"; then
                    local received_name=$(basename "$latest_snapshot")
                    local received_path="$EXTERNAL_BACKUP_DIR/$name/$received_name"

                    if [[ -d "$received_path" ]] && mv "$received_path" "$incremental_path"; then
                        log "Successfully created incremental backup for $name: $incremental_path"
                        verify_backup "$incremental_path" "$name incremental backup"
                    else
                        error_continue "Failed to rename incremental backup for $name"
                        failed_backups+=("$name")
                    fi
                else
                    error_continue "Failed to create incremental backup for $name"
                    failed_backups+=("$name")
                fi
            fi
        fi
    done

    # Report any failures
    if [[ ${#failed_backups[@]} -gt 0 ]]; then
        log "WARNING: Failed to create external backups for: ${failed_backups[*]}"
        OPERATION_FAILED=true
    else
        log "All external backups created successfully"
    fi
}

# Cleanup old external incremental backups
cleanup_external_incrementals() {
    if ! is_external_drive_mounted; then
        log "External drive not mounted - skipping external cleanup"
        return 0
    fi

    local retention_days="$REGULAR_KEEP_DAYS"

    log "Cleaning up incremental backups older than $retention_days days"

    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_backup_dir="$EXTERNAL_BACKUP_DIR/$name"

        if [[ ! -d "$subvol_backup_dir" ]]; then
            continue
        fi

        log "Checking for old incremental backups in $subvol_backup_dir"

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

                        log "Incremental backup $backup_name: created $(date -d "@$backup_timestamp" '+%Y-%m-%d %H:%M:%S'), age: $age_days days"

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
            for backup in "${backups_to_delete[@]}"; do
                execute_command "Remove old incremental backup $(basename "$backup") for $name" \
                               btrfs subvolume delete "$backup" "true"
            done
        fi
    done
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

    # Confirmation prompt
    echo "WARNING: About to delete $description"
    echo "Path: $backup_path"
    echo ""
    echo "This action cannot be undone!"
    echo "Type 'yes' to confirm deletion, or anything else to cancel:"
    read -r confirmation

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
    else
        echo "  External drive: not mounted"
    fi
}

# Show status of snapshots and backups
show_status() {
    echo "=== BTRFS Simplified Snapshot Status ==="
    echo "Version: v2.1-enhanced (Improved security and robustness)"
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
    echo "Configuration:"
    echo "  Regular retention: $REGULAR_KEEP_DAYS days"
    echo "  Parent backup interval: $PARENT_BACKUP_INTERVAL_DAYS days"
    echo "  Minimum parent retention: $MIN_PARENT_RETENTION_DAYS days"
    echo "  Disk space warning threshold: ${DISK_SPACE_WARNING_THRESHOLD}%"
    echo "  Disk space critical threshold: ${DISK_SPACE_CRITICAL_THRESHOLD}%"
    echo "  Required free space for backup: ${DISK_SPACE_REQUIRED_PERCENT}%"
    echo "  Backup verification: $([ "$BACKUP_VERIFICATION_ENABLED" == "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Mount timeout: ${MOUNT_TIMEOUT}s"
    echo
    echo "Log file: $LOG_FILE"
    echo "Lock file: $LOCK_FILE"
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS|ARGUMENTS]

Commands:
    backup    Create local snapshot and external backup (if drive available)
    cleanup   Only perform cleanup operations
    status    Show snapshot and backup status
    health    Show system health information
    list      List snapshots and backups
    delete    Delete specific snapshots or backups
    help      Display comprehensive help message

Options:
    --dry-run    Show what would be done without executing any commands

List command usage:
    $0 list [all|local|external]    # List all, local only, or external only

Delete command usage:
    $0 delete <local|external> <root|home> <backup_name>

Examples:
    $0 backup --dry-run             # Preview backup routine
    $0 cleanup --dry-run            # Preview cleanup operations
    $0 list                         # List all snapshots and backups
    $0 health                       # Check system health
    $0 status                       # Show current status (always safe)

If no command is specified, 'backup' is assumed.

Configuration:
- Edit REGULAR_KEEP_DAYS to change snapshot/incremental retention
- Edit PARENT_BACKUP_INTERVAL_DAYS to change parent backup frequency
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
            --help|-h)
                show_help
                exit 0
                ;;
            backup|cleanup|status|help|list|delete|health)
                if [[ -z "$COMMAND" ]]; then
                    COMMAND="$arg"
                else
                    COMMAND_ARGS+=("$arg")
                fi
                ;;
            all|local|external|root|home)
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

    # Validate configuration
    validate_configuration

    # Acquire lock
    acquire_lock

    # Ensure snapshot directory exists
    ensure_snapshot_dir

    # Check subvolumes
    check_subvolumes

    # Execute command
    case "$COMMAND" in
        backup)
            log "Starting backup routine"
            create_backup_snapshot
            create_external_backup
            cleanup_regular_snapshots
            cleanup_external_incrementals
            log "Backup routine completed"
            ;;
        cleanup)
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
