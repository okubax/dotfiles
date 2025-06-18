#!/bin/bash

# ISO to USB Bootable Media Creator
# Interactive script to write Linux ISOs to USB drives

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is potentially dangerous."
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check required tools
check_dependencies() {
    local missing_tools=()
    
    # Check for essential tools (lsblk and dd are required)
    for tool in lsblk dd; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Install them with: sudo apt install ${missing_tools[*]} (Debian/Ubuntu)"
        print_info "Or: sudo yum install ${missing_tools[*]} (RHEL/CentOS)"
        exit 1
    fi
    
    # Check for pv (optional but recommended for progress)
    if ! command -v pv &> /dev/null; then
        print_warning "pv (pipe viewer) not found - progress display will be limited"
        print_info "Install with: sudo apt install pv (Debian/Ubuntu) or sudo yum install pv (RHEL/CentOS)"
        print_info "Continuing without pv..."
        echo
    fi
}

# Function to detect USB drives
detect_usb_drives() {
    print_info "Detecting USB drives..."
    
    # Get removable block devices
    local usb_drives=($(lsblk -d -o NAME,SIZE,MODEL,TRAN | grep usb | awk '{print $1}'))
    
    if [[ ${#usb_drives[@]} -eq 0 ]]; then
        print_error "No USB drives detected!"
        exit 1
    fi
    
    echo
    print_info "Available USB drives:"
    echo "----------------------------------------"
    printf "%-4s %-10s %-8s %-20s\n" "NUM" "DEVICE" "SIZE" "MODEL"
    echo "----------------------------------------"
    
    local i=1
    for drive in "${usb_drives[@]}"; do
        local info=$(lsblk -d -o SIZE,MODEL "/dev/$drive" | tail -n 1)
        printf "%-4s %-10s %s\n" "$i" "/dev/$drive" "$info"
        ((i++))
    done
    echo "----------------------------------------"
    
    # Let user select USB drive
    while true; do
        read -p "Select USB drive (1-${#usb_drives[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#usb_drives[@]} ]]; then
            selected_drive="/dev/${usb_drives[$((selection-1))]}"
            break
        else
            print_error "Invalid selection. Please choose 1-${#usb_drives[@]}"
        fi
    done
    
    print_info "Selected: $selected_drive"
}

# Function to select ISO file
select_iso() {
    print_info "Select ISO file..."
    
    # Check for ISO files in current directory
    local iso_files=($(find . -maxdepth 1 -name "*.iso" -type f 2>/dev/null))
    
    if [[ ${#iso_files[@]} -gt 0 ]]; then
        echo
        print_info "ISO files found in current directory:"
        echo "----------------------------------------"
        printf "%-4s %-50s %-10s\n" "NUM" "FILENAME" "SIZE"
        echo "----------------------------------------"
        
        local i=1
        for iso in "${iso_files[@]}"; do
            local size=$(du -h "$iso" | cut -f1)
            printf "%-4s %-50s %-10s\n" "$i" "$(basename "$iso")" "$size"
            ((i++))
        done
        echo "----------------------------------------"
        
        read -p "Select ISO file (1-${#iso_files[@]}) or enter path manually (m): " iso_selection
        
        if [[ "$iso_selection" == "m" ]] || [[ "$iso_selection" == "M" ]]; then
            read -p "Enter full path to ISO file: " selected_iso
        elif [[ "$iso_selection" =~ ^[0-9]+$ ]] && [[ "$iso_selection" -ge 1 ]] && [[ "$iso_selection" -le ${#iso_files[@]} ]]; then
            selected_iso="${iso_files[$((iso_selection-1))]}"
        else
            print_error "Invalid selection"
            exit 1
        fi
    else
        read -p "Enter full path to ISO file: " selected_iso
    fi
    
    # Verify ISO file exists and is readable
    if [[ ! -f "$selected_iso" ]]; then
        print_error "ISO file not found: $selected_iso"
        exit 1
    fi
    
    if [[ ! -r "$selected_iso" ]]; then
        print_error "Cannot read ISO file: $selected_iso"
        exit 1
    fi
    
    print_info "Selected ISO: $selected_iso"
}

# Function to show final confirmation
confirm_operation() {
    local iso_size=$(du -h "$selected_iso" | cut -f1)
    local drive_info=$(lsblk -d -o SIZE,MODEL "$selected_drive" | tail -n 1)
    
    echo
    print_warning "=== FINAL CONFIRMATION ==="
    echo "ISO file: $selected_iso ($iso_size)"
    echo "Target USB: $selected_drive ($drive_info)"
    echo
    print_warning "THIS WILL COMPLETELY ERASE ALL DATA ON $selected_drive"
    print_warning "THIS OPERATION CANNOT BE UNDONE!"
    echo
    
    read -p "Are you absolutely sure? Type 'YES' to continue: " confirmation
    if [[ "$confirmation" != "YES" ]]; then
        print_info "Operation cancelled."
        exit 0
    fi
}

# Function to unmount USB drive
unmount_usb() {
    print_info "Unmounting USB drive partitions..."
    
    # Find and unmount all partitions on the drive
    local partitions=$(lsblk -ln -o NAME "$selected_drive" | tail -n +2)
    
    for partition in $partitions; do
        if mountpoint -q "/dev/$partition" 2>/dev/null; then
            print_info "Unmounting /dev/$partition"
            sudo umount "/dev/$partition" 2>/dev/null || true
        fi
    done
    
    # Additional safety check
    sleep 2
}

# Function to write ISO to USB with progress
write_iso() {
    print_info "Writing ISO to USB drive..."
    print_info "This may take several minutes depending on ISO size and USB speed."
    
    local iso_size=$(stat -c%s "$selected_iso")
    local iso_size_mb=$((iso_size / 1024 / 1024))
    
    echo
    print_info "ISO size: ${iso_size_mb}MB"
    print_info "Starting write operation..."
    echo
    
    # Use different methods based on available tools
    if command -v pv &> /dev/null; then
        # Method 1: Use pv with dd for best progress display
        print_info "Using pv for progress display:"
        sudo sh -c "pv -p -t -e -r -b '$selected_iso' | dd of='$selected_drive' bs=4M oflag=sync,direct 2>/dev/null"
    else
        # Method 2: Use dd with progress (modern versions)
        if dd --help 2>&1 | grep -q "status=progress"; then
            print_info "Using dd with progress display:"
            sudo dd if="$selected_iso" of="$selected_drive" bs=4M status=progress oflag=sync,direct
        else
            # Method 3: Fallback for older dd versions
            print_info "Using dd (no progress available on this system):"
            print_info "Please wait... (this may take several minutes)"
            
            # Show periodic updates
            (
                while kill -0 $ 2>/dev/null; do
                    sleep 10
                    if pgrep -f "dd.*$selected_drive" >/dev/null; then
                        print_info "Still writing... ($(date '+%H:%M:%S'))"
                    fi
                done
            ) &
            local monitor_pid=$!
            
            sudo dd if="$selected_iso" of="$selected_drive" bs=4M oflag=sync,direct 2>/dev/null
            
            # Stop the monitor
            kill $monitor_pid 2>/dev/null || true
        fi
    fi
    
    echo
    print_info "Write completed. Syncing data to ensure all data is written..."
    sudo sync
    sleep 2
    
    print_success "ISO successfully written to USB drive!"
}

# Function to verify the write operation
verify_write() {
    read -p "Would you like to verify the written data? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Verifying written data..."
        print_info "This will take some time..."
        
        local iso_size=$(stat -c%s "$selected_iso")
        local blocks=$((iso_size / 4194304))  # 4M blocks
        
        if sudo cmp -n "$iso_size" "$selected_iso" "$selected_drive"; then
            print_success "Verification successful! Data written correctly."
        else
            print_error "Verification failed! Data may be corrupted."
            exit 1
        fi
    fi
}

# Function to eject USB drive
eject_usb() {
    read -p "Would you like to safely eject the USB drive? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Ejecting USB drive..."
        sudo eject "$selected_drive" 2>/dev/null || print_warning "Could not eject drive automatically"
        print_info "You can now safely remove the USB drive."
    fi
}

# Main function
main() {
    clear
    echo "============================================"
    echo "  ISO to USB Bootable Media Creator"
    echo "============================================"
    echo
    
    # Check if running as root
    check_root
    
    # Check dependencies
    check_dependencies
    
    # Detect USB drives
    detect_usb_drives
    
    # Select ISO file
    select_iso
    
    # Final confirmation
    confirm_operation
    
    # Unmount USB drive
    unmount_usb
    
    # Write ISO to USB
    write_iso
    
    # Verify write (optional)
    verify_write
    
    # Eject USB (optional)
    eject_usb
    
    echo
    print_success "Bootable USB creation completed successfully!"
    print_info "Your USB drive is now ready to boot."
}

# Trap Ctrl+C
trap 'echo; print_info "Operation cancelled by user."; exit 1' INT

# Run main function
main "$@"