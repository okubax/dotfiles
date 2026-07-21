#!/bin/bash
# godaddy-server-backup.sh
# Mirror the whole GoDaddy/cPanel server home (~/) to a local directory that is
# itself already covered by this machine's snapshot/offline backups.
#
# Pulls the remote home via rsync over SSH using key auth from the running
# ssh-agent (no passwords). Skips data this machine already holds -- configured
# per-machine via EXTRA_EXCLUDES in the config file -- plus server-side caches
# and cPanel/CloudLinux machinery. Because the mirror lands inside a directory
# your own backups already capture, there are no per-run archives or retention
# to manage here; history lives in those backups.
#
# Config file: ~/.config/godaddy_backup.conf   (keeps host/user OUT of this script)
#     SERVER_USER        remote ssh user                              (required)
#     SERVER_HOST        remote host                                  (required)
#     LOCAL_BACKUP_DIR   local directory to mirror into (created if missing)
#     SSH_PRIVATE_KEY    optional ssh identity file
#     EXTRA_EXCLUDES     bash array of extra rsync excludes (machine-specific,
#                        e.g. Nextcloud data, a private repo cloned locally,
#                        DB dumps pulled here by another job)
#
# Usage: godaddy-server-backup.sh [options]
#     -n, --dry-run      Preview what rsync would transfer; write/delete nothing
#     -v, --verbose      Show per-file progress
#     -h, --help         Show this help
#
# Auth note: the key is used via the ssh-agent. If it lives in a desktop
# (gcr/gnome-keyring) agent, this script reuses that socket, so the key must be
# unlocked in your session for an unattended run to succeed.

set -o pipefail

readonly CONFIG_FILE="${GODADDY_BACKUP_CONFIG:-$HOME/.config/godaddy_backup.conf}"
readonly LOCK_FILE="/tmp/godaddy_backup.lock"

# Colours
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
log()         { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Defaults (overridable by config / env)
SERVER_USER=""
SERVER_HOST=""
LOCAL_BACKUP_DIR="$HOME/backups/godaddy-server"
SSH_PRIVATE_KEY=""
EXTRA_EXCLUDES=()

DRY_RUN=false
VERBOSE=false

# Generic, non-sensitive excludes (safe to publish). Anything machine-specific
# belongs in EXTRA_EXCLUDES in the config file, not here.
readonly DEFAULT_EXCLUDES=(
    '.cache'
    '/cache' '/tmp' '/.tmp'
    '/logs' '/access-logs'
    '/.trash' '/.quarantine' '/.sucuriquarantine'
    '/.cpanel' '/.cphorde' '/.cagefs' '/.cl.selector' '/.clwpos'
)

usage() { sed -n '/^# Usage:/,/^# *-h/{s/^# \{0,1\}//p}' "$0"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=true ;;
            -v|--verbose) VERBOSE=true ;;
            -h|--help)    usage; exit 0 ;;
            *) log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        log_warning "No config file at $CONFIG_FILE; relying on environment."
    fi
    SERVER_USER="${GODADDY_USER:-$SERVER_USER}"
    SERVER_HOST="${GODADDY_HOST:-$SERVER_HOST}"
    LOCAL_BACKUP_DIR="${GODADDY_BACKUP_DIR:-$LOCAL_BACKUP_DIR}"
}

# Reuse an existing agent; else fall back to a desktop gcr/keyring socket.
resolve_agent() {
    [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK:-}" ]] && return 0
    local rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local sock
    for sock in "$rt/gcr/.ssh" "$rt/keyring/ssh" "$rt/gcr/ssh"; do
        [[ -S "$sock" ]] && { export SSH_AUTH_SOCK="$sock"; return 0; }
    done
}

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid; pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_error "Another backup is running (PID $pid). Remove $LOCK_FILE if stale."
            exit 1
        fi
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}
release_lock() { [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE"; }
trap release_lock EXIT

build_ssh_cmd() {
    local cmd="ssh -o BatchMode=yes -o ConnectTimeout=30 -o LogLevel=ERROR"
    [[ -n "$SSH_PRIVATE_KEY" ]] && cmd="$cmd -i $SSH_PRIVATE_KEY"
    printf '%s' "$cmd"
}

run_backup() {
    local dest="$LOCAL_BACKUP_DIR"
    local ssh_cmd; ssh_cmd="$(build_ssh_cmd)"

    log "Testing SSH connection to $SERVER_HOST ..."
    if ! $ssh_cmd "$SERVER_USER@$SERVER_HOST" exit 2>/dev/null; then
        log_error "SSH connection/auth failed. Is your key loaded in the agent?"
        exit 1
    fi
    log_success "SSH OK."

    local -a excludes=() e
    for e in "${DEFAULT_EXCLUDES[@]}" "${EXTRA_EXCLUDES[@]}"; do
        excludes+=( "--exclude=$e" )
    done

    local -a opts=( -az --delete --partial -h --info=stats1 )
    [[ "$VERBOSE" == true ]] && opts+=( -v --progress )
    [[ "$DRY_RUN"  == true ]] && opts+=( --dry-run )

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY RUN: previewing $SERVER_USER@$SERVER_HOST:~/  (nothing written)"
    else
        log "Mirroring $SERVER_USER@$SERVER_HOST:~/  ->  $dest"
        mkdir -p "$dest"
    fi

    rsync "${opts[@]}" -e "$ssh_cmd" "${excludes[@]}" \
        "$SERVER_USER@$SERVER_HOST:./" "$dest/"
    local rc=$?

    case $rc in
        0)  [[ "$DRY_RUN" == true ]] && log_success "Dry run complete." \
                                     || log_success "Mirror complete -> $dest" ;;
        24) log_warning "rsync rc=24: some source files vanished mid-transfer (normal on a live server)." ;;
        *)  log_error "rsync failed (rc=$rc)."; exit "$rc" ;;
    esac
}

main() {
    parse_args "$@"
    load_config
    resolve_agent
    if [[ -z "$SERVER_USER" || -z "$SERVER_HOST" ]]; then
        log_error "SERVER_USER/SERVER_HOST not set (config: $CONFIG_FILE)."
        exit 1
    fi
    [[ "$DRY_RUN" == false ]] && acquire_lock
    run_backup
    log_success "Done."
}

main "$@"
