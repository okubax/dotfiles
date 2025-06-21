#!/bin/bash
# Public Dotfiles Management Script
# Creates symlinks from dotfiles repository to home directory
# Designed for community sharing - handles missing files gracefully

# Auto-detect dotfiles directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
DRY_RUN=false
FORCE=false
VERBOSE=false
NO_BACKUP=false

# File mappings: source -> destination
# Note: Some files may not exist in the public repo - this is normal
declare -A FILES=(
    # Shell and aliases
    ["aliases/aliases"]="$HOME/.aliases"
    ["aliases/aliases_dev"]="$HOME/.aliases_dev"
    ["aliases/aliases_personal"]="$HOME/.aliases_personal"
    ["aliases/aliases_script"]="$HOME/.aliases_script"
    ["aliases/aliases_system"]="$HOME/.aliases_system"
    
    # Binaries and scripts
    ["bin"]="$HOME/bin"
    
    # Application configs (basic)
    ["fontconfig"]="$HOME/.config/fontconfig"
    ["gitconfig"]="$HOME/.gitconfig"
    ["ii"]="$HOME/.config/ii"
    ["img"]="$HOME/.img"
    ["kitty"]="$HOME/.config/kitty"
    ["mplayer"]="$HOME/.mplayer"
    ["multitailrc"]="$HOME/.multitailrc"
    ["mutt"]="$HOME/.mutt"
    ["ncmpcpp"]="$HOME/.ncmpcpp"
    ["neofetch"]="$HOME/.config/neofetch"
    ["offlineimap.py"]="$HOME/.offlineimap.py"
    ["offlineimaprc"]="$HOME/.offlineimaprc"
    ["ranger"]="$HOME/.config/ranger"
    ["startpage"]="$HOME/.startpage"
    ["todo"]="$HOME/.todo"
    ["urlview"]="$HOME/.urlview"
    ["vim"]="$HOME/.vim"
    ["vimrc"]="$HOME/.vimrc"
    
    # MSMTP config (basic template)
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
    ["zsh/zsh_history"]="$HOME/.zsh_history"
    
    # ZSH modular configs
    ["zsh/config/history.zsh"]="$HOME/.config/zsh/history.zsh"
    ["zsh/config/options.zsh"]="$HOME/.config/zsh/options.zsh"
    ["zsh/config/completion.zsh"]="$HOME/.config/zsh/completion.zsh"
    ["zsh/config/prompt.zsh"]="$HOME/.config/zsh/prompt.zsh"
    ["zsh/config/aliases.zsh"]="$HOME/.config/zsh/aliases.zsh"
    ["zsh/config/plugins.zsh"]="$HOME/.config/zsh/plugins.zsh"
    
    # ZSH plugins (individual files)
    ["zsh/plugins/catppuccin_frappe-zsh-syntax-highlighting.zsh"]="$HOME/.local/share/zsh/plugins/catppuccin_frappe-zsh-syntax-highlighting.zsh"
    ["zsh/plugins/catppuccin_latte-zsh-syntax-highlighting.zsh"]="$HOME/.local/share/zsh/plugins/catppuccin_latte-zsh-syntax-highlighting.zsh"
    ["zsh/plugins/catppuccin_macchiato-zsh-syntax-highlighting.zsh"]="$HOME/.local/share/zsh/plugins/catppuccin_macchiato-zsh-syntax-highlighting.zsh"
    ["zsh/plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh"]="$HOME/.local/share/zsh/plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh"
)

# Logging functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${NC}[VERBOSE] $1"
    fi
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    install     Install/link all available dotfiles (default)
    uninstall   Remove all symlinks created by this script
    status      Show status of all dotfiles
    backup      Create backup of existing configs
    restore     Restore from most recent backup
    help        Show this help

OPTIONS:
    -d, --dry-run       Show what would be done
    -f, --force         Overwrite existing files
    -v, --verbose       Verbose output
    -p, --path PATH     Specify dotfiles directory (default: script location)
    -b, --no-backup     Skip automatic backup during install
    -h, --help          Show help

EXAMPLES:
    $0                                # Install available dotfiles
    $0 install -d                     # Preview installation
    $0 backup                         # Create backup manually
    $0 status                         # Check current status
    $0 uninstall -f                   # Force remove all symlinks

NOTES:
    - This is a public dotfiles repository
    - Some files may not be included for privacy/system-specific reasons
    - Missing files will show warnings but won't cause installation to fail
    - Private configs (GPG keys, credentials) are not included

SETUP ON NEW SYSTEM:
    1. Clone repository: git clone https://github.com/okubax/dotfiles.git ~/dotfiles
    2. Install dependencies (see README.md)
    3. Run installer: ~/dotfiles/dotfiles.sh install

EOF
}

# Create backup of existing configs
create_backup() {
    if [[ "$NO_BACKUP" == true ]]; then
        verbose "Skipping backup as requested"
        return 0
    fi
    
    info "Creating backup directory: $BACKUP_DIR"
    
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    local backup_count=0
    local backup_list=()
    
    # Check what needs backing up (only check files that exist in repo)
    for source_rel in "${!FILES[@]}"; do
        local dest="${FILES[$source_rel]}"
        local source="$DOTFILES_DIR/$source_rel"
        
        # Skip if source doesn't exist in this public repo
        if [[ ! -e "$source" ]]; then
            continue
        fi
        
        # Only backup if file/directory exists and is not already a symlink to our dotfiles
        if [[ -e "$dest" ]] && [[ ! -L "$dest" || "$(readlink "$dest" 2>/dev/null)" != "$source" ]]; then
            backup_list+=("$dest")
        fi
    done
    
    if [[ ${#backup_list[@]} -eq 0 ]]; then
        info "No files need backing up"
        if [[ "$DRY_RUN" == false ]]; then
            rmdir "$BACKUP_DIR" 2>/dev/null || true
        fi
        return 0
    fi
    
    info "Found ${#backup_list[@]} files/directories to backup"
    
    # Create backups
    for dest in "${backup_list[@]}"; do
        local backup_name="$(basename "$dest")"
        local backup_path="$BACKUP_DIR/$backup_name"
        
        # Handle naming conflicts in backup directory
        local counter=1
        while [[ -e "$backup_path" ]]; do
            backup_path="$BACKUP_DIR/${backup_name}.${counter}"
            ((counter++))
        done
        
        verbose "Backing up: $dest → $backup_path"
        
        if [[ "$DRY_RUN" == false ]]; then
            if [[ -d "$dest" ]]; then
                cp -r "$dest" "$backup_path"
            else
                cp "$dest" "$backup_path"
            fi
            ((backup_count++))
        else
            echo "  Would backup: $dest → $backup_path"
        fi
    done
    
    if [[ "$DRY_RUN" == false ]]; then
        # Save backup location for easy restoration
        echo "$BACKUP_DIR" > "$HOME/.dotfiles_last_backup"
        echo "# Public dotfiles backup created on $(date)" >> "$BACKUP_DIR/backup_info.txt"
        echo "# Original dotfiles directory: $DOTFILES_DIR" >> "$BACKUP_DIR/backup_info.txt"
        echo "# Files backed up: $backup_count" >> "$BACKUP_DIR/backup_info.txt"
        echo "# Repository: https://github.com/okubax/dotfiles" >> "$BACKUP_DIR/backup_info.txt"
        
        success "Backed up $backup_count files to $BACKUP_DIR"
        info "Backup location saved to ~/.dotfiles_last_backup"
    fi
}

# Restore from backup
restore_backup() {
    local backup_dir="${1:-}"
    
    # If no backup dir specified, use the last one
    if [[ -z "$backup_dir" ]]; then
        if [[ -f "$HOME/.dotfiles_last_backup" ]]; then
            backup_dir=$(cat "$HOME/.dotfiles_last_backup")
            info "Using last backup: $backup_dir"
        else
            error "No backup directory specified and no last backup found"
            echo "Usage: $0 restore [backup_directory]"
            echo "Available backups:"
            ls -la "$HOME"/.dotfiles_backup_* 2>/dev/null || echo "  No backups found"
            return 1
        fi
    fi
    
    if [[ ! -d "$backup_dir" ]]; then
        error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    info "Restoring from backup: $backup_dir"
    
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    local restore_count=0
    
    # Show backup info if available
    if [[ -f "$backup_dir/backup_info.txt" ]]; then
        info "Backup information:"
        cat "$backup_dir/backup_info.txt" | sed 's/^/  /'
        echo ""
    fi
    
    # Restore each file
    for backup_file in "$backup_dir"/*; do
        if [[ -e "$backup_file" ]] && [[ "$(basename "$backup_file")" != "backup_info.txt" ]]; then
            local filename=$(basename "$backup_file")
            
            # Remove any numbering suffix added during backup
            local clean_filename=$(echo "$filename" | sed 's/\.[0-9]*$//')
            local restore_path="$HOME/$clean_filename"
            
            # Handle special cases for dotfiles
            if [[ "$clean_filename" != .* ]]; then
                restore_path="$HOME/.$clean_filename"
            fi
            
            verbose "Restoring: $backup_file → $restore_path"
            
            if [[ "$DRY_RUN" == false ]]; then
                # Remove current symlink/file if it exists
                if [[ -L "$restore_path" ]]; then
                    rm "$restore_path"
                elif [[ -e "$restore_path" ]]; then
                    rm -rf "$restore_path"
                fi
                
                # Restore the backup
                if [[ -d "$backup_file" ]]; then
                    cp -r "$backup_file" "$restore_path"
                else
                    cp "$backup_file" "$restore_path"
                fi
                ((restore_count++))
            else
                echo "  Would restore: $backup_file → $restore_path"
            fi
        fi
    done
    
    if [[ "$DRY_RUN" == false ]]; then
        success "Restored $restore_count files from backup"
        warning "Note: You may need to reconfigure private settings (credentials, keys, etc.)"
    fi
}

# Create necessary directories
create_directories() {
    local dest_path="$1"
    local dest_dir
    dest_dir=$(dirname "$dest_path")
    
    if [[ ! -d "$dest_dir" ]]; then
        verbose "Creating directory: $dest_dir"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$dest_dir"
        fi
    fi
}

# Check if file should be processed
should_link() {
    local source="$1"
    local dest="$2"
    
    # Source must exist (but we handle this gracefully)
    if [[ ! -e "$source" ]]; then
        return 1
    fi
    
    # If destination is already correctly linked, skip
    if [[ -L "$dest" ]]; then
        local current_target
        current_target=$(readlink "$dest")
        if [[ "$current_target" == "$source" ]]; then
            verbose "Already linked correctly: $dest"
            return 1
        fi
    fi
    
    return 0
}

# Handle existing files
handle_existing() {
    local dest="$1"
    local source="$2"
    
    if [[ ! -e "$dest" ]]; then
        return 0  # Nothing exists, proceed
    fi
    
    if [[ -L "$dest" ]]; then
        verbose "Removing existing symlink: $dest"
        if [[ "$DRY_RUN" == false ]]; then
            rm "$dest"
        fi
        return 0
    fi
    
    if [[ "$FORCE" == true ]]; then
        warning "Force removing existing file: $dest"
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$dest"
        fi
        return 0
    fi
    
    # Interactive mode
    echo -e "${YELLOW}File exists: $dest${NC}"
    echo "What would you like to do?"
    echo "  [o]verwrite"
    echo "  [s]kip"
    echo "  [b]ackup and overwrite"
    echo "  [q]uit"
    read -p "Choice [o/s/b/q]: " choice
    
    case $choice in
        o|O)
            if [[ "$DRY_RUN" == false ]]; then
                rm -rf "$dest"
            fi
            return 0
            ;;
        s|S)
            info "Skipping: $dest"
            return 1
            ;;
        b|B)
            local backup_name="${dest}.bak.$(date +%s)"
            info "Backing up to: $backup_name"
            if [[ "$DRY_RUN" == false ]]; then
                mv "$dest" "$backup_name"
            fi
            return 0
            ;;
        q|Q)
            info "Quitting"
            exit 0
            ;;
        *)
            warning "Invalid choice, skipping"
            return 1
            ;;
    esac
}

# Create a single symlink
link_file() {
    local source_rel="$1"
    local dest="$2"
    local source="$DOTFILES_DIR/$source_rel"
    
    verbose "Processing: $source_rel"
    
    # Check if source exists - warn but don't fail
    if [[ ! -e "$source" ]]; then
        warning "Source not found (skipping): $source_rel"
        verbose "  This file may be system-specific or private"
        return 1
    fi
    
    if ! should_link "$source" "$dest"; then
        return 1
    fi
    
    create_directories "$dest"
    
    if ! handle_existing "$dest" "$source"; then
        return 1
    fi
    
    info "Linking: $source_rel -> $dest"
    
    if [[ "$DRY_RUN" == false ]]; then
        ln -s "$source" "$dest"
        success "✓ Linked: $(basename "$dest")"
    else
        echo "  Would link: $source -> $dest"
    fi
    
    return 0
}

# Install all dotfiles
install() {
    info "Installing dotfiles from $DOTFILES_DIR"
    info "This is a public dotfiles repository - some files may not be included"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Create backup first (unless disabled or dry run)
    if [[ "$DRY_RUN" == false ]]; then
        create_backup
        echo ""
    fi
    
    local success_count=0
    local skip_count=0
    local missing_count=0
    
    # Process each file
    for source_rel in "${!FILES[@]}"; do
        local dest="${FILES[$source_rel]}"
        local source="$DOTFILES_DIR/$source_rel"
        
        if [[ ! -e "$source" ]]; then
            ((missing_count++))
            verbose "Missing: $source_rel (this is normal for public repos)"
            continue
        fi
        
        if link_file "$source_rel" "$dest"; then
            ((success_count++))
        else
            ((skip_count++))
        fi
    done
    
    echo ""
    success "Installation complete!"
    info "Successfully linked: $success_count"
    info "Skipped: $skip_count"
    
    if [[ $missing_count -gt 0 ]]; then
        warning "Missing files: $missing_count (normal for public repo)"
        verbose "Missing files are typically private configs, credentials, or system-specific"
    fi
    
    echo ""
    info "Next steps:"
    info "1. Install required packages (see README.md)"
    info "2. Configure private settings (email, GPG, etc.)"
    info "3. Restart your shell or log out/in to apply changes"
}

# Uninstall all dotfiles
uninstall() {
    info "Uninstalling dotfiles..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    local removed_count=0
    
    for source_rel in "${!FILES[@]}"; do
        local dest="${FILES[$source_rel]}"
        local source="$DOTFILES_DIR/$source_rel"
        
        if [[ -L "$dest" ]]; then
            local current_target
            current_target=$(readlink "$dest")
            
            if [[ "$current_target" == "$source" ]]; then
                verbose "Removing symlink: $dest"
                
                if [[ "$DRY_RUN" == false ]]; then
                    rm "$dest"
                    ((removed_count++))
                else
                    echo "  Would remove: $dest"
                fi
            else
                verbose "Skipping (not our symlink): $dest"
            fi
        else
            verbose "Not a symlink, skipping: $dest"
        fi
    done
    
    success "Removed $removed_count symlinks"
}

# Show status of all dotfiles
status() {
    info "Dotfiles status (from: $DOTFILES_DIR):"
    echo ""
    
    printf "%-50s %-15s %s\n" "FILE" "STATUS" "TARGET/NOTE"
    printf "%-50s %-15s %s\n" "----" "------" "----------"
    
    local available=0
    local linked=0
    local missing=0
    
    for source_rel in "${!FILES[@]}"; do
        local dest="${FILES[$source_rel]}"
        local source="$DOTFILES_DIR/$source_rel"
        local status_text="MISSING"
        local note=""
        
        if [[ ! -e "$source" ]]; then
            status_text="NOT_IN_REPO"
            note="(private/system-specific)"
            printf "%-50s ${YELLOW}%-15s${NC} %s\n" "$dest" "$status_text" "$note"
            ((missing++))
            continue
        fi
        
        ((available++))
        
        if [[ -L "$dest" ]]; then
            local target
            target=$(readlink "$dest")
            if [[ "$target" == "$source" ]]; then
                status_text="LINKED"
                printf "%-50s ${GREEN}%-15s${NC} %s\n" "$dest" "$status_text" "$target"
                ((linked++))
            else
                status_text="WRONG_LINK"
                printf "%-50s ${YELLOW}%-15s${NC} %s\n" "$dest" "$status_text" "$target"
            fi
        elif [[ -e "$dest" ]]; then
            status_text="EXISTS"
            printf "%-50s ${RED}%-15s${NC} %s\n" "$dest" "$status_text" "(file exists, not symlinked)"
        else
            status_text="AVAILABLE"
            printf "%-50s ${BLUE}%-15s${NC} %s\n" "$dest" "$status_text" "(ready to link)"
        fi
    done
    
    echo ""
    info "Summary:"
    info "  Available in repo: $available"
    info "  Currently linked: $linked"
    info "  Not in public repo: $missing"
}

# Parse command line arguments
parse_args() {
    local command="install"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|uninstall|status|backup|restore|help)
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
            -p|--path)
                DOTFILES_DIR="$2"
                shift 2
                ;;
            -b|--no-backup)
                NO_BACKUP=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    echo "$command"
}() {
    local command="install"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|uninstall|status|help)
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
            -p|--path)
                DOTFILES_DIR="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    echo "$command"
}

# Main function
main() {
    # Parse arguments first (may override DOTFILES_DIR)
    local command
    command=$(parse_args "$@")
    
    # Resolve absolute path
    DOTFILES_DIR=$(cd "$DOTFILES_DIR" && pwd)
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    verbose "Using dotfiles directory: $DOTFILES_DIR"
    
    # Execute command
    case $command in
        install)
            install
            ;;
        uninstall)
            uninstall
            ;;
        status)
            status
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "${2:-}"
            ;;
        help)
            usage
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
