#!/bin/bash

# BTRFS Incremental Snapshot and Backup Script for Laptop
# Usage: ./btrfs_backup.sh [daily|weekly|monthly|cleanup] [--dry-run]

set -euo pipefail

# Global dry-run flag
DRY_RUN=false

# Configuration
BTRFS_POOL="/mnt/btr_pool"              # Main BTRFS pool mount point
ROOT_SUBVOLUME="$BTRFS_POOL/@"          # Root subvolume path
HOME_SUBVOLUME="$BTRFS_POOL/@home"      # Home subvolume path
SNAPSHOT_DIR="$BTRFS_POOL/.snapshots"   # Local snapshot directory
EXTERNAL_MOUNT=""  # External drive mount point
EXTERNAL_BACKUP_DIR="$EXTERNAL_MOUNT/btrfs_backups"
LOG_FILE="/var/log/btrfs_backup.log"

# Subvolumes to backup (add more if needed)
declare -a SUBVOLUMES=("root:$ROOT_SUBVOLUME" "home:$HOME_SUBVOLUME")

# Device identification for external drive
EXTERNAL_DEVICE_UUID=""  # Your external drive UUID
EXTERNAL_DEVICE_LABEL=""                # Or set device label here if preferred

# Retention settings
DAILY_KEEP_DAYS=7                       # Keep daily snapshots for 7 days
WEEKLY_KEEP_WEEKS=4                     # Keep weekly snapshots for 4 weeks
MONTHLY_KEEP_MONTHS=6                   # Keep monthly backups for 6 months (increased from 1)

# Advanced settings
DISK_SPACE_WARNING_THRESHOLD=85         # Warn when disk usage exceeds this percentage
DISK_SPACE_CRITICAL_THRESHOLD=95        # Critical threshold for disk usage
BACKUP_VERIFICATION_ENABLED=true        # Enable backup verification
FULL_BACKUP_INTERVAL_MONTHS=2           # How often to do full backups vs incremental
INCREMENTAL_CLEANUP_ENABLED=true        # Enable incremental cleanup

# Logging function
log() {
    local prefix=""
    if [[ "$DRY_RUN" == "true" ]]; then
        prefix="[DRY-RUN] "
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${prefix}$1" | tee -a "$LOG_FILE"
}

# Dry-run aware command execution with error recovery
execute_command() {
    local cmd="$1"
    local description="$2"
    local allow_failure="${3:-false}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "WOULD EXECUTE: $cmd"
        log "DESCRIPTION: $description"
        return 0
    else
        log "EXECUTING: $description"
        log "COMMAND: $cmd"
        if eval "$cmd"; then
            log "SUCCESS: $description"
            return 0
        else
            if [[ "$allow_failure" == "true" ]]; then
                error_continue "FAILED: $description - Command was: $cmd"
                return 1
            else
                error_exit "FAILED: $description - Command was: $cmd"
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

# Disk space warning system
check_and_warn_disk_space() {
    local path="$1"
    local description="$2"
    
    local usage=$(check_disk_space "$path" "$description")
    
    if [[ -z "$usage" ]]; then
        log "WARNING: Could not determine disk usage for $description"
        return 1
    fi
    
    log "Disk usage for $description: ${usage}%"
    
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

# Error handling with exit
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Error handling that allows continuation
error_continue() {
    log "ERROR: $1 - continuing with remaining operations"
}

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
        if mountpoint -q "$EXTERNAL_MOUNT"; then
            device_found=true
        fi
    fi
    
    echo "$device_found"
}

# Check if external drive is mounted and accessible
is_external_drive_mounted() {
    if mountpoint -q "$EXTERNAL_MOUNT" && [[ -w "$EXTERNAL_MOUNT" ]]; then
        return 0
    else
        return 1
    fi
}

# Get the most recent snapshot for incremental backups
get_latest_snapshot() {
    local subvol_name="$1"
    local pattern="$2"
    find "$SNAPSHOT_DIR/$subvol_name" -maxdepth 1 -name "${pattern}_*" -type d 2>/dev/null | sort | tail -1
}

# Create incremental daily snapshot
create_daily_snapshot() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_snapshots=()
    
    # Check local disk space before creating snapshots
    check_and_warn_disk_space "$BTRFS_POOL" "BTRFS pool"
    
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local path="${subvol_entry##*:}"
        local snapshot_name="daily_${timestamp}"
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
        
        # Find the most recent daily snapshot for incremental backup
        local parent_daily=$(get_latest_snapshot "$name" "daily")
        
        log "Creating incremental daily snapshot for $name: $snapshot_name"
        if [[ -n "$parent_daily" ]]; then
            log "Using parent snapshot: $(basename "$parent_daily")"
        else
            log "Creating first snapshot for $name (no parent found)"
        fi
        
        if ! execute_command "btrfs subvolume snapshot -r '$path' '$snapshot_path'" \
                            "Create daily snapshot $snapshot_name for $name subvolume" "true"; then
            failed_snapshots+=("$name")
        else
            # Verify the snapshot was created successfully
            if verify_backup "$snapshot_path" "$name daily snapshot"; then
                log "Daily snapshot verification successful for $name"
            else
                log "WARNING: Daily snapshot verification failed for $name"
            fi
        fi
    done
    
    # Report any failures
    if [[ ${#failed_snapshots[@]} -gt 0 ]]; then
        log "WARNING: Failed to create daily snapshots for: ${failed_snapshots[*]}"
    else
        log "All daily snapshots created successfully"
    fi
}

# Create weekly snapshot
create_weekly_snapshot() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_snapshots=()
    
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local path="${subvol_entry##*:}"
        local snapshot_name="weekly_${timestamp}"
        local snapshot_path="$SNAPSHOT_DIR/$name/$snapshot_name"
        local snapshot_subdir="$SNAPSHOT_DIR/$name"
        
        # Ensure the subdirectory exists
        if [[ ! -d "$snapshot_subdir" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD CREATE: snapshot subdirectory $snapshot_subdir"
            else
                if ! mkdir -p "$snapshot_subdir"; then
                    error_continue "Failed to create snapshot subdirectory: $snapshot_subdir"
                    failed_snapshots+=("$name")
                    continue
                fi
            fi
        fi
        
        log "Creating weekly snapshot for $name: $snapshot_name"
        
        if ! execute_command "btrfs subvolume snapshot -r '$path' '$snapshot_path'" \
                            "Create weekly snapshot $snapshot_name for $name subvolume" "true"; then
            failed_snapshots+=("$name")
        else
            if verify_backup "$snapshot_path" "$name weekly snapshot"; then
                log "Weekly snapshot verification successful for $name"
            else
                log "WARNING: Weekly snapshot verification failed for $name"
            fi
        fi
    done
    
    # Report any failures
    if [[ ${#failed_snapshots[@]} -gt 0 ]]; then
        log "WARNING: Failed to create weekly snapshots for: ${failed_snapshots[*]}"
    else
        log "All weekly snapshots created successfully"
    fi
}

# Generic cleanup function for snapshots
cleanup_snapshots_by_type() {
    local snapshot_type="$1"
    local retention_days="$2"
    local description="$3"
    
    log "Cleaning up $snapshot_type snapshots older than $retention_days days ($description)"
    
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_dir="$SNAPSHOT_DIR/$name"
        
        if [[ ! -d "$subvol_dir" ]]; then
            continue
        fi
        
        log "Checking for old $snapshot_type snapshots in $subvol_dir"
        
        local snapshots_to_delete=()
        local current_time=$(date +%s)
        local retention_seconds=$((retention_days * 86400))
        
        # Find all snapshots of this type and check their age
        while IFS= read -r snapshot; do
            if [[ -n "$snapshot" ]]; then
                local snapshot_name=$(basename "$snapshot")
                
                # Extract timestamp from snapshot name (format: type_YYYYMMDD_HHMMSS)
                if [[ $snapshot_name =~ ${snapshot_type}_([0-9]{8})_([0-9]{6}) ]]; then
                    local date_part="${BASH_REMATCH[1]}"
                    local time_part="${BASH_REMATCH[2]}"
                    
                    # Convert to timestamp format that date can parse
                    local year="${date_part:0:4}"
                    local month="${date_part:4:2}"
                    local day="${date_part:6:2}"
                    local hour="${time_part:0:2}"
                    local minute="${time_part:2:2}"
                    local second="${time_part:4:2}"
                    
                    # Get the timestamp of when this snapshot was created
                    local snapshot_timestamp=$(date -d "$year-$month-$day $hour:$minute:$second" +%s 2>/dev/null || echo "0")
                    
                    if [[ $snapshot_timestamp -gt 0 ]]; then
                        local age_seconds=$((current_time - snapshot_timestamp))
                        local age_days=$((age_seconds / 86400))
                        
                        log "Snapshot $snapshot_name: created $(date -d "@$snapshot_timestamp"), age: $age_days days"
                        
                        if [[ $age_seconds -gt $retention_seconds ]]; then
                            snapshots_to_delete+=("$snapshot")
                            log "Will delete: $snapshot_name (older than $retention_days days)"
                        else
                            log "Will keep: $snapshot_name (within retention period)"
                        fi
                    else
                        log "Could not parse timestamp from $snapshot_name, skipping"
                    fi
                else
                    log "Snapshot name $snapshot_name doesn't match expected format, skipping"
                fi
            fi
        done < <(find "$subvol_dir" -maxdepth 1 -name "${snapshot_type}_*" -type d 2>/dev/null || true)
        
        if [[ ${#snapshots_to_delete[@]} -eq 0 ]]; then
            log "No old $snapshot_type snapshots to clean up for $name"
        else
            for snapshot in "${snapshots_to_delete[@]}"; do
                execute_command "btrfs subvolume delete '$snapshot'" \
                               "Remove old $snapshot_type snapshot $(basename "$snapshot") for $name" "true"
            done
        fi
    done
}

# Clean up old daily snapshots
cleanup_daily_snapshots() {
    cleanup_snapshots_by_type "daily" "$DAILY_KEEP_DAYS" "retention: $DAILY_KEEP_DAYS days"
}

# Clean up old weekly snapshots
cleanup_weekly_snapshots() {
    local keep_weeks_days=$((WEEKLY_KEEP_WEEKS * 7))
    cleanup_snapshots_by_type "weekly" "$keep_weeks_days" "retention: $WEEKLY_KEEP_WEEKS weeks"
}

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

# Create incremental external backup (weekly)
create_weekly_external_backup() {
    if ! is_external_drive_mounted; then
        log "External drive not mounted - skipping weekly backup"
        return 0
    fi
    
    setup_external_backup_dir
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_backups=()
    
    # Check external drive disk space
    check_and_warn_disk_space "$EXTERNAL_MOUNT" "External drive"
    
    # Verify external drive is BTRFS
    if ! btrfs filesystem show "$EXTERNAL_MOUNT" >/dev/null 2>&1; then
        log "ERROR: External drive is not a BTRFS filesystem or not properly mounted"
        log "External backup requires BTRFS filesystem for btrfs send/receive"
        return 1
    fi
    
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local backup_name="weekly_backup_${timestamp}"
        local backup_path="$EXTERNAL_BACKUP_DIR/$name/$backup_name"
        
        log "Creating weekly external backup for $name: $backup_name"
        
        # Find the most recent weekly snapshot for this subvolume
        local latest_weekly=$(get_latest_snapshot "$name" "weekly")
        
        if [[ -z "$latest_weekly" ]]; then
            log "No weekly snapshot found for $name backup - skipping"
            failed_backups+=("$name")
            continue
        fi
        
        log "Using snapshot for $name backup: $(basename "$latest_weekly")"
        
        # Find parent for incremental backup - must be a valid subvolume
        local parent_backup=""
        local potential_parents=($(find "$EXTERNAL_BACKUP_DIR/$name" -maxdepth 1 -name "*_backup_*" -type d 2>/dev/null | sort -r))
        
        for potential_parent in "${potential_parents[@]}"; do
            if btrfs subvolume show "$potential_parent" >/dev/null 2>&1; then
                parent_backup="$potential_parent"
                log "Found valid parent backup: $(basename "$parent_backup")"
                break
            else
                log "Skipping invalid parent backup: $(basename "$potential_parent")"
            fi
        done
        
        if [[ -n "$parent_backup" ]]; then
            # For incremental backup, we need to find the corresponding local snapshot
            # that was used to create the parent backup
            local parent_backup_name=$(basename "$parent_backup")
            local parent_timestamp=""
            
            # Extract timestamp from parent backup name (format: weekly_backup_YYYYMMDD_HHMMSS)
            if [[ $parent_backup_name =~ weekly_backup_([0-9]{8})_([0-9]{6}) ]]; then
                local date_part="${BASH_REMATCH[1]}"
                local time_part="${BASH_REMATCH[2]}"
                parent_timestamp="${date_part}_${time_part}"
            fi
            
            local local_parent=""
            if [[ -n "$parent_timestamp" ]]; then
                local_parent="/mnt/btr_pool/.snapshots/$name/weekly_${parent_timestamp}"
                if [[ -d "$local_parent" ]] && btrfs subvolume show "$local_parent" >/dev/null 2>&1; then
                    log "Found corresponding local parent snapshot: $(basename "$local_parent")"
                else
                    log "Local parent snapshot not found: $local_parent"
                    local_parent=""
                fi
            fi
            
            if [[ -n "$local_parent" ]]; then
                log "Creating incremental backup for $name using local parent: $(basename "$local_parent")"
                if [[ "$DRY_RUN" == "true" ]]; then
                    log "WOULD EXECUTE: btrfs send -p '$local_parent' '$latest_weekly' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
                    log "WOULD RENAME: received snapshot to $backup_name"
                else
                    # Create incremental backup using local parent
                    local send_cmd="btrfs send -p '$local_parent' '$latest_weekly'"
                    local receive_cmd="btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
                    
                    log "Executing incremental send/receive for $name"
                    if eval "$send_cmd" | eval "$receive_cmd"; then
                        local received_name=$(basename "$latest_weekly")
                        local received_path="$EXTERNAL_BACKUP_DIR/$name/$received_name"
                        
                        # Check if received snapshot exists before renaming
                        if [[ -d "$received_path" ]]; then
                            if mv "$received_path" "$backup_path"; then
                                log "Successfully created incremental weekly backup for $name: $backup_path"
                                verify_backup "$backup_path" "$name weekly backup"
                            else
                                error_continue "Failed to rename weekly backup for $name from $received_path to $backup_path"
                                failed_backups+=("$name")
                            fi
                        else
                            error_continue "Received snapshot not found at expected path: $received_path"
                            failed_backups+=("$name")
                        fi
                    else
                        log "Incremental backup failed for $name, attempting full backup instead"
                        local_parent=""  # Force full backup
                    fi
                fi
            else
                log "No valid local parent found for incremental backup, will create full backup"
                local_parent=""
            fi
        fi
        
        # Create full backup if no parent or incremental failed
        if [[ -z "$parent_backup" ]] || [[ -z "$local_parent" ]]; then
            log "Creating full backup for $name (no valid parent found)"
            if [[ "$DRY_RUN" == "true" ]]; then
                log "WOULD EXECUTE: btrfs send '$latest_weekly' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
                log "WOULD RENAME: received snapshot to $backup_name"
            else
                local send_cmd="btrfs send '$latest_weekly'"
                local receive_cmd="btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
                
                log "Executing full send/receive for $name"
                if eval "$send_cmd" | eval "$receive_cmd"; then
                    local received_name=$(basename "$latest_weekly")
                    local received_path="$EXTERNAL_BACKUP_DIR/$name/$received_name"
                    
                    # Check if received snapshot exists before renaming
                    if [[ -d "$received_path" ]]; then
                        if mv "$received_path" "$backup_path"; then
                            log "Successfully created full weekly backup for $name: $backup_path"
                            verify_backup "$backup_path" "$name weekly backup"
                        else
                            error_continue "Failed to rename full weekly backup for $name"
                            failed_backups+=("$name")
                        fi
                    else
                        error_continue "Received snapshot not found at expected path: $received_path"
                        failed_backups+=("$name")
                    fi
                else
                    error_continue "Failed to create full weekly backup for $name"
                    failed_backups+=("$name")
                fi
            fi
        fi
    done
    
    # Report any failures
    if [[ ${#failed_backups[@]} -gt 0 ]]; then
        log "WARNING: Failed to create weekly backups for: ${failed_backups[*]}"
    else
        log "All weekly external backups created successfully"
    fi
}

# Create full monthly backup
create_monthly_backup() {
    if ! is_external_drive_mounted; then
        log "External drive not mounted - skipping monthly backup"
        return 0
    fi
    
    setup_external_backup_dir
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local failed_backups=()
    
    # Check external drive disk space
    check_and_warn_disk_space "$EXTERNAL_MOUNT" "External drive"
    
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local path="${subvol_entry##*:}"
        local backup_name="monthly_backup_${timestamp}"
        local backup_path="$EXTERNAL_BACKUP_DIR/$name/$backup_name"
        local temp_snapshot="$SNAPSHOT_DIR/$name/temp_monthly_${timestamp}"
        
        log "Creating monthly full backup for $name: $backup_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "WOULD CREATE: temporary read-only snapshot $temp_snapshot"
            log "WOULD EXECUTE: btrfs send '$temp_snapshot' | btrfs receive '$EXTERNAL_BACKUP_DIR/$name'"
            log "WOULD RENAME: received snapshot to $backup_name"
            log "WOULD DELETE: temporary snapshot $temp_snapshot"
        else
            # Create temporary read-only snapshot for sending
            log "Creating temporary read-only snapshot: $temp_snapshot"
            if btrfs subvolume snapshot -r "$path" "$temp_snapshot"; then
                log "Successfully created temporary snapshot: $temp_snapshot"
                
                # Send the temporary snapshot to external drive
                if btrfs send "$temp_snapshot" | btrfs receive "$EXTERNAL_BACKUP_DIR/$name"; then
                    local received_name=$(basename "$temp_snapshot")
                    if mv "$EXTERNAL_BACKUP_DIR/$name/$received_name" "$backup_path"; then
                        log "Successfully created monthly backup for $name: $backup_path"
                        verify_backup "$backup_path" "$name monthly backup"
                        
                        # Clean up temporary snapshot
                        if btrfs subvolume delete "$temp_snapshot"; then
                            log "Cleaned up temporary snapshot: $temp_snapshot"
                        else
                            log "WARNING: Failed to delete temporary snapshot: $temp_snapshot"
                        fi
                    else
                        error_continue "Failed to rename monthly backup for $name"
                        failed_backups+=("$name")
                        # Clean up temporary snapshot on failure
                        btrfs subvolume delete "$temp_snapshot" || true
                    fi
                else
                    error_continue "Failed to send monthly backup for $name"
                    failed_backups+=("$name")
                    # Clean up temporary snapshot on failure
                    btrfs subvolume delete "$temp_snapshot" || true
                fi
            else
                error_continue "Failed to create temporary snapshot for $name"
                failed_backups+=("$name")
            fi
        fi
    done
    
    # Report any failures
    if [[ ${#failed_backups[@]} -gt 0 ]]; then
        log "WARNING: Failed to create monthly backups for: ${failed_backups[*]}"
    else
        log "All monthly backups created successfully"
    fi
}

# Generic cleanup function for external backups
cleanup_external_backups_by_type() {
    local backup_type="$1"
    local retention_days="$2"
    local description="$3"
    
    if ! is_external_drive_mounted; then
        return 0
    fi
    
    log "Cleaning up $backup_type external backups older than $retention_days days ($description)"
    
    for subvol_entry in "${SUBVOLUMES[@]}"; do
        local name="${subvol_entry%%:*}"
        local subvol_backup_dir="$EXTERNAL_BACKUP_DIR/$name"
        
        if [[ ! -d "$subvol_backup_dir" ]]; then
            continue
        fi
        
        log "Checking for old $backup_type backups in $subvol_backup_dir"
        
        local backups_to_delete=()
        local current_time=$(date +%s)
        local retention_seconds=$((retention_days * 86400))
        
        # Find all backups of this type and check their age
        while IFS= read -r backup; do
            if [[ -n "$backup" ]]; then
                local backup_name=$(basename "$backup")
                
                # Extract timestamp from backup name (format: type_backup_YYYYMMDD_HHMMSS)
                if [[ $backup_name =~ ${backup_type}_backup_([0-9]{8})_([0-9]{6}) ]]; then
                    local date_part="${BASH_REMATCH[1]}"
                    local time_part="${BASH_REMATCH[2]}"
                    
                    # Convert to timestamp format that date can parse
                    local year="${date_part:0:4}"
                    local month="${date_part:4:2}"
                    local day="${date_part:6:2}"
                    local hour="${time_part:0:2}"
                    local minute="${time_part:2:2}"
                    local second="${time_part:4:2}"
                    
                    # Get the timestamp of when this backup was created
                    local backup_timestamp=$(date -d "$year-$month-$day $hour:$minute:$second" +%s 2>/dev/null || echo "0")
                    
                    if [[ $backup_timestamp -gt 0 ]]; then
                        local age_seconds=$((current_time - backup_timestamp))
                        local age_days=$((age_seconds / 86400))
                        
                        log "Backup $backup_name: created $(date -d "@$backup_timestamp"), age: $age_days days"
                        
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
        done < <(find "$subvol_backup_dir" -maxdepth 1 -name "${backup_type}_backup_*" -type d 2>/dev/null || true)
        
        if [[ ${#backups_to_delete[@]} -eq 0 ]]; then
            log "No old $backup_type external backups to clean up for $name"
        else
            for backup in "${backups_to_delete[@]}"; do
                execute_command "btrfs subvolume delete '$backup'" \
                               "Remove old $backup_type backup $(basename "$backup") for $name" "true"
            done
        fi
    done
}

# Clean up old weekly external backups (called after monthly backup)
cleanup_weekly_external_backups() {
    local keep_weeks_days=$((WEEKLY_KEEP_WEEKS * 7))
    cleanup_external_backups_by_type "weekly" "$keep_weeks_days" "retention: $WEEKLY_KEEP_WEEKS weeks"
}

# Clean up old monthly external backups
cleanup_monthly_external_backups() {
    local keep_months_days=$((MONTHLY_KEEP_MONTHS * 30))
    cleanup_external_backups_by_type "monthly" "$keep_months_days" "retention: $MONTHLY_KEEP_MONTHS months"
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    daily     Create incremental daily snapshots and cleanup old daily snapshots
    weekly    Create weekly snapshots and external backup (if drive available)
    monthly   Create monthly full backup to external drive (if available)
    cleanup   Only perform cleanup operations
    status    Show snapshot and backup status
    help      Display this help message

Options:
    --dry-run    Show what would be done without executing any commands

Examples:
    $0 daily --dry-run           # Preview daily snapshot routine
    $0 weekly --dry-run          # Preview weekly snapshot and backup routine
    $0 monthly --dry-run         # Preview monthly backup routine
    $0 cleanup --dry-run         # Preview cleanup operations
    $0 status                    # Show current status (always safe)

If no command is specified, 'daily' is assumed.

Three-Tier Backup Strategy:
- Daily: Local incremental snapshots (retention: $DAILY_KEEP_DAYS days)
- Weekly: Local snapshots + external incremental backups (retention: $WEEKLY_KEEP_WEEKS weeks)
- Monthly: Full external backups (retention: $MONTHLY_KEEP_MONTHS months)

Configuration:
- Edit DAILY_KEEP_DAYS to change daily snapshot retention
- Edit WEEKLY_KEEP_WEEKS to change weekly snapshot retention
- Edit MONTHLY_KEEP_MONTHS to change monthly backup retention
- External backups only run when drive is connected and mounted
EOF
}

# Show status of snapshots and backups
show_status() {
    echo "=== BTRFS Multi-Subvolume Snapshot Status ==="
    echo "Version: v69-improved (Enhanced with Better Error Handling and Weekly Support)"
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
            local daily_count=$(find "$subvol_dir" -name "daily_*" -type d 2>/dev/null | wc -l)
            local weekly_count=$(find "$subvol_dir" -name "weekly_*" -type d 2>/dev/null | wc -l)
            
            echo "    Daily snapshots: $daily_count"
            if [[ $daily_count -gt 0 ]]; then
                local latest_daily=$(find "$subvol_dir" -name "daily_*" -type d 2>/dev/null | sort | tail -1)
                echo "      Latest: $(basename "$latest_daily" 2>/dev/null || echo "none")"
            fi
            
            echo "    Weekly snapshots: $weekly_count"
            if [[ $weekly_count -gt 0 ]]; then
                local latest_weekly=$(find "$subvol_dir" -name "weekly_*" -type d 2>/dev/null | sort | tail -1)
                echo "      Latest: $(basename "$latest_weekly" 2>/dev/null || echo "none")"
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
                local weekly_backup_count=$(find "$backup_dir" -name "weekly_backup_*" -type d 2>/dev/null | wc -l)
                local monthly_backup_count=$(find "$backup_dir" -name "monthly_backup_*" -type d 2>/dev/null | wc -l)
                
                echo "    Weekly backups: $weekly_backup_count"
                if [[ $weekly_backup_count -gt 0 ]]; then
                    local latest_weekly_backup=$(find "$backup_dir" -name "weekly_backup_*" -type d 2>/dev/null | sort | tail -1)
                    echo "      Latest: $(basename "$latest_weekly_backup" 2>/dev/null || echo "none")"
                fi
                
                echo "    Monthly backups: $monthly_backup_count"
                if [[ $monthly_backup_count -gt 0 ]]; then
                    local latest_monthly_backup=$(find "$backup_dir" -name "monthly_backup_*" -type d 2>/dev/null | sort | tail -1)
                    echo "      Latest: $(basename "$latest_monthly_backup" 2>/dev/null || echo "none")"
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
    echo "  Daily retention: $DAILY_KEEP_DAYS days"
    echo "  Weekly retention: $WEEKLY_KEEP_WEEKS weeks"
    echo "  Monthly retention: $MONTHLY_KEEP_MONTHS months"
    echo "  Disk space warning threshold: ${DISK_SPACE_WARNING_THRESHOLD}%"
    echo "  Disk space critical threshold: ${DISK_SPACE_CRITICAL_THRESHOLD}%"
    echo "  Backup verification: $([ "$BACKUP_VERIFICATION_ENABLED" == "true" ] && echo "Enabled" || echo "Disabled")"
    echo
    echo "Log file: $LOG_FILE"
}

# Parse command line arguments
parse_arguments() {
    # Parse all arguments
    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                DRY_RUN="true"
                ;;
            daily|weekly|monthly|cleanup|status|help)
                COMMAND="$arg"
                ;;
            *)
                if [[ -n "$arg" ]]; then
                    echo "Unknown argument: $arg" >&2
                    usage
                    exit 1
                fi
                ;;
        esac
    done
    
    # Set defaults
    COMMAND=${COMMAND:-daily}
    
    # Debug output to stderr so it doesn't interfere with command output
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DEBUG: Dry-run mode enabled" >&2
    fi
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Show dry-run status
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "=== DRY-RUN MODE - No changes will be made ==="
        echo
    fi
    
    # Status doesn't need root or subvolume checks
    if [[ "$COMMAND" == "status" ]]; then
        show_status
        return 0
    fi
    
    # Help doesn't need root or subvolume checks
    if [[ "$COMMAND" == "help" ]]; then
        usage
        return 0
    fi
    
    # All other commands need root and subvolume verification
    check_root
    ensure_snapshot_dir
    check_subvolumes
    
    case "$COMMAND" in
        daily)
            log "Starting daily snapshot routine"
            create_daily_snapshot
            cleanup_daily_snapshots
            log "Daily snapshot routine completed"
            ;;
        weekly)
            log "Starting weekly snapshot and backup routine"
            create_weekly_snapshot
            create_weekly_external_backup
            cleanup_weekly_snapshots
            log "Weekly routine completed"
            ;;
        monthly)
            log "Starting monthly backup routine"
            create_monthly_backup
            cleanup_monthly_external_backups
            # Clean up weekly backups after successful monthly backup
            cleanup_weekly_external_backups
            log "Monthly backup routine completed"
            ;;
        cleanup)
            log "Starting cleanup routine"
            cleanup_daily_snapshots
            cleanup_weekly_snapshots
            if is_external_drive_mounted; then
                cleanup_weekly_external_backups
                cleanup_monthly_external_backups
            fi
            log "Cleanup routine completed"
            ;;
        *)
            echo "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo
        echo "=== DRY-RUN COMPLETED - No actual changes were made ==="
        echo "Run without --dry-run to execute the operations shown above."
    fi
}

# Run main function with all arguments
main "$@"
