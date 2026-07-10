#!/bin/bash
# backup_godaddy.sh - Password-Auth Friendly Version
# Focused GoDaddy Shared Hosting File Backup Script
#
# Rsyncs public_html from the GoDaddy server to a local dated backup,
# compresses it, and prunes backups older than RETENTION_DAYS.
# Connection details come from ~/.config/godaddy_backup.conf or
# GODADDY_USER/GODADDY_HOST/GODADDY_BACKUP_DIR environment variables.
#
# Usage: backup_godaddy.sh [options]
#   -d, --dry-run      Preview what rsync would transfer; nothing is
#                      written, compressed or deleted
#   -s, --skip-test    Skip the SSH connection test (one fewer password prompt)
#   -e, --no-compress  Keep the backup as a plain folder (skip tar.gz, faster)
#   -v, --verbose      Show per-file rsync progress
#   -h, --help         Show usage

set -o pipefail

# --- Configuration ---
readonly CONFIG_FILE="${GODADDY_BACKUP_CONFIG:-$HOME/.config/godaddy_backup.conf}"
readonly LOCK_FILE="/tmp/godaddy_backup.lock"
readonly SCRIPT_NAME="$(basename "$0")"

SERVER_USER=""
SERVER_HOST=""
LOCAL_BACKUP_DIR=""
USE_PASSWORD_AUTH="true" # Forced to true for your use case

readonly DATE=$(date +%Y%m%d_%H%M%S)
readonly BACKUP_NAME="godaddy_backup_$DATE"
BACKUP_PATH=""

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

VERBOSE=false
DRY_RUN=false
SKIP_TEST=false
COMPRESS=true
RETENTION_DAYS=30

# --- Functions ---

usage() {
    sed -n '/^# Usage:/,/^# *-h/{s/^# \{0,1\}//p}' "$0"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)     DRY_RUN=true ;;
            -s|--skip-test)   SKIP_TEST=true ;;
            -e|--no-compress) COMPRESS=false ;;
            -v|--verbose)     VERBOSE=true ;;
            -h|--help)        usage; exit 0 ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        [[ -n "$GODADDY_USER" ]] && SERVER_USER="$GODADDY_USER"
        [[ -n "$GODADDY_HOST" ]] && SERVER_HOST="$GODADDY_HOST"
        [[ -n "$GODADDY_BACKUP_DIR" ]] && LOCAL_BACKUP_DIR="$GODADDY_BACKUP_DIR"
    else
        SERVER_USER="${GODADDY_USER:-}"
        SERVER_HOST="${GODADDY_HOST:-}"
        LOCAL_BACKUP_DIR="${GODADDY_BACKUP_DIR:-$HOME/Projects/sites/backups/godaddy}"
    fi
    BACKUP_PATH="$LOCAL_BACKUP_DIR/$BACKUP_NAME"
}

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another backup is already running (PID: $lock_pid). Remove $LOCK_FILE if stale."
            return 1
        fi
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() { rm -f "$LOCK_FILE"; }
trap release_lock EXIT

test_connection() {
    log "Testing SSH connection to $SERVER_HOST (Password prompt may appear)..."
    # Added LogLevel=QUIET to hide the Post-Quantum warnings
    # Removed -n and timeout to allow manual password entry
    if ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o LogLevel=QUIET "$SERVER_USER@$SERVER_HOST" exit; then
        log_success "SSH connection successful."
        return 0
    else
        log_error "Connection failed. Please check your password."
        return 1
    fi
}

backup_files() {
    if [[ "$DRY_RUN" == true ]]; then
        log "DRY RUN: listing what rsync would transfer (nothing is written)..."
    else
        log "Starting rsync transfer..."
        mkdir -p "$BACKUP_PATH/files"
    fi

    # Define SSH command for rsync (shuts up warnings)
    local ssh_cmd="ssh -o LogLevel=QUIET"

    local rsync_opts="-avz"
    [[ "$VERBOSE" == true ]] && rsync_opts="$rsync_opts --progress"
    [[ "$DRY_RUN" == true ]] && rsync_opts="$rsync_opts --dry-run"

    local excludes=("--exclude=*.zip" "--exclude=*.tar.gz" "--exclude=mail/" "--exclude=mysql/")

    # We don't pipe to tee here because tee hides the password prompt from the user
    rsync $rsync_opts -e "$ssh_cmd" "${excludes[@]}" \
        "$SERVER_USER@$SERVER_HOST:public_html/" \
        "$BACKUP_PATH/files/"

    if [[ $? -eq 0 ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_success "Dry run finished - no files were written."
        else
            log_success "Files transferred successfully."
        fi
    else
        log_error "Rsync encountered an error."
    fi
}

compress_backup() {
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi
    if [[ "$COMPRESS" == "true" ]]; then
        log "Compressing backup..."
        cd "$LOCAL_BACKUP_DIR" && tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
        rm -rf "$BACKUP_NAME"
        log_success "Backup saved as ${BACKUP_NAME}.tar.gz"
    else
        log "Skipping compression (--no-compress); backup left in $BACKUP_PATH"
    fi
}

cleanup_old() {
    if [[ "$DRY_RUN" == true ]]; then
        log "DRY RUN: backups older than $RETENTION_DAYS days that would be deleted:"
        find "$LOCAL_BACKUP_DIR" -name "godaddy_backup_*" -mtime +$RETENTION_DAYS 2>/dev/null || true
        return 0
    fi
    log "Cleaning backups older than $RETENTION_DAYS days..."
    find "$LOCAL_BACKUP_DIR" -name "godaddy_backup_*" -mtime +$RETENTION_DAYS -delete
}

main() {
    parse_args "$@"
    load_config

    if [[ -z "$SERVER_USER" || -z "$SERVER_HOST" ]]; then
        log_error "Missing SERVER_USER or SERVER_HOST in config/env."
        exit 1
    fi

    acquire_lock

    if [[ "$SKIP_TEST" == true ]]; then
        log "Skipping SSH connection test (--skip-test)."
    else
        test_connection || exit 1
    fi

    backup_files
    compress_backup
    cleanup_old
    log_success "Done!"
}

main "$@"
