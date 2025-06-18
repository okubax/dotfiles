#!/bin/bash

# Collapsible Disk Usage Analyzer for Arch Linux
# Features: Interactive tree view, colors, size bars, duplicate detection, cache cleanup

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Configuration
CACHE_DIR="$HOME/.cache"
USE_SUDO=false
SHOW_DUPLICATES=false
CLEAN_CACHE=false
MAX_DEPTH=3
MIN_SIZE=1024
COMPACT_MODE=true
SHOW_TOP_N=10
INTERACTIVE_MODE=true

# Global arrays for tree state
declare -A EXPANDED_DIRS
declare -A DIR_SIZES
declare -A DIR_ITEMS

# Usage function
usage() {
    echo -e "${BOLD}Collapsible Disk Usage Analyzer${NC}"
    echo "Usage: $0 [options] [directory]"
    echo ""
    echo "Options:"
    echo "  -s, --sudo       Use sudo for accurate root filesystem analysis"
    echo "  -d, --duplicates Find and display duplicate files"
    echo "  -c, --clean      Clean ~/.cache directory (interactive)"
    echo "  -D, --depth N    Maximum tree depth (default: 3)"
    echo "  -m, --min-size N Minimum size in bytes to display (default: 1024)"
    echo "  -t, --top N      Show top N items per directory (default: 10)"
    echo "  -f, --full       Show full tree (non-compact mode)"
    echo "  -n, --no-interactive  Non-interactive mode"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Interactive Commands:"
    echo "  ENTER    - Toggle expand/collapse directory"
    echo "  q        - Quit"
    echo "  r        - Refresh current view"
    echo "  f        - Toggle full/compact mode"
    echo "  +/-      - Increase/decrease items shown"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--sudo)
                USE_SUDO=true
                shift
                ;;
            -d|--duplicates)
                SHOW_DUPLICATES=true
                shift
                ;;
            -c|--clean)
                CLEAN_CACHE=true
                shift
                ;;
            -D|--depth)
                MAX_DEPTH="$2"
                shift 2
                ;;
            -m|--min-size)
                MIN_SIZE="$2"
                shift 2
                ;;
            -t|--top)
                SHOW_TOP_N="$2"
                shift 2
                ;;
            -f|--full)
                COMPACT_MODE=false
                shift
                ;;
            -n|--no-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                TARGET_DIR="$1"
                shift
                ;;
        esac
    done
}

# Convert bytes to human readable format
human_readable() {
    local bytes=$1
    local units=("B" "K" "M" "G" "T")
    local unit=0
    
    while [[ $bytes -gt 1024 && $unit -lt 4 ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    printf "%4d%s" $bytes "${units[$unit]}"
}

# Create size bar visualization
size_bar() {
    local size=$1
    local max_size=$2
    local bar_width=15
    local filled_width
    
    if [[ $max_size -eq 0 ]]; then
        filled_width=0
    else
        filled_width=$((size * bar_width / max_size))
    fi
    
    local bar=""
    for ((i=0; i<filled_width; i++)); do
        bar+="█"
    done
    for ((i=filled_width; i<bar_width; i++)); do
        bar+="░"
    done
    
    echo "$bar"
}

# Get file/directory size
get_size() {
    local path="$1"
    local cmd="du -sb"
    
    if [[ $USE_SUDO == true && ! -r "$path" ]]; then
        cmd="sudo du -sb"
    fi
    
    $cmd "$path" 2>/dev/null | cut -f1 || echo "0"
}

# Cache directory contents and sizes
cache_directory_data() {
    local dir="$1"
    local depth="$2"
    
    if [[ $depth -gt $MAX_DEPTH ]] || [[ -n "${DIR_ITEMS[$dir]}" ]]; then
        return
    fi
    
    local cmd="ls -1A"
    if [[ $USE_SUDO == true && ! -r "$dir" ]]; then
        cmd="sudo ls -1A"
    fi
    
    local items=()
    local sizes=()
    
    while IFS= read -r item; do
        [[ -n "$item" ]] || continue
        local full_path="$dir/$item"
        local size=$(get_size "$full_path")
        
        if [[ $size -ge $MIN_SIZE ]]; then
            items+=("$item")
            sizes+=("$size")
            DIR_SIZES["$full_path"]=$size
            
            # Recursively cache subdirectories if needed
            if [[ -d "$full_path" && $depth -lt $MAX_DEPTH ]]; then
                cache_directory_data "$full_path" $((depth + 1))
            fi
        fi
    done < <($cmd "$dir" 2>/dev/null)
    
    # Sort by size and store
    local sorted_data=""
    for i in "${!items[@]}"; do
        sorted_data+="${sizes[i]}:${items[i]}"$'\n'
    done
    
    DIR_ITEMS["$dir"]=$(echo "$sorted_data" | sort -rn -t:)
}

# Check if directory is expanded
is_expanded() {
    local dir="$1"
    [[ "${EXPANDED_DIRS[$dir]}" == "true" ]]
}

# Toggle directory expansion
toggle_expansion() {
    local dir="$1"
    if is_expanded "$dir"; then
        EXPANDED_DIRS["$dir"]="false"
    else
        EXPANDED_DIRS["$dir"]="true"
    fi
}

# Display compact tree summary
display_compact_summary() {
    local dir="$1"
    local max_size="$2"
    
    echo -e "\n${BOLD}${CYAN}📊 Directory Size Summary (Top $SHOW_TOP_N)${NC}"
    echo -e "${BOLD}${WHITE}============================================================${NC}"
    
    local data="${DIR_ITEMS[$dir]}"
    [[ -z "$data" ]] && return
    
    local count=0
    while IFS= read -r line && [[ $count -lt $SHOW_TOP_N ]]; do
        [[ -z "$line" ]] && continue
        local size="${line%%:*}"
        local item="${line#*:}"
        local full_path="$dir/$item"
        
        local color="$WHITE"
        local icon="📄"
        local expand_indicator=""
        
        if [[ -d "$full_path" ]]; then
            color="$BLUE"
            icon="📁"
            if is_expanded "$full_path"; then
                expand_indicator="${GREEN}[-]${NC}"
            else
                expand_indicator="${YELLOW}[+]${NC}"
            fi
        elif [[ -x "$full_path" ]]; then
            color="$GREEN"
            icon="⚡"
        elif [[ $size -gt 104857600 ]]; then
            color="$RED"
            icon="🔥"
        fi
        
        local bar=$(size_bar $size $max_size)
        local size_str=$(human_readable $size)
        local percentage=$((size * 100 / max_size))
        
        echo -e "${expand_indicator} ${color}$(printf "%-30s" "$item")${NC} ${CYAN}$(printf "%6s" "$size_str")${NC} $bar ${DIM}$(printf "%3d" "$percentage")%${NC}"
        
        # Show expanded directory contents
        if [[ -d "$full_path" ]] && is_expanded "$full_path"; then
            display_expanded_directory "$full_path" "  " $max_size
        fi
        
        ((count++))
    done <<< "$data"
}

# Display expanded directory contents
display_expanded_directory() {
    local dir="$1"
    local prefix="$2"
    local max_size="$3"
    
    local data="${DIR_ITEMS[$dir]}"
    [[ -z "$data" ]] && return
    
    local count=0
    local show_limit=$((SHOW_TOP_N / 2))  # Show fewer items in expanded view
    
    while IFS= read -r line && [[ $count -lt $show_limit ]]; do
        [[ -z "$line" ]] && continue
        local size="${line%%:*}"
        local item="${line#*:}"
        local full_path="$dir/$item"
        
        local color="$WHITE"
        local icon="📄"
        
        if [[ -d "$full_path" ]]; then
            color="$BLUE"
            icon="📁"
        elif [[ $size -eq 0 ]]; then
            color="$GRAY"
            icon="∅"
        elif [[ $size -gt 10485760 ]]; then
            color="$YELLOW"
            icon="📋"
        fi
        
        local size_str=$(human_readable $size)
        local mini_bar=$(size_bar $size $max_size | cut -c1-8)
        
        echo -e "${prefix}├── ${color}${icon} ${item}${NC} ${CYAN}$(printf "%6s" "$size_str")${NC} $mini_bar"
        
        ((count++))
    done <<< "$data"
    
    # Show "..." if there are more items
    local total_items=$(echo "$data" | wc -l)
    if [[ $total_items -gt $show_limit ]]; then
        echo -e "${prefix}└── ${DIM}... ($((total_items - show_limit)) more items)${NC}"
    fi
}

# Interactive mode
interactive_mode() {
    local dir="$1"
    local max_size="$2"
    
    while true; do
        clear
        
        # Header
        echo -e "${BOLD}${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
        echo -e "${BOLD}${CYAN}│      🖥️  Interactive Disk Usage Analyzer (Compact)     │${NC}"
        echo -e "${BOLD}${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
        
        local total_size=$(get_size "$dir")
        echo -e "${BOLD}📍 Target: ${BLUE}$dir${NC}"
        echo -e "${BOLD}📈 Total: ${CYAN}$(human_readable $total_size)${NC} | Mode: ${YELLOW}$($COMPACT_MODE && echo "Compact" || echo "Full")${NC} | Top: ${GREEN}$SHOW_TOP_N${NC}"
        
        if $COMPACT_MODE; then
            display_compact_summary "$dir" "$max_size"
        else
            display_tree "$dir" "" 0 "$max_size"
        fi
        
        echo -e "\n${BOLD}Commands:${NC} ${GREEN}[ENTER]${NC} Select | ${RED}[b]${NC} Back | ${YELLOW}[q]${NC} Quit | ${BLUE}[r]${NC} Refresh | ${PURPLE}[f]${NC} Toggle Mode | ${CYAN}[+/-]${NC} Items"
        echo -n "Select item number or command: "
        
        read -r input
        
        case "$input" in
            b|B|back)
                # Collapse all expanded directories and return to compact view
                for key in "${!EXPANDED_DIRS[@]}"; do
                    if [[ "$key" != "$dir" ]]; then
                        EXPANDED_DIRS["$key"]="false"
                    fi
                done
                COMPACT_MODE=true
                ;;
            q|Q|quit|exit)
                echo -e "${GREEN}Goodbye!${NC}"
                break
                ;;
            r|R|refresh)
                # Clear cache and refresh
                DIR_ITEMS=()
                DIR_SIZES=()
                cache_directory_data "$dir" 0
                max_size=$(get_max_size "$dir")
                ;;
            f|F|full)
                COMPACT_MODE=$(!$COMPACT_MODE && echo true || echo false)
                ;;
            +)
                SHOW_TOP_N=$((SHOW_TOP_N + 5))
                ;;
            -)
                [[ $SHOW_TOP_N -gt 5 ]] && SHOW_TOP_N=$((SHOW_TOP_N - 5))
                ;;
            [0-9]*)
                # Select item by number
                local data="${DIR_ITEMS[$dir]}"
                local count=1
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    if [[ $count -eq $input ]]; then
                        local item="${line#*:}"
                        local full_path="$dir/$item"
                        if [[ -d "$full_path" ]]; then
                            toggle_expansion "$full_path"
                        fi
                        break
                    fi
                    ((count++))
                done <<< "$data"
                ;;
        esac
    done
}

# Display full tree (original mode)
display_tree() {
    local dir="$1"
    local prefix="$2"
    local depth="$3"
    local max_size="$4"
    
    if [[ $depth -gt $MAX_DEPTH ]]; then
        return
    fi
    
    local data="${DIR_ITEMS[$dir]}"
    [[ -z "$data" ]] && return
    
    local count=0
    local total_items=$(echo "$data" | wc -l)
    
    while IFS= read -r line && [[ $count -lt $SHOW_TOP_N ]]; do
        [[ -z "$line" ]] && continue
        local size="${line%%:*}"
        local item="${line#*:}"
        local full_path="$dir/$item"
        
        ((count++))
        local is_last=$([[ $count -eq $SHOW_TOP_N || $count -eq $total_items ]] && echo true || echo false)
        local connector=$($is_last && echo "└── " || echo "├── ")
        local new_prefix=$($is_last && echo "$prefix    " || echo "$prefix│   ")
        
        local color="$WHITE"
        local icon="📄"
        
        if [[ -d "$full_path" ]]; then
            color="$BLUE"
            icon="📁"
        elif [[ -x "$full_path" ]]; then
            color="$GREEN"
            icon="⚡"
        elif [[ $size -eq 0 ]]; then
            color="$GRAY"
            icon="∅"
        elif [[ $size -gt 104857600 ]]; then
            color="$RED"
            icon="🔥"
        fi
        
        local bar=$(size_bar $size $max_size)
        local size_str=$(human_readable $size)
        
        echo -e "${prefix}${connector}${color}${icon} ${item}${NC} ${CYAN}${size_str}${NC} ${bar}"
        
        if [[ -d "$full_path" && $depth -lt $MAX_DEPTH ]]; then
            display_tree "$full_path" "$new_prefix" $((depth + 1)) "$max_size"
        fi
    done <<< "$data"
    
    # Show summary if items were truncated
    if [[ $total_items -gt $SHOW_TOP_N ]]; then
        echo -e "${prefix}${DIM}... (${total_items} total items, showing top ${SHOW_TOP_N})${NC}"
    fi
}

# Get maximum size for bar scaling
get_max_size() {
    local dir="$1"
    local data="${DIR_ITEMS[$dir]}"
    [[ -z "$data" ]] && echo "0" && return
    
    echo "$data" | head -1 | cut -d: -f1
}

# Find duplicates and zero files (simplified for compact mode)
find_issues() {
    local dir="$1"
    echo -e "\n${BOLD}${YELLOW}🔍 File Issues Summary${NC}"
    
    local cmd="find"
    if [[ $USE_SUDO == true ]]; then
        cmd="sudo find"
    fi
    
    # Zero size files
    local zero_count=$($cmd "$dir" -type f -size 0 2>/dev/null | wc -l)
    echo -e "${PURPLE}📋 Zero-size files: ${CYAN}$zero_count${NC}"
    
    # Large files (>100MB)
    local large_count=$($cmd "$dir" -type f -size +100M 2>/dev/null | wc -l)
    echo -e "${RED}🔥 Large files (>100MB): ${CYAN}$large_count${NC}"
    
    if [[ $SHOW_DUPLICATES == true ]]; then
        echo -e "${YELLOW}🔄 Scanning for duplicates...${NC}"
        # Simplified duplicate detection
        $cmd "$dir" -type f -exec stat -c '%s %n' {} \; 2>/dev/null | \
        sort -rn | uniq -d -w10 | wc -l | \
        xargs -I {} echo -e "${RED}📋 Potential duplicates: ${CYAN}{}${NC}"
    fi
}

# Clean cache
clean_cache() {
    if [[ ! -d "$CACHE_DIR" ]]; then
        echo -e "${YELLOW}Cache directory $CACHE_DIR not found${NC}"
        return
    fi
    
    local cache_size=$(get_size "$CACHE_DIR")
    echo -e "\n${BOLD}${BLUE}🧹 Cache: $(human_readable $cache_size)${NC}"
    
    if [[ $cache_size -lt 1024 ]]; then
        echo -e "${GREEN}Cache is clean!${NC}"
        return
    fi
    
    read -p "Clean cache? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CACHE_DIR"/* 2>/dev/null
        echo -e "${GREEN}✅ Cache cleaned!${NC}"
    fi
}

# Main function
main() {
    TARGET_DIR="${TARGET_DIR:-$(pwd)}"
    parse_args "$@"
    
    if [[ ! -d "$TARGET_DIR" ]]; then
        echo -e "${RED}Error: Directory '$TARGET_DIR' not found${NC}"
        exit 1
    fi
    
    # Initialize expanded state for root
    EXPANDED_DIRS["$TARGET_DIR"]="true"
    
    # Cache all directory data
    echo -e "${YELLOW}📊 Analyzing directory structure...${NC}"
    cache_directory_data "$TARGET_DIR" 0
    
    local max_size=$(get_max_size "$TARGET_DIR")
    
    # Clean cache if requested
    [[ $CLEAN_CACHE == true ]] && clean_cache
    
    if [[ $INTERACTIVE_MODE == true ]]; then
        interactive_mode "$TARGET_DIR" "$max_size"
    else
        # Non-interactive mode
        local total_size=$(get_size "$TARGET_DIR")
        echo -e "${BOLD}📍 Target: ${BLUE}$TARGET_DIR${NC}"
        echo -e "${BOLD}📈 Total: ${CYAN}$(human_readable $total_size)${NC}"
        
        if $COMPACT_MODE; then
            display_compact_summary "$TARGET_DIR" "$max_size"
        else
            display_tree "$TARGET_DIR" "" 0 "$max_size"
        fi
        
        find_issues "$TARGET_DIR"
    fi
    
    echo -e "\n${BOLD}${GREEN}✅ Analysis complete!${NC}"
}

# Run main function
main "$@"
