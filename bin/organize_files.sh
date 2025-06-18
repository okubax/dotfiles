#!/bin/bash
# organize_files.sh - Organize files by extension into categorized folders
# Usage: ./organize_files.sh [directory] [options]

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration - Add more extensions as needed
declare -A FILE_CATEGORIES=(
    # Documents
    ["pdf"]="documents"
    ["doc"]="documents"
    ["docx"]="documents"
    ["txt"]="documents"
    ["rtf"]="documents"
    ["odt"]="documents"
    ["pages"]="documents"
    
    # Spreadsheets & Presentations
    ["xls"]="documents"
    ["xlsx"]="documents"
    ["ods"]="documents"
    ["csv"]="documents"
    ["ppt"]="documents"
    ["pptx"]="documents"
    ["odp"]="documents"
    ["key"]="documents"
    
    # Images
    ["jpg"]="images"
    ["jpeg"]="images"
    ["png"]="images"
    ["gif"]="images"
    ["bmp"]="images"
    ["tiff"]="images"
    ["tif"]="images"
    ["svg"]="images"
    ["webp"]="images"
    ["ico"]="images"
    ["raw"]="images"
    ["cr2"]="images"
    ["nef"]="images"
    
    # Videos
    ["mp4"]="videos"
    ["avi"]="videos"
    ["mkv"]="videos"
    ["mov"]="videos"
    ["wmv"]="videos"
    ["flv"]="videos"
    ["webm"]="videos"
    ["m4v"]="videos"
    ["3gp"]="videos"
    ["mpg"]="videos"
    ["mpeg"]="videos"
    
    # Audio
    ["mp3"]="audio"
    ["wav"]="audio"
    ["flac"]="audio"
    ["aac"]="audio"
    ["ogg"]="audio"
    ["wma"]="audio"
    ["m4a"]="audio"
    ["opus"]="audio"
    
    # Archives
    ["zip"]="archives"
    ["rar"]="archives"
    ["7z"]="archives"
    ["tar"]="archives"
    ["gz"]="archives"
    ["bz2"]="archives"
    ["xz"]="archives"
    ["deb"]="archives"
    ["rpm"]="archives"
    ["dmg"]="archives"
    ["iso"]="archives"
    
    # Code & Development
    ["py"]="code"
    ["js"]="code"
    ["html"]="code"
    ["css"]="code"
    ["php"]="code"
    ["java"]="code"
    ["cpp"]="code"
    ["c"]="code"
    ["h"]="code"
    ["sh"]="code"
    ["bash"]="code"
    ["json"]="code"
    ["xml"]="code"
    ["yml"]="code"
    ["yaml"]="code"
    ["sql"]="code"
    ["md"]="code"
    
    # Executables & Applications
    ["exe"]="applications"
    ["msi"]="applications"
    ["app"]="applications"
    ["deb"]="applications"
    ["rpm"]="applications"
    ["appimage"]="applications"
    
    # Fonts
    ["ttf"]="fonts"
    ["otf"]="fonts"
    ["woff"]="fonts"
    ["woff2"]="fonts"
    
    # Other
    ["log"]="logs"
    ["tmp"]="temp"
    ["bak"]="backups"
    ["old"]="backups"
)

# Default settings
DRY_RUN=false
RECURSIVE=false
VERBOSE=false
WORK_DIR="."
MOVED_COUNT=0
SKIPPED_COUNT=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [DIRECTORY] [OPTIONS]"
    echo ""
    echo "Organize files by extension into categorized folders"
    echo ""
    echo "ARGUMENTS:"
    echo "  DIRECTORY     Directory to organize (default: current directory)"
    echo ""
    echo "OPTIONS:"
    echo "  -r, --recursive    Organize files in subdirectories too"
    echo "  -d, --dry-run      Show what would be moved without actually moving"
    echo "  -v, --verbose      Show detailed output"
    echo "  -l, --list         List supported file types and exit"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                     # Organize current directory"
    echo "  $0 ~/Downloads         # Organize Downloads folder"
    echo "  $0 -d ~/Downloads      # Preview organization"
    echo "  $0 -r ~/Documents      # Organize recursively"
}

# Show supported file types
show_supported_types() {
    echo "Supported File Categories and Extensions:"
    echo "========================================"
    
    # Group by category
    declare -A categories
    for ext in "${!FILE_CATEGORIES[@]}"; do
        category="${FILE_CATEGORIES[$ext]}"
        if [[ -z "${categories[$category]}" ]]; then
            categories[$category]="$ext"
        else
            categories[$category]="${categories[$category]}, $ext"
        fi
    done
    
    # Display grouped
    for category in $(printf '%s\n' "${!categories[@]}" | sort); do
        echo -e "${GREEN}$category:${NC} ${categories[$category]}"
    done
}

# Get file extension in lowercase
get_extension() {
    local filename="$1"
    echo "${filename##*.}" | tr '[:upper:]' '[:lower:]'
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$dir"
            log_verbose "Created directory: $dir"
        else
            log_verbose "Would create directory: $dir"
        fi
    fi
}

# Move a single file
move_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    local extension=$(get_extension "$filename")
    
    # Skip files without extensions or hidden files
    if [[ "$extension" == "$filename" ]] || [[ "$filename" == .* ]]; then
        log_verbose "Skipping: $filename (no extension or hidden file)"
        ((SKIPPED_COUNT++))
        return
    fi
    
    # Check if we have a category for this extension
    if [[ -z "${FILE_CATEGORIES[$extension]}" ]]; then
        log_verbose "Skipping: $filename (unsupported extension: .$extension)"
        ((SKIPPED_COUNT++))
        return
    fi
    
    local category="${FILE_CATEGORIES[$extension]}"
    local dest_dir="$WORK_DIR/$category"
    local dest_path="$dest_dir/$filename"
    
    # Handle file name conflicts
    local counter=1
    local base_name="${filename%.*}"
    local file_ext="$extension"
    
    while [[ -e "$dest_path" ]] && [[ "$dest_path" != "$file_path" ]]; do
        dest_path="$dest_dir/${base_name}_${counter}.${file_ext}"
        ((counter++))
    done
    
    # Skip if source and destination are the same
    if [[ "$file_path" == "$dest_path" ]]; then
        log_verbose "Skipping: $filename (already in correct location)"
        ((SKIPPED_COUNT++))
        return
    fi
    
    # Create destination directory
    ensure_directory "$dest_dir"
    
    # Move the file
    if [ "$DRY_RUN" = true ]; then
        echo "Would move: $file_path → $dest_path"
    else
        if mv "$file_path" "$dest_path"; then
            log_verbose "Moved: $filename → $category/"
            ((MOVED_COUNT++))
        else
            log_error "Failed to move: $filename"
        fi
    fi
}

# Organize files in a directory
organize_directory() {
    local dir="$1"
    
    log_info "Organizing directory: $dir"
    
    if [ "$RECURSIVE" = true ]; then
        # Find all files recursively
        while IFS= read -r -d '' file; do
            move_file "$file"
        done < <(find "$dir" -type f -print0)
    else
        # Only process files in the current directory
        for file in "$dir"/*; do
            if [ -f "$file" ]; then
                move_file "$file"
            fi
        done
    fi
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--recursive)
                RECURSIVE=true
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
            -l|--list)
                show_supported_types
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -d "$1" ]]; then
                    WORK_DIR="$1"
                else
                    log_error "Directory not found: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Convert to absolute path
    WORK_DIR=$(realpath "$WORK_DIR")
    
    # Verify directory exists
    if [[ ! -d "$WORK_DIR" ]]; then
        log_error "Directory does not exist: $WORK_DIR"
        exit 1
    fi
    
    # Show configuration
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN MODE - No files will be moved"
    fi
    
    log_info "Working directory: $WORK_DIR"
    log_info "Recursive mode: $RECURSIVE"
    log_info "Verbose mode: $VERBOSE"
    echo ""
    
    # Start organizing
    organize_directory "$WORK_DIR"
    
    # Show summary
    echo ""
    log_success "Organization complete!"
    echo "Files moved: $MOVED_COUNT"
    echo "Files skipped: $SKIPPED_COUNT"
    
    if [ "$DRY_RUN" = true ]; then
        echo ""
        log_info "This was a dry run. Use without -d to actually move files."
    fi
}

# Run main function with all arguments
main "$@"
