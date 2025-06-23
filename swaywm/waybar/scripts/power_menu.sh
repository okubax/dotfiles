#!/bin/bash
# Robust Power Menu for Sway/Wayland
# Enhanced version with error handling, confirmations, and fallbacks

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
WOFI_HEIGHT=280
WOFI_WIDTH=300
LOCK_COMMAND="swaylock"
SUSPEND_DELAY=1

# Colors and styling (adjust to match your theme)
WOFI_OPTS=(
    --height="$WOFI_HEIGHT"
    --width="$WOFI_WIDTH"
    --dmenu
    --prompt="Power Menu:"
    --cache-file=/dev/null
    --hide-scroll
    --matching=fuzzy
    --insensitive
)

# Power menu options with icons and descriptions
declare -A POWER_OPTIONS=(
    ["🔒 Lock Screen"]="lock"
    ["💤 Suspend"]="suspend"
    ["🚪 Logout"]="logout"
    ["⏻ Shutdown"]="shutdown"
    ["🔄 Reboot"]="reboot"
    ["❌ Cancel"]="cancel"
)

# Logging functions
log_info() {
    echo "[$SCRIPT_NAME] INFO: $1" >&2
}

log_error() {
    echo "[$SCRIPT_NAME] ERROR: $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo "[$SCRIPT_NAME] DEBUG: $1" >&2
    fi
}

# Check if required commands exist
check_dependencies() {
    local missing_deps=()
    
    for cmd in wofi swaymsg systemctl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        notify_user "Error" "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Check if we're running in a Sway session
check_sway_session() {
    if [[ -z "${SWAYSOCK:-}" ]] && ! pgrep -x sway &> /dev/null; then
        log_error "Not running in a Sway session"
        notify_user "Error" "This script requires Sway window manager"
        exit 1
    fi
}

# Send notification to user
notify_user() {
    local urgency="$1"
    local message="$2"
    
    if command -v notify-send &> /dev/null; then
        notify-send --urgency="$urgency" "Power Menu" "$message"
    elif command -v mako &> /dev/null; then
        echo "$message" | mako
    else
        log_info "Notification: $message"
    fi
}

# Show confirmation dialog for destructive actions
confirm_action() {
    local action="$1"
    local message="$2"
    
    local confirm_options="✅ Yes\n❌ No"
    
    local choice
    choice=$(echo -e "$confirm_options" | wofi "${WOFI_OPTS[@]}" \
        --prompt="$message" --height=150 --width=250)
    
    case "$choice" in
        "✅ Yes")
            log_debug "User confirmed: $action"
            return 0
            ;;
        "❌ No"|"")
            log_debug "User cancelled: $action"
            return 1
            ;;
    esac
}

# Lock screen with fallback options
lock_screen() {
    log_info "Locking screen..."
    
    # Try swaylock first
    if command -v swaylock &> /dev/null; then
        if swaylock; then
            log_debug "Screen locked with swaylock"
            return 0
        else
            log_error "swaylock failed"
        fi
    fi
    
    # Fallback to other lock commands
    for lock_cmd in gtklock waylock; do
        if command -v "$lock_cmd" &> /dev/null; then
            log_info "Falling back to $lock_cmd"
            if "$lock_cmd"; then
                log_debug "Screen locked with $lock_cmd"
                return 0
            fi
        fi
    done
    
    log_error "No working screen lock found"
    notify_user "critical" "Failed to lock screen - no working lock command found"
    return 1
}

# Suspend system
suspend_system() {
    if ! confirm_action "suspend" "Suspend the system?"; then
        return 1
    fi
    
    log_info "Suspending system..."
    
    # Lock screen first
    if ! lock_screen; then
        log_error "Failed to lock screen before suspend"
        notify_user "critical" "Cannot suspend - failed to lock screen"
        return 1
    fi
    
    # Small delay to ensure lock is active
    sleep "$SUSPEND_DELAY"
    
    # Suspend
    if systemctl suspend; then
        log_debug "System suspended successfully"
    else
        log_error "Failed to suspend system"
        notify_user "critical" "Failed to suspend system"
        return 1
    fi
}

# Logout from Sway
logout_sway() {
    if ! confirm_action "logout" "Logout from Sway session?"; then
        return 1
    fi
    
    log_info "Logging out from Sway..."
    
    # Save any unsaved work notification
    notify_user "normal" "Logging out in 3 seconds..."
    sleep 3
    
    if swaymsg exit; then
        log_debug "Sway exit command sent"
    else
        log_error "Failed to exit Sway"
        notify_user "critical" "Failed to logout from Sway"
        return 1
    fi
}

# Shutdown system
shutdown_system() {
    if ! confirm_action "shutdown" "Shutdown the computer?"; then
        return 1
    fi
    
    log_info "Shutting down system..."
    
    # Final warning
    notify_user "critical" "Shutting down in 3 seconds..."
    sleep 3
    
    if systemctl poweroff; then
        log_debug "Shutdown command sent"
    else
        log_error "Failed to shutdown system"
        notify_user "critical" "Failed to shutdown system"
        return 1
    fi
}

# Reboot system
reboot_system() {
    if ! confirm_action "reboot" "Reboot the computer?"; then
        return 1
    fi
    
    log_info "Rebooting system..."
    
    # Final warning
    notify_user "critical" "Rebooting in 3 seconds..."
    sleep 3
    
    if systemctl reboot; then
        log_debug "Reboot command sent"
    else
        log_error "Failed to reboot system"
        notify_user "critical" "Failed to reboot system"
        return 1
    fi
}

# Show power menu and get user selection
show_power_menu() {
    local options=""
    
    # Build options string
    for option in "${!POWER_OPTIONS[@]}"; do
        options+="$option\n"
    done
    
    # Remove trailing newline
    options=${options%\\n}
    
    log_debug "Showing power menu with wofi"
    
    # Show menu and get selection
    local selected
    selected=$(echo -e "$options" | wofi "${WOFI_OPTS[@]}")
    
    if [[ -z "$selected" ]]; then
        log_debug "No selection made or menu cancelled"
        return 1
    fi
    
    echo "${POWER_OPTIONS[$selected]}"
}

# Execute the selected action
execute_action() {
    local action="$1"
    
    log_debug "Executing action: $action"
    
    case "$action" in
        "lock")
            lock_screen
            ;;
        "suspend")
            suspend_system
            ;;
        "logout")
            logout_sway
            ;;
        "shutdown")
            shutdown_system
            ;;
        "reboot")
            reboot_system
            ;;
        "cancel")
            log_debug "User cancelled"
            exit 0
            ;;
        *)
            log_error "Unknown action: $action"
            notify_user "critical" "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Handle script interruption
cleanup() {
    log_debug "Script interrupted, cleaning up..."
    exit 1
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main function
main() {
    log_debug "Starting power menu script"
    
    # Perform checks
    check_dependencies
    check_sway_session
    
    # Show menu and get selection
    local selected_action
    if selected_action=$(show_power_menu); then
        execute_action "$selected_action"
    else
        log_debug "Menu cancelled or no selection made"
        exit 0
    fi
    
    log_debug "Power menu script completed"
}

# Show usage information
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

A robust power menu for Sway window manager with confirmations and error handling.

OPTIONS:
    -h, --help      Show this help message
    -d, --debug     Enable debug output
    --lock-only     Show only lock option (useful for quick access)

ENVIRONMENT VARIABLES:
    DEBUG=1         Enable debug mode
    WOFI_THEME      Custom wofi theme to use

EXAMPLES:
    $SCRIPT_NAME                    # Show full power menu
    $SCRIPT_NAME --lock-only        # Quick lock option only
    DEBUG=1 $SCRIPT_NAME            # Run with debug output

DEPENDENCIES:
    - wofi (application launcher)
    - swaymsg (Sway IPC)
    - systemctl (systemd)
    - swaylock (or compatible screen locker)

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                shift
                ;;
            --lock-only)
                # Override options to show only lock
                POWER_OPTIONS=(
                    ["🔒 Lock Screen"]="lock"
                    ["❌ Cancel"]="cancel"
                )
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    main
fi