#!/bin/bash
# deploy_websites.sh - Website deployment script
# Usage: ./deploy_websites.sh [site_name] or ./deploy_websites.sh all

# Configuration
SERVER_USER="your_username"
SERVER_HOST="your-server.com"
LOCAL_PROJECTS="$HOME/Projects/sites"
REMOTE_BASE="public_html"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if rsync is available
check_dependencies() {
    if ! command -v rsync &> /dev/null; then
        error "rsync is not installed. Please install it first."
        exit 1
    fi
}

# Test SSH connection
test_connection() {
    log "Testing SSH connection to $SERVER_HOST..."
    
    # More aggressive timeout settings
    if timeout 15s ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" exit 2>/dev/null; then
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

# Deploy individual site
deploy_site() {
    local site_name="$1"
    local local_path="$2"
    local remote_path="$3"
    
    log "Deploying $site_name..."
    
    if [ ! -d "$local_path" ]; then
        error "Local directory $local_path does not exist"
        return 1
    fi
    
    # Show what will be transferred
    log "Preparing to sync: $local_path -> $SERVER_USER@$SERVER_HOST:$remote_path"
    
    # WARNING: Removed --delete flag for safety
    # If you need to delete files, use deploy_site_with_delete function instead
    if [ "$DRY_RUN" = "true" ]; then
        warning "DRY RUN MODE - No files will be transferred"
        rsync -avz --dry-run --progress "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
    else
        warning "SYNC MODE - Files will be added/updated but NOT deleted"
        rsync -avz --progress "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
        
        if [ $? -eq 0 ]; then
            success "$site_name deployed successfully"
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
    
    if [ ! -d "$local_path" ]; then
        error "Local directory $local_path does not exist"
        return 1
    fi
    
    # Show what will be transferred AND deleted
    log "Preparing to sync: $local_path -> $SERVER_USER@$SERVER_HOST:$remote_path"
    warning "Files on server that don't exist locally WILL BE DELETED"
    
    if [ "$DRY_RUN" = "true" ]; then
        warning "DRY RUN MODE - Showing what would be deleted/transferred"
        rsync -avz --dry-run --progress --delete "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
    else
        error "DANGER: Syncing with delete enabled!"
        rsync -avz --progress --delete "$local_path/" "$SERVER_USER@$SERVER_HOST:$remote_path/"
        
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
    
    # Deploy each site
    deploy_site "site1" "$LOCAL_PROJECTS/site1/remote/_site" "$REMOTE_BASE" || failed_deployments+=("site1")
    deploy_site "site2" "$LOCAL_PROJECTS/site2/remote/output" "$REMOTE_BASE/site2.example.com" || failed_deployments+=("site2")
    deploy_site "site3" "$LOCAL_PROJECTS/site3/remote" "$REMOTE_BASE/site3.example.com" || failed_deployments+=("site3")
    deploy_site "site4" "$LOCAL_PROJECTS/site4/remote" "$REMOTE_BASE/site4.example.com" || failed_deployments+=("site4")
    
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
    local deploy_func="deploy_site"
    if [ "$WITH_DELETE" = "true" ]; then
        deploy_func="deploy_site_with_delete"
    fi
    
    case "$1" in
        "site1")
            $deploy_func "site1" "$LOCAL_PROJECTS/site1/remote/_site" "$REMOTE_BASE"
            ;;
        "site2")
            $deploy_func "site2" "$LOCAL_PROJECTS/site2/remote/output" "$REMOTE_BASE/site2.example.com"
            ;;
        "site3")
            $deploy_func "site3" "$LOCAL_PROJECTS/site3/remote" "$REMOTE_BASE/site3.example.com"
            ;;
        "site4")
            $deploy_func "site4" "$LOCAL_PROJECTS/site4/remote" "$REMOTE_BASE/site4.example.com"
            ;;
        *)
            error "Unknown site: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] [SITE]"
    echo ""
    echo "SITES:"
    echo "  site1         Deploy site1"
    echo "  site2         Deploy site2"
    echo "  site3         Deploy site3"
    echo "  site4         Deploy site4"
    echo "  all           Deploy all sites (default)"
    echo ""
    echo "OPTIONS:"
    echo "  --dry-run     Show what would be transferred without actually doing it"
    echo "  --skip-test   Skip SSH connection test (faster startup)"
    echo "  --ssh         Connect to server via SSH"
    echo "  --with-delete Use rsync --delete (DANGEROUS: deletes remote files)"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy all sites"
    echo "  $0 site1             # Deploy only site1"
    echo "  $0 --dry-run all     # See what would be deployed"
}

# SSH connection helper
connect_ssh() {
    log "Connecting to $SERVER_HOST..."
    ssh "$SERVER_USER@$SERVER_HOST"
}

# Main script logic
main() {
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
            --ssh)
                connect_ssh
                exit 0
                ;;
            site1|site2|site3|site4|all)
                SITE_TO_DEPLOY="$1"
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
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
