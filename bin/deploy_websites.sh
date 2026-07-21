#!/bin/bash
# deploy_websites.sh - Website deployment script
# Usage: ./deploy_websites.sh [site_name] or ./deploy_websites.sh all

set -o pipefail

# Default configuration file location
readonly CONFIG_FILE="${DEPLOY_CONFIG:-$HOME/.config/deploy_websites.conf}"
readonly LOCK_FILE="/tmp/deploy_websites.lock"
readonly LOG_FILE="${DEPLOY_LOG_FILE:-$HOME/.local/log/deploy_websites.log}"
readonly SCRIPT_PID=$$

# Configuration with defaults (can be overridden by config file or env vars)
SERVER_USER="${DEPLOY_USER:-}"
SERVER_HOST="${DEPLOY_HOST:-}"
LOCAL_PROJECTS="${DEPLOY_LOCAL_DIR:-$HOME/Projects/sites}"
REMOTE_BASE="${DEPLOY_REMOTE_BASE:-public_html}"
SSH_KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/id_ed25519}"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Associative arrays for site configurations
declare -A SITE_LOCAL_PATHS
declare -A SITE_REMOTE_PATHS
declare -A SITE_EXCLUDES
declare -A SITE_PRE_HOOKS
declare -A SITE_POST_HOOKS
declare -A SITE_BUILD_CMDS

# Initialize log file
init_log() {
    local log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || true
    fi
}

# Logging function
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}${message}${NC}"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
}

error() {
    local message="[ERROR] $1"
    echo -e "${RED}${message}${NC}" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE" 2>/dev/null || true
}

success() {
    local message="[SUCCESS] $1"
    echo -e "${GREEN}${message}${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE" 2>/dev/null || true
}

warning() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}${message}${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# Load configuration from file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Validate config file permissions
        local perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null)
        if [[ "$perms" != "600" && "$perms" != "400" && "$perms" != "644" ]]; then
            warning "Config file $CONFIG_FILE has unusual permissions: $perms"
        fi

        log "Loading configuration from $CONFIG_FILE"
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"

        # Override with environment variables if set
        SERVER_USER="${DEPLOY_USER:-${SERVER_USER:-}}"
        SERVER_HOST="${DEPLOY_HOST:-${SERVER_HOST:-}}"
        LOCAL_PROJECTS="${DEPLOY_LOCAL_DIR:-${LOCAL_PROJECTS:-}}"
        REMOTE_BASE="${DEPLOY_REMOTE_BASE:-${REMOTE_BASE:-}}"
        SSH_KEY="${DEPLOY_SSH_KEY:-${SSH_KEY:-}}"
    else
        log "No config file found at $CONFIG_FILE, using defaults/environment variables"
    fi
}

# Load default site configurations if not in config file
load_default_sites() {
    # Only load defaults if no sites defined in config
    if [[ ${#SITE_LOCAL_PATHS[@]} -eq 0 ]]; then
        # Static sites built by a generator into <repo>/output (or _site).
        # SITE_BUILD_CMDS runs before the rsync; omit it for sites with no build.
        SITE_LOCAL_PATHS[site1]="$LOCAL_PROJECTS/site1/remote/_site"
        SITE_REMOTE_PATHS[site1]="$REMOTE_BASE"

        SITE_LOCAL_PATHS[site2]="$LOCAL_PROJECTS/site2/remote/output"
        SITE_REMOTE_PATHS[site2]="$REMOTE_BASE/site2.example.com"
        SITE_BUILD_CMDS[site2]="cd '$LOCAL_PROJECTS/site2/remote' && python3 ssg.py build"

        SITE_LOCAL_PATHS[site3]="$LOCAL_PROJECTS/site3/remote"
        SITE_REMOTE_PATHS[site3]="$REMOTE_BASE/site3.example.com"

        # A PHP app uploaded as-is; exclude patterns are neither uploaded nor
        # deleted, protecting server-owned runtime files from --with-delete
        SITE_LOCAL_PATHS[site4]="$LOCAL_PROJECTS/site4"
        SITE_REMOTE_PATHS[site4]="$REMOTE_BASE/site4.example.com"
        SITE_EXCLUDES[site4]="*.sql,.env,.git,.gitignore,cache,*.log"
    fi
}

# Validate configuration
validate_config() {
    local errors=0

    if [[ -z "$SERVER_USER" ]]; then
        error "SERVER_USER not set. Set via env var DEPLOY_USER or in $CONFIG_FILE"
        errors=1
    fi

    if [[ -z "$SERVER_HOST" ]]; then
        error "SERVER_HOST not set. Set via env var DEPLOY_HOST or in $CONFIG_FILE"
        errors=1
    fi

    if [[ -n "$SSH_KEY" ]] && [[ ! -f "$SSH_KEY" ]]; then
        warning "SSH key not found: $SSH_KEY (will use default SSH config)"
    fi

    return $errors
}

# Acquire lock to prevent simultaneous deployments
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            error "Another deployment is already running (PID: $lock_pid)"
            error "If this is incorrect, remove $LOCK_FILE"
            return 1
        else
            warning "Stale lock file found, removing..."
            rm -f "$LOCK_FILE"
        fi
    fi

    echo $$ > "$LOCK_FILE" || {
        error "Failed to create lock file: $LOCK_FILE"
        return 1
    }
    return 0
}

# Release lock file
release_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ "$lock_pid" == "$SCRIPT_PID" ]]; then
            rm -f "$LOCK_FILE"
        fi
    fi
}

# Cleanup function called on exit
cleanup_on_exit() {
    local exit_code=$?
    release_lock

    if [[ $exit_code -ne 0 ]]; then
        error "Script exited with error code: $exit_code"
    fi

    exit $exit_code
}

# Set up trap handlers
trap cleanup_on_exit EXIT
trap 'echo -e "\n${YELLOW}[WARNING]${NC} Interrupted by user" >&2; exit 130' INT TERM

# Check if rsync is available
check_dependencies() {
    if ! command -v rsync &> /dev/null; then
        error "rsync is not installed. Please install it first."
        exit 1
    fi

    # Fall back to the desktop keyring's ssh-agent when run without one
    # (e.g. from cron or a non-login shell) so the passphrase-protected
    # key can still be used
    local gcr_sock="/run/user/$(id -u)/gcr/ssh"
    if [[ -z "${SSH_AUTH_SOCK:-}" && -S "$gcr_sock" ]]; then
        export SSH_AUTH_SOCK="$gcr_sock"
        log "Using keyring ssh-agent: $gcr_sock"
    fi
}

# Test SSH connection
test_connection() {
    log "Testing SSH connection to $SERVER_HOST..."

    local ssh_opts="-o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no"
    if [[ -f "$SSH_KEY" ]]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi

    # More aggressive timeout settings
    if timeout 15s ssh $ssh_opts "$SERVER_USER@$SERVER_HOST" exit 2>/dev/null; then
        success "SSH connection successful"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            error "SSH connection timed out after 15 seconds"
        else
            error "Cannot connect to $SERVER_HOST. Please check your SSH configuration."
            warning "Try: ssh $SERVER_USER@$SERVER_HOST (to test manually)"
        fi
        return 1
    fi
}

# Run deployment hook if it exists
run_hook() {
    local hook_script="$1"
    local hook_name="$2"

    if [[ -n "$hook_script" ]]; then
        if [[ -f "$hook_script" && -x "$hook_script" ]]; then
            log "Running $hook_name hook: $hook_script"
            if "$hook_script"; then
                success "$hook_name hook completed successfully"
                return 0
            else
                error "$hook_name hook failed (exit code: $?)"
                return 1
            fi
        else
            warning "$hook_name hook not found or not executable: $hook_script"
        fi
    fi
    return 0
}

# Run the site's build command if one is defined
run_build() {
    local site_name="$1"
    local build_cmd="${SITE_BUILD_CMDS[$site_name]}"

    if [[ -n "$build_cmd" ]]; then
        log "Building $site_name: $build_cmd"
        if bash -c "$build_cmd"; then
            success "$site_name built successfully"
        else
            error "Build failed for $site_name (exit code: $?), aborting deployment"
            return 1
        fi
    fi
    return 0
}

# Deploy individual site
deploy_site() {
    local site_name="$1"
    local local_path="$2"
    local remote_path="$3"

    log "Deploying $site_name..."

    # Build the site first if a build command is defined
    if ! run_build "$site_name"; then
        return 1
    fi

    # Validate local directory
    if [ ! -d "$local_path" ]; then
        error "Local directory $local_path does not exist"
        return 1
    fi

    # Run pre-deployment hook if defined
    if ! run_hook "${SITE_PRE_HOOKS[$site_name]}" "pre-deployment"; then
        error "Pre-deployment hook failed for $site_name, aborting deployment"
        return 1
    fi

    # Build rsync options array (avoids eval + command injection)
    local rsync_opts=(-avz --progress)

    # Add SSH key if specified
    if [[ -f "$SSH_KEY" ]]; then
        rsync_opts+=(-e "ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15")
    fi

    # Add exclude patterns if defined
    if [[ -n "${SITE_EXCLUDES[$site_name]}" ]]; then
        local IFS=','
        for exclude in ${SITE_EXCLUDES[$site_name]}; do
            rsync_opts+=(--exclude="$exclude")
        done
    fi

    # Show what will be transferred
    log "Preparing to sync: $local_path -> $SERVER_USER@$SERVER_HOST:$remote_path"

    # WARNING: Removed --delete flag for safety
    # If you need to delete files, use deploy_site_with_delete function instead
    if [ "$DRY_RUN" = "true" ]; then
        warning "DRY RUN MODE - No files will be transferred"
        rsync "${rsync_opts[@]}" --dry-run "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
    else
        warning "SYNC MODE - Files will be added/updated but NOT deleted"
        rsync "${rsync_opts[@]}" "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"

        if [ $? -eq 0 ]; then
            success "$site_name deployed successfully"

            # Run post-deployment hook if defined
            if ! run_hook "${SITE_POST_HOOKS[$site_name]}" "post-deployment"; then
                warning "Post-deployment hook failed for $site_name (deployment succeeded)"
            fi

            return 0
        else
            error "Failed to deploy $site_name"
            return 1
        fi
    fi
}

# Separate function for deployments that need to delete files (USE WITH EXTREME CAUTION)
deploy_site_with_delete() {
    local site_name="$1"
    local local_path="$2"
    local remote_path="$3"
    
    warning "⚠️  DANGEROUS: This will DELETE files on server that don't exist locally!"
    read -p "Are you absolutely sure you want to delete remote files? (yes/NO): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Deployment cancelled - using safe sync instead"
        deploy_site "$site_name" "$local_path" "$remote_path"
        return
    fi
    
    log "Deploying $site_name WITH DELETE..."

    # Build the site first if a build command is defined
    if ! run_build "$site_name"; then
        return 1
    fi

    if [ ! -d "$local_path" ]; then
        error "Local directory $local_path does not exist"
        return 1
    fi

    # Honor the same excludes as deploy_site: excluded patterns are neither
    # uploaded NOR deleted on the server, which protects server-owned runtime
    # files (logs, caches) from --delete
    local rsync_opts=(-avz --progress --delete)

    if [[ -f "$SSH_KEY" ]]; then
        rsync_opts+=(-e "ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15")
    fi

    if [[ -n "${SITE_EXCLUDES[$site_name]}" ]]; then
        local IFS=','
        for exclude in ${SITE_EXCLUDES[$site_name]}; do
            rsync_opts+=(--exclude="$exclude")
        done
    fi

    # Show what will be transferred AND deleted
    log "Preparing to sync: $local_path -> $SERVER_USER@$SERVER_HOST:$remote_path"
    warning "Files on server that don't exist locally WILL BE DELETED"

    if [ "$DRY_RUN" = "true" ]; then
        warning "DRY RUN MODE - Showing what would be deleted/transferred"
        rsync "${rsync_opts[@]}" --dry-run "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
    else
        error "DANGER: Syncing with delete enabled!"
        rsync "${rsync_opts[@]}" "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
        
        if [ $? -eq 0 ]; then
            success "$site_name deployed successfully (with deletions)"
            return 0
        else
            error "Failed to deploy $site_name"
            return 1
        fi
    fi
}

# Deploy all sites
deploy_all() {
    local failed_deployments=()

    log "Starting deployment of all websites..."

    # Deploy each configured site
    for site_name in "${!SITE_LOCAL_PATHS[@]}"; do
        local local_path="${SITE_LOCAL_PATHS[$site_name]}"
        local remote_path="${SITE_REMOTE_PATHS[$site_name]}"

        if [ "$WITH_DELETE" = "true" ]; then
            deploy_site_with_delete "$site_name" "$local_path" "$remote_path" || failed_deployments+=("$site_name")
        else
            deploy_site "$site_name" "$local_path" "$remote_path" || failed_deployments+=("$site_name")
        fi
    done

    # Report results
    if [ ${#failed_deployments[@]} -eq 0 ]; then
        success "All websites deployed successfully!"
    else
        error "Failed deployments: ${failed_deployments[*]}"
        return 1
    fi
}

# Deploy specific site
deploy_specific() {
    local site_name="$1"

    # Check if site is configured
    if [[ -z "${SITE_LOCAL_PATHS[$site_name]}" ]]; then
        error "Unknown site: $site_name"
        error "Available sites: ${!SITE_LOCAL_PATHS[*]}"
        return 1
    fi

    local local_path="${SITE_LOCAL_PATHS[$site_name]}"
    local remote_path="${SITE_REMOTE_PATHS[$site_name]}"

    if [ "$WITH_DELETE" = "true" ]; then
        deploy_site_with_delete "$site_name" "$local_path" "$remote_path"
    else
        deploy_site "$site_name" "$local_path" "$remote_path"
    fi
}

# List all configured sites
list_sites() {
    echo "Configured sites:"
    for site_name in "${!SITE_LOCAL_PATHS[@]}"; do
        echo "  - $site_name"
        echo "      Local:  ${SITE_LOCAL_PATHS[$site_name]}"
        echo "      Remote: ${SITE_REMOTE_PATHS[$site_name]}"
        if [[ -n "${SITE_BUILD_CMDS[$site_name]}" ]]; then
            echo "      Build:  ${SITE_BUILD_CMDS[$site_name]}"
        fi
        if [[ -n "${SITE_EXCLUDES[$site_name]}" ]]; then
            echo "      Excludes: ${SITE_EXCLUDES[$site_name]}"
        fi
        if [[ -n "${SITE_PRE_HOOKS[$site_name]}" ]]; then
            echo "      Pre-hook: ${SITE_PRE_HOOKS[$site_name]}"
        fi
        if [[ -n "${SITE_POST_HOOKS[$site_name]}" ]]; then
            echo "      Post-hook: ${SITE_POST_HOOKS[$site_name]}"
        fi
        echo ""
    done
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] [SITE]"
    echo ""
    echo "SITES:"
    echo "  Use --list to see all configured sites"
    echo "  all           Deploy all sites (default)"
    echo ""
    echo "OPTIONS:"
    echo "  --dry-run     Show what would be transferred without actually doing it"
    echo "  --skip-test   Skip SSH connection test (faster startup)"
    echo "  --ssh         Connect to server via SSH"
    echo "  --with-delete Use rsync --delete (DANGEROUS: deletes remote files)"
    echo "  --list        List all configured sites"
    echo "  --help        Show this help message"
    echo ""
    echo "CONFIGURATION:"
    echo "  Config file: $CONFIG_FILE (optional)"
    echo "  Set via env: DEPLOY_CONFIG=/path/to/config"
    echo ""
    echo "  Config file format (bash syntax):"
    echo "    SERVER_USER=\"username\""
    echo "    SERVER_HOST=\"hostname.com\""
    echo "    LOCAL_PROJECTS=\"/path/to/projects\""
    echo "    REMOTE_BASE=\"public_html\""
    echo "    SSH_KEY=\"/path/to/ssh/key\""
    echo ""
    echo "    # Define sites using associative arrays"
    echo "    SITE_LOCAL_PATHS[mysite]=\"/local/path\""
    echo "    SITE_REMOTE_PATHS[mysite]=\"remote/path\""
    echo "    SITE_EXCLUDES[mysite]=\"*.log,.git,node_modules\""
    echo "    SITE_BUILD_CMDS[mysite]=\"cd /path/to/site && python3 ssg.py build\""
    echo "    SITE_PRE_HOOKS[mysite]=\"/path/to/pre-deploy.sh\""
    echo "    SITE_POST_HOOKS[mysite]=\"/path/to/post-deploy.sh\""
    echo ""
    echo "  Environment variables (override config file):"
    echo "    DEPLOY_USER        - SSH username"
    echo "    DEPLOY_HOST        - Server hostname"
    echo "    DEPLOY_LOCAL_DIR   - Local projects directory"
    echo "    DEPLOY_REMOTE_BASE - Remote base directory"
    echo "    DEPLOY_SSH_KEY     - Path to SSH private key"
    echo "    DEPLOY_LOG_FILE    - Path to log file"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy all sites"
    echo "  $0 mysite            # Deploy specific site"
    echo "  $0 --dry-run all     # See what would be deployed"
    echo "  $0 --list            # List all configured sites"
}

# SSH connection helper
connect_ssh() {
    log "Connecting to $SERVER_HOST..."
    ssh "$SERVER_USER@$SERVER_HOST"
}

# Main script logic
main() {
    # Initialize logging
    init_log

    # Load configuration
    load_config
    load_default_sites

    # Validate configuration
    if ! validate_config; then
        error "Configuration validation failed"
        exit 1
    fi

    check_dependencies

    # Parse command line arguments
    DRY_RUN=false
    SITE_TO_DEPLOY="all"
    SKIP_CONNECTION_TEST=false
    WITH_DELETE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-test)
                SKIP_CONNECTION_TEST=true
                shift
                ;;
            --with-delete)
                WITH_DELETE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            --list)
                list_sites
                exit 0
                ;;
            --ssh)
                connect_ssh
                exit 0
                ;;
            all)
                SITE_TO_DEPLOY="all"
                shift
                ;;
            *)
                # Check if it's a valid site name
                if [[ -n "${SITE_LOCAL_PATHS[$1]}" ]]; then
                    SITE_TO_DEPLOY="$1"
                    shift
                else
                    error "Unknown option or site: $1"
                    show_usage
                    exit 1
                fi
                ;;
        esac
    done

    # Acquire lock to prevent simultaneous deployments
    if ! acquire_lock; then
        exit 1
    fi

    # Test connection first (unless skipped)
    if [ "$SKIP_CONNECTION_TEST" = "false" ] && ! test_connection; then
        warning "Connection test failed. Use --skip-test to bypass this check."
        exit 1
    fi

    # Deploy based on argument
    if [ "$SITE_TO_DEPLOY" = "all" ]; then
        deploy_all
    else
        deploy_specific "$SITE_TO_DEPLOY"
    fi
}

# Run main function with all arguments
main "$@"
