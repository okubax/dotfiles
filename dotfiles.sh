#!/bin/bash
# dotfiles.sh - Robust Dotfiles Management System
# Manages symlinks for configuration files across systems

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$HOME/.dotfiles.log"
CONFIG_FILE="$SCRIPT_DIR/dotfiles.conf"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Flags
DRY_RUN=false
VERBOSE=false
FORCE=false
SKIP_BACKUPS=false
INTERACTIVE=true

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1" | tee -a "$LOG_FILE"
    fi
}

# Configuration structure - source:destination pairs
declare -A DOTFILES_MAP=(
    # Shell and aliases
    ["aliases/aliases"]="$HOME/.aliases"
    ["aliases/aliases_dev"]="$HOME/.aliases_dev"
    ["aliases/aliases_personal"]="$HOME/.aliases_personal"
    ["aliases/aliases_script"]="$HOME/.aliases_script"
    ["aliases/aliases_system"]="$HOME/.aliases_system"
    
    # Binaries and scripts
    ["bin"]="$HOME/bin"
    
    # Application configs
    ["fontconfig"]="$HOME/.config/fontconfig"
    ["gitconfig"]="$HOME/.gitconfig"
    ["ii"]="$HOME/.config/ii"
    ["img"]="$HOME/.img"
    ["kitty"]="$HOME/.config/kitty"
    ["mpd"]="$HOME/.mpd"
    ["mplayer"]="$HOME/.mplayer"
    ["multitailrc"]="$HOME/.multitailrc"
    ["mutt"]="$HOME/.mutt"
    ["ncmpcpp"]="$HOME/.ncmpcpp"
    ["offlineimap.py"]="$HOME/.offlineimap.py"
    ["offlineimaprc"]="$HOME/.offlineimaprc"
    ["pass"]="$HOME/.password-store"
    ["ranger"]="$HOME/.config/ranger"
    ["ssh"]="$HOME/.ssh"
    ["startpage"]="$HOME/.startpage"
    ["todo"]="$HOME/.todo"
    ["urlview"]="$HOME/.urlview"
    ["vim"]="$HOME/.vim"
    ["vimrc"]="$HOME/.vimrc"
    
    # MSMTP configs
    ["msmtprc"]="$HOME/.msmtprc"

    # SwayWM configs
    ["swaywm/mako"]="$HOME/.config/mako"
    ["swaywm/swaylock"]="$HOME/.config/swaylock"
    ["swaywm/waybar"]="$HOME/.config/waybar"
    ["swaywm/wofi"]="$HOME/.config/wofi"
    ["swaywm/sway"]="$HOME/.config/sway"
    ["swaywm/swayshot.sh"]="$HOME/.config/swayshot.sh"
    
    # ZSH configs
    ["zsh/zprofile"]="$HOME/.zprofile"
    ["zsh/zshenv"]="$HOME/.zshenv"
    ["zsh/zshrc"]="$HOME/.zshrc"
)

# Load external config if it exists
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_verbose "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    install         Install/link all dotfiles (default)
    uninstall       Remove all dotfiles symlinks
    status          Show status of all dotfiles
    backup          Create backup of existing files
    restore         Restore from backup
    validate        Validate dotfiles configuration
    list            List all managed dotfiles
    update          Update existing symlinks
    clean           Remove broken symlinks

OPTIONS:
    -d, --dry-run       Show what would be done without executing
    -v, --verbose       Enable verbose output
    -f, --force         Force operations (overwrite existing files)
    -b, --skip-backup   Skip creating backups
    -y, --yes           Non-interactive mode (yes to all prompts)
    -h, --help          Show this help message

EXAMPLES:
    $0                      # Install all dotfiles with prompts
    $0 install -d           # Preview installation without changes
    $0 status              # Check current symlink status
    $0 backup              # Create backup of existing configs
    $0 uninstall -f        # Force remove all symlinks
    $0 validate            # Check for missing source files

CONFIGURATION:
    Edit $CONFIG_FILE to customize file mappings
    Logs are written to $LOG_FILE

EOF
}

# Validate dotfiles configuration
validate_dotfiles() {
    log_info "Validating dotfiles configuration..."
    local errors=0
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local full_source_path="$DOTFILES_DIR/$source_path"
        
        if [[ ! -e "$full_source_path" ]]; then
            log_error "Source file/directory not found: $full_source_path"
            ((errors++))
        else
            log_verbose "✓ Found: $source_path"
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "All source files validated successfully"
        return 0
    else
        log_error "Validation failed: $errors missing files"
        return 1
    fi
}

# Create backup of existing files
create_backup() {
    if [[ "$SKIP_BACKUPS" == true ]]; then
        log_info "Skipping backups as requested"
        return 0
    fi
    
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    local backed_up=0
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        
        if [[ -e "$dest_path" ]] && [[ ! -L "$dest_path" ]]; then
            local backup_path="$BACKUP_DIR/$(basename "$dest_path")"
            log_verbose "Backing up: $dest_path → $backup_path"
            
            if [[ "$DRY_RUN" == false ]]; then
                cp -r "$dest_path" "$backup_path"
                ((backed_up++))
            fi
        fi
    done
    
    if [[ $backed_up -gt 0 ]]; then
        log_success "Backed up $backed_up files to $BACKUP_DIR"
        echo "$BACKUP_DIR" > "$HOME/.dotfiles_last_backup"
    else
        log_info "No files needed backing up"
        rmdir "$BACKUP_DIR" 2>/dev/null || true
    fi
}

# Restore from backup
restore_backup() {
    local backup_dir="$1"
    
    if [[ -z "$backup_dir" ]]; then
        if [[ -f "$HOME/.dotfiles_last_backup" ]]; then
            backup_dir=$(cat "$HOME/.dotfiles_last_backup")
        else
            log_error "No backup directory specified and no last backup found"
            return 1
        fi
    fi
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log_info "Restoring from backup: $backup_dir"
    
    for backup_file in "$backup_dir"/*; do
        if [[ -e "$backup_file" ]]; then
            local filename=$(basename "$backup_file")
            local restore_path="$HOME/.$filename"
            
            log_verbose "Restoring: $backup_file → $restore_path"
            
            if [[ "$DRY_RUN" == false ]]; then
                # Remove symlink if it exists
                [[ -L "$restore_path" ]] && rm "$restore_path"
                cp -r "$backup_file" "$restore_path"
            fi
        fi
    done
    
    log_success "Backup restored successfully"
}

# Create directory structure
ensure_directories() {
    local dest_path="$1"
    local dest_dir=$(dirname "$dest_path")
    
    if [[ ! -d "$dest_dir" ]]; then
        log_verbose "Creating directory: $dest_dir"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$dest_dir"
        fi
    fi
}

# Check if file should be processed
should_process_file() {
    local source_path="$1"
    local dest_path="$2"
    
    # Skip if source doesn't exist
    if [[ ! -e "$DOTFILES_DIR/$source_path" ]]; then
        log_warning "Source not found: $source_path"
        return 1
    fi
    
    # Skip if destination is already correctly linked
    if [[ -L "$dest_path" ]]; then
        local current_target=$(readlink "$dest_path")
        local expected_target="$DOTFILES_DIR/$source_path"
        
        if [[ "$current_target" == "$expected_target" ]]; then
            log_verbose "Already linked correctly: $dest_path"
            return 1
        fi
    fi
    
    return 0
}

# Handle existing files/directories
handle_existing() {
    local dest_path="$1"
    local source_path="$2"
    
    if [[ ! -e "$dest_path" ]]; then
        return 0  # Nothing exists, proceed
    fi
    
    if [[ -L "$dest_path" ]]; then
        log_verbose "Removing existing symlink: $dest_path"
        if [[ "$DRY_RUN" == false ]]; then
            rm "$dest_path"
        fi
        return 0
    fi
    
    if [[ "$FORCE" == true ]]; then
        log_warning "Force removing existing file: $dest_path"
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$dest_path"
        fi
        return 0
    fi
    
    if [[ "$INTERACTIVE" == true ]]; then
        echo -e "${YELLOW}File exists: $dest_path${NC}"
        echo -e "${CYAN}Options:${NC}"
        echo -e "  ${GREEN}o${NC}verwrite"
        echo -e "  ${GREEN}s${NC}kip"
        echo -e "  ${GREEN}b${NC}ackup and overwrite"
        echo -e "  ${GREEN}q${NC}uit"
        echo -n "Choice [o/s/b/q]: "
        
        local choice
        read choice
        
        case $choice in
            o|O)
                if [[ "$DRY_RUN" == false ]]; then
                    rm -rf "$dest_path"
                fi
                return 0
                ;;
            s|S)
                log_info "Skipping: $dest_path"
                return 1
                ;;
            b|B)
                local backup_name="${dest_path}.bak.$(date +%s)"
                log_info "Backing up to: $backup_name"
                if [[ "$DRY_RUN" == false ]]; then
                    mv "$dest_path" "$backup_name"
                fi
                return 0
                ;;
            q|Q)
                log_info "Quitting as requested"
                exit 0
                ;;
            *)
                log_warning "Invalid choice, skipping file"
                return 1
                ;;
        esac
    else
        log_warning "File exists, skipping (use -f to force): $dest_path"
        return 1
    fi
}

# Create a single symlink
create_symlink() {
    local source_path="$1"
    local dest_path="$2"
    local full_source_path="$DOTFILES_DIR/$source_path"
    
    if ! should_process_file "$source_path" "$dest_path"; then
        return 0
    fi
    
    ensure_directories "$dest_path"
    
    if ! handle_existing "$dest_path" "$source_path"; then
        return 0
    fi
    
    log_verbose "Linking: $source_path → $dest_path"
    
    if [[ "$DRY_RUN" == false ]]; then
        ln -s "$full_source_path" "$dest_path"
        log_success "✓ Linked: $(basename "$dest_path")"
    else
        echo -e "${CYAN}Would link:${NC} $source_path → $dest_path"
    fi
}

# Install all dotfiles
install_dotfiles() {
    log_info "Installing dotfiles from $DOTFILES_DIR"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Validate first
    if ! validate_dotfiles; then
        log_error "Validation failed, aborting installation"
        return 1
    fi
    
    # Create backup
    create_backup
    
    local success_count=0
    local skip_count=0
    local error_count=0
    
    # Process each dotfile
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        
        if create_symlink "$source_path" "$dest_path"; then
            ((success_count++))
        else
            ((skip_count++))
        fi
    done
    
    # Summary
    echo ""
    log_success "Installation complete!"
    log_info "Successfully linked: $success_count"
    log_info "Skipped: $skip_count"
    
    if [[ $error_count -gt 0 ]]; then
        log_warning "Errors: $error_count"
    fi
}

# Uninstall all dotfiles
uninstall_dotfiles() {
    log_info "Uninstalling dotfiles..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    local removed_count=0
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        local full_source_path="$DOTFILES_DIR/$source_path"
        
        if [[ -L "$dest_path" ]]; then
            local current_target=$(readlink "$dest_path")
            
            if [[ "$current_target" == "$full_source_path" ]]; then
                log_verbose "Removing symlink: $dest_path"
                
                if [[ "$DRY_RUN" == false ]]; then
                    rm "$dest_path"
                    ((removed_count++))
                else
                    echo -e "${CYAN}Would remove:${NC} $dest_path"
                fi
            else
                log_verbose "Skipping (not our symlink): $dest_path"
            fi
        else
            log_verbose "Not a symlink, skipping: $dest_path"
        fi
    done
    
    log_success "Removed $removed_count symlinks"
}

# Show status of all dotfiles
show_status() {
    log_info "Dotfiles status:"
    echo ""
    
    printf "%-40s %-15s %s\n" "FILE" "STATUS" "TARGET"
    printf "%-40s %-15s %s\n" "----" "------" "------"
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        local full_source_path="$DOTFILES_DIR/$source_path"
        local status="MISSING"
        local target=""
        
        if [[ -L "$dest_path" ]]; then
            target=$(readlink "$dest_path")
            if [[ "$target" == "$full_source_path" ]]; then
                status="LINKED"
                printf "%-40s ${GREEN}%-15s${NC} %s\n" "$(basename "$dest_path")" "$status" "$target"
            else
                status="WRONG_LINK"
                printf "%-40s ${YELLOW}%-15s${NC} %s\n" "$(basename "$dest_path")" "$status" "$target"
            fi
        elif [[ -e "$dest_path" ]]; then
            status="EXISTS"
            printf "%-40s ${RED}%-15s${NC} %s\n" "$(basename "$dest_path")" "$status" "$target"
        else
            status="MISSING"
            printf "%-40s ${BLUE}%-15s${NC} %s\n" "$(basename "$dest_path")" "$status" "$target"
        fi
    done
}

# List all managed dotfiles
list_dotfiles() {
    log_info "Managed dotfiles:"
    echo ""
    
    printf "%-40s %s\n" "DESTINATION" "SOURCE"
    printf "%-40s %s\n" "-----------" "------"
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        printf "%-40s %s\n" "$dest_path" "$source_path"
    done
}

# Clean broken symlinks
clean_symlinks() {
    log_info "Cleaning broken symlinks..."
    
    local cleaned=0
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        
        if [[ -L "$dest_path" ]] && [[ ! -e "$dest_path" ]]; then
            log_verbose "Removing broken symlink: $dest_path"
            
            if [[ "$DRY_RUN" == false ]]; then
                rm "$dest_path"
                ((cleaned++))
            else
                echo -e "${CYAN}Would remove broken symlink:${NC} $dest_path"
            fi
        fi
    done
    
    log_success "Cleaned $cleaned broken symlinks"
}

# Update existing symlinks
update_symlinks() {
    log_info "Updating existing symlinks..."
    
    local updated=0
    
    for source_path in "${!DOTFILES_MAP[@]}"; do
        local dest_path="${DOTFILES_MAP[$source_path]}"
        local full_source_path="$DOTFILES_DIR/$source_path"
        
        if [[ -L "$dest_path" ]]; then
            local current_target=$(readlink "$dest_path")
            
            if [[ "$current_target" != "$full_source_path" ]]; then
                log_verbose "Updating symlink: $dest_path"
                
                if [[ "$DRY_RUN" == false ]]; then
                    rm "$dest_path"
                    ln -s "$full_source_path" "$dest_path"
                    ((updated++))
                else
                    echo -e "${CYAN}Would update:${NC} $dest_path"
                fi
            fi
        fi
    done
    
    log_success "Updated $updated symlinks"
}

# Parse command line arguments
parse_args() {
    local command="install"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|uninstall|status|backup|restore|validate|list|update|clean)
                command="$1"
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--skip-backup)
                SKIP_BACKUPS=true
                shift
                ;;
            -y|--yes)
                INTERACTIVE=false
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "$command"
}

# Main function
main() {
    # Initialize logging
    log "Dotfiles manager started"
    
    # Load configuration
    load_config
    
    # Parse arguments
    local command=$(parse_args "$@")
    
    # Show configuration
    if [[ "$VERBOSE" == true ]]; then
        log_verbose "Dotfiles directory: $DOTFILES_DIR"
        log_verbose "Backup directory: $BACKUP_DIR"
        log_verbose "Command: $command"
        log_verbose "Dry run: $DRY_RUN"
        log_verbose "Force: $FORCE"
        log_verbose "Interactive: $INTERACTIVE"
    fi
    
    # Execute command
    case $command in
        install)
            install_dotfiles
            ;;
        uninstall)
            uninstall_dotfiles
            ;;
        status)
            show_status
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "${2:-}"
            ;;
        validate)
            validate_dotfiles
            ;;
        list)
            list_dotfiles
            ;;
        update)
            update_symlinks
            ;;
        clean)
            clean_symlinks
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
    
    log "Dotfiles manager finished"
}

# Run main function with all arguments
main "$@"
