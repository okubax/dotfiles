#!/bin/bash

# Comprehensive System Information Script for Arch Linux + Sway
# Enhanced version with HTML output, advanced filesystem support, and extensive monitoring
# Author: Enhanced for Arch Linux with SwayWM/Wayland
# Usage: ./sysinfo.sh [--json|--html] [--brief] [--help] [--save] [--compare]

# Version and metadata
SCRIPT_VERSION="3.0"
SCRIPT_NAME="ArchSway System Info Enhanced"

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables - Initialize all at once
JSON_OUTPUT=false
HTML_OUTPUT=false
BRIEF_MODE=false
SAVE_OUTPUT=false
COMPARE_MODE=false
VERBOSE_MODE=false
SKIP_FILESYSTEM=false
OUTPUT_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/sysinfo_$$"
CONFIG_DIR="$HOME/.config/sysinfo"
CACHE_DIR="$CONFIG_DIR/cache"

# Create necessary directories
mkdir -p "$CONFIG_DIR" "$TEMP_DIR" "$CACHE_DIR"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Error function
show_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Warning function
show_warning() {
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

# Progress indicator
show_progress() {
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]] && [[ "$VERBOSE_MODE" == true ]]; then
        echo -e "${YELLOW}[INFO]${NC} $1" >&2
    fi
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Function to safely execute commands with sudo
safe_sudo() {
    if sudo -n true 2>/dev/null; then
        sudo "$@"
    else
        if [[ "$HTML_OUTPUT" == false ]] && [[ "$JSON_OUTPUT" == false ]]; then
            echo -e "${YELLOW}[SUDO REQUIRED]${NC} $*"
        fi
        sudo "$@"
    fi
}

# Function to get human readable sizes
human_readable() {
    numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "$1"
}

# Function to calculate percentage
calculate_percentage() {
    local used=$1
    local total=$2
    if [[ $total -gt 0 ]]; then
        echo $(( (used * 100) / total ))
    else
        echo "0"
    fi
}

# HTML Generation Functions
html_start() {
    if [[ "$HTML_OUTPUT" == true ]]; then
        local current_date=$(date '+%Y-%m-%d %H:%M:%S %Z')
        cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Information Report</title>
    <style>
        :root {
            --bg-primary: #1a1a1a;
            --bg-secondary: #2d2d2d;
            --bg-tertiary: #3d3d3d;
            --text-primary: #ffffff;
            --text-secondary: #cccccc;
            --accent: #00d4aa;
            --accent-secondary: #ff6b6b;
            --border: #4a4a4a;
            --success: #51cf66;
            --warning: #ffd43b;
            --error: #ff6b6b;
        }
        
        .light-theme {
            --bg-primary: #ffffff;
            --bg-secondary: #f8f9fa;
            --bg-tertiary: #e9ecef;
            --text-primary: #212529;
            --text-secondary: #6c757d;
            --border: #dee2e6;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
            transition: all 0.3s ease;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 2rem;
            padding: 2rem;
            background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
            border-radius: 10px;
            color: white;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }
        
        .header .subtitle {
            font-size: 1.2rem;
            opacity: 0.9;
        }
        
        .controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding: 1rem;
            background-color: var(--bg-secondary);
            border-radius: 8px;
        }
        
        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 0.9rem;
            transition: all 0.3s ease;
        }
        
        .btn-primary {
            background-color: var(--accent);
            color: white;
        }
        
        .btn-primary:hover {
            background-color: var(--accent-secondary);
        }
        
        .section {
            background-color: var(--bg-secondary);
            border-radius: 10px;
            margin-bottom: 1.5rem;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .section-header {
            background-color: var(--bg-tertiary);
            padding: 1rem 1.5rem;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border);
        }
        
        .section-header:hover {
            background-color: var(--accent);
            color: white;
        }
        
        .section-title {
            font-size: 1.3rem;
            font-weight: 600;
        }
        
        .collapse-icon {
            transition: transform 0.3s ease;
        }
        
        .collapsed .collapse-icon {
            transform: rotate(-90deg);
        }
        
        .section-content {
            padding: 1.5rem;
            display: block;
        }
        
        .collapsed .section-content {
            display: none;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1rem;
        }
        
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 0.5rem 0;
            border-bottom: 1px solid var(--border);
        }
        
        .info-label {
            font-weight: 600;
            color: var(--accent);
        }
        
        .info-value {
            color: var(--text-secondary);
            text-align: right;
        }
        
        .progress-bar {
            width: 100%;
            height: 20px;
            background-color: var(--bg-tertiary);
            border-radius: 10px;
            overflow: hidden;
            margin: 0.5rem 0;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--success), var(--warning));
            transition: width 0.3s ease;
        }
        
        .progress-high {
            background: linear-gradient(90deg, var(--warning), var(--error)) !important;
        }
        
        .health-score {
            font-size: 2rem;
            font-weight: bold;
            text-align: center;
            padding: 1rem;
            border-radius: 10px;
            margin: 1rem 0;
        }
        
        .health-excellent { background-color: var(--success); color: white; }
        .health-good { background-color: var(--warning); color: white; }
        .health-poor { background-color: var(--error); color: white; }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
        }
        
        th, td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        
        th {
            background-color: var(--bg-tertiary);
            font-weight: 600;
            color: var(--accent);
        }
        
        .status-active { color: var(--success); }
        .status-inactive { color: var(--error); }
        .status-warning { color: var(--warning); }
        
        @media (max-width: 768px) {
            .container { padding: 10px; }
            .header h1 { font-size: 2rem; }
            .info-grid { grid-template-columns: 1fr; }
            .controls { flex-direction: column; gap: 1rem; }
        }
        
        @media print {
            .controls, .btn { display: none; }
            .section { break-inside: avoid; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>System Information Report</h1>
            <div class="subtitle">Generated on ${current_date}</div>
        </div>
        
        <div class="controls">
            <div>
                <button class="btn btn-primary" onclick="toggleTheme()">Toggle Theme</button>
                <button class="btn btn-primary" onclick="toggleAllSections()">Expand/Collapse All</button>
                <button class="btn btn-primary" onclick="window.print()">Print Report</button>
            </div>
        </div>
EOF
    fi
}

html_end() {
    if [[ "$HTML_OUTPUT" == true ]]; then
        cat << 'EOF'
    </div>
    
    <script>
        let allCollapsed = false;
        
        function toggleTheme() {
            document.body.classList.toggle('light-theme');
        }
        
        function toggleSection(element) {
            element.parentElement.classList.toggle('collapsed');
        }
        
        function toggleAllSections() {
            const sections = document.querySelectorAll('.section');
            sections.forEach(section => {
                if (allCollapsed) {
                    section.classList.remove('collapsed');
                } else {
                    section.classList.add('collapsed');
                }
            });
            allCollapsed = !allCollapsed;
        }
        
        // Make sections collapsible
        document.addEventListener('DOMContentLoaded', function() {
            const headers = document.querySelectorAll('.section-header');
            headers.forEach(header => {
                header.addEventListener('click', () => toggleSection(header));
            });
        });
    </script>
</body>
</html>
EOF
    fi
}

html_section() {
    if [[ "$HTML_OUTPUT" == true ]]; then
        cat << EOF
        <div class="section">
            <div class="section-header">
                <div class="section-title">$1</div>
                <div class="collapse-icon">▼</div>
            </div>
            <div class="section-content">
EOF
    fi
}

html_section_end() {
    if [[ "$HTML_OUTPUT" == true ]]; then
        echo "            </div>"
        echo "        </div>"
    fi
}

html_info_item() {
    if [[ "$HTML_OUTPUT" == true ]]; then
        cat << EOF
                <div class="info-item">
                    <div class="info-label">$1</div>
                    <div class="info-value">$2</div>
                </div>
EOF
    fi
}

html_progress_bar() {
    local percentage=$1
    local label=$2
    local class=""
    
    if [[ $percentage -gt 80 ]]; then
        class="progress-high"
    fi
    
    if [[ "$HTML_OUTPUT" == true ]]; then
        cat << EOF
                <div class="info-item">
                    <div class="info-label">$label</div>
                    <div class="info-value">${percentage}%</div>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill $class" style="width: ${percentage}%"></div>
                </div>
EOF
    fi
}

html_health_score() {
    local score=$1
    local class="health-excellent"
    
    if [[ $score -lt 70 ]]; then
        class="health-poor"
    elif [[ $score -lt 85 ]]; then
        class="health-good"
    fi
    
    if [[ "$HTML_OUTPUT" == true ]]; then
        cat << EOF
                <div class="health-score $class">
                    Health Score: $score/100
                </div>
EOF
    fi
}

# JSON helper functions
json_start() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "{"
    fi
}

json_end() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "}"
    fi
}

json_section() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "  \"$1\": {"
    fi
}

json_section_end() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "  },"
    fi
}

json_field() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "    \"$1\": \"$2\","
    fi
}

# Console output functions
print_header() {
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║${NC}${WHITE}%-62s${NC}${BLUE}║${NC}\n" " $1"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    fi
}

print_subheader() {
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "\n${CYAN}┌─ $1 ─────────────────────────────────────────────────────┐${NC}"
    fi
}

# Enhanced temperature monitoring
get_temperatures() {
    local temps=()
    
    # Try multiple temperature sources
    if command_exists sensors; then
        while IFS= read -r line; do
            if [[ $line =~ \+([0-9]+\.[0-9]+)°C ]]; then
                temps+=("${BASH_REMATCH[1]}°C")
            fi
        done < <(sensors 2>/dev/null)
    fi
    
    # Thermal zones
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            local temp=$(cat "$zone" 2>/dev/null || echo "0")
            if [[ "$temp" != "0" ]]; then
                temps+=("$((temp / 1000))°C")
            fi
        fi
    done
    
    printf '%s\n' "${temps[@]}" | head -5
}

# Btrfs specific information - improved parsing
get_btrfs_info() {
    echo "Btrfs Filesystem Analysis:"
    
    # Check if btrfs tools are available
    if ! command_exists btrfs; then
        echo "  Btrfs tools not installed"
        return 1
    fi
    
    # Find btrfs filesystems using a more reliable method
    local btrfs_found=false
    
    # Check mounted btrfs filesystems
    if mount | grep -q btrfs; then
        btrfs_found=true
        echo "  Btrfs filesystems detected:"
        
        # Parse mount output more carefully
        mount | grep btrfs | while IFS= read -r line; do
            # Extract device and mount point from mount output
            # Format: /dev/device on /mount/point type btrfs (options)
            local device=$(echo "$line" | awk '{print $1}')
            local mount_point=$(echo "$line" | sed 's/.* on \([^ ]*\) type btrfs.*/\1/')
            
            echo "    Device: $device"
            echo "    Mount: $mount_point"
            
            # Try to get subvolume information
            if [[ -n "$mount_point" ]] && [[ -d "$mount_point" ]]; then
                echo "    Analyzing subvolumes..."
                
                # Get subvolumes with error handling
                local subvol_output
                if subvol_output=$(btrfs subvolume list "$mount_point" 2>/dev/null); then
                    if [[ -n "$subvol_output" ]]; then
                        local subvol_count=$(echo "$subvol_output" | wc -l)
                        echo "      Total subvolumes: $subvol_count"
                        
                        # Show first few subvolumes
                        echo "      Subvolumes:"
                        echo "$subvol_output" | head -5 | while IFS= read -r subvol_line; do
                            if [[ -n "$subvol_line" ]]; then
                                local subvol_id=$(echo "$subvol_line" | awk '{print $2}')
                                local subvol_path=$(echo "$subvol_line" | awk '{print $NF}')
                                echo "        ID $subvol_id: $subvol_path"
                            fi
                        done
                    else
                        echo "      No subvolumes found"
                    fi
                else
                    echo "      Unable to list subvolumes (permission denied or error)"
                fi
                
                # Check for snapshots
                local snapshot_output
                if snapshot_output=$(btrfs subvolume list -s "$mount_point" 2>/dev/null); then
                    if [[ -n "$snapshot_output" ]]; then
                        local snapshot_count=$(echo "$snapshot_output" | wc -l)
                        echo "      Snapshots: $snapshot_count found"
                        echo "$snapshot_output" | head -3 | while IFS= read -r snap_line; do
                            if [[ -n "$snap_line" ]]; then
                                local snap_id=$(echo "$snap_line" | awk '{print $2}')
                                local snap_path=$(echo "$snap_line" | awk '{print $NF}')
                                echo "        ID $snap_id: $snap_path"
                            fi
                        done
                    else
                        echo "      No snapshots found"
                    fi
                else
                    echo "      Unable to check snapshots"
                fi
                
                # Check compression
                local compression
                if compression=$(btrfs property get "$mount_point" compression 2>/dev/null); then
                    echo "      Compression: ${compression:-none}"
                else
                    echo "      Compression: Unable to determine"
                fi
                
                echo ""
            else
                echo "    Mount point not accessible: $mount_point"
                echo ""
            fi
        done
    fi
    
    if [[ "$btrfs_found" == false ]]; then
        echo "  No Btrfs filesystems detected"
    fi
}

# Ext4 specific information - improved
get_ext4_info() {
    echo "Ext4 Filesystem Analysis:"
    
    # Check for Ext4 filesystems
    if mount | grep -q ext4; then
        echo "  Ext4 filesystems detected:"
        
        mount | grep ext4 | while IFS= read -r line; do
            # Extract device and mount point from mount output
            local device=$(echo "$line" | awk '{print $1}')
            local mount_point=$(echo "$line" | sed 's/.* on \([^ ]*\) type ext4.*/\1/')
            
            echo "    Device: $device"
            echo "    Mount: $mount_point"
            
            # Get filesystem info if tune2fs is available
            if command_exists tune2fs; then
                echo "    Filesystem info:"
                local fs_info
                if fs_info=$(tune2fs -l "$device" 2>/dev/null); then
                    echo "$fs_info" | grep -E "Filesystem features|Block size|Inode count" | head -3 | while IFS= read -r info_line; do
                        echo "      $info_line"
                    done
                else
                    echo "      Unable to get filesystem details"
                fi
            fi
            
            # Get inode usage
            if command_exists df; then
                echo "    Inode usage:"
                df -i "$mount_point" 2>/dev/null | tail -1 | awk '{printf "      Used: %s, Available: %s, Use%%: %s\n", $3, $4, $5}' || echo "      Unable to get inode info"
            fi
            
            echo ""
        done
    else
        echo "  No Ext4 filesystems detected"
    fi
}

# System health check
system_health_check() {
    print_header "SYSTEM HEALTH CHECK"
    html_section "System Health Check"
    json_section "health"
    
    local health_score=100
    local issues=()
    local warnings=()
    
    # Check disk space
    local root_usage=$(df / | awk 'NR==2 {print substr($5, 1, length($5)-1)}')
    if [[ $root_usage -gt 95 ]]; then
        issues+=("Root filesystem >95% full")
        health_score=$((health_score - 25))
    elif [[ $root_usage -gt 90 ]]; then
        issues+=("Root filesystem >90% full")
        health_score=$((health_score - 15))
    elif [[ $root_usage -gt 80 ]]; then
        warnings+=("Root filesystem >80% full")
        health_score=$((health_score - 5))
    fi
    
    # Check memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ $mem_usage -gt 95 ]]; then
        issues+=("Memory usage >95%")
        health_score=$((health_score - 20))
    elif [[ $mem_usage -gt 85 ]]; then
        warnings+=("Memory usage >85%")
        health_score=$((health_score - 10))
    fi
    
    # Check load average
    local load_1min=$(cut -d' ' -f1 /proc/loadavg)
    local cpu_cores=$(nproc)
    local load_per_core=$(awk "BEGIN {printf \"%.2f\", $load_1min / $cpu_cores}")
    local load_high=$(awk "BEGIN {print ($load_per_core > 3.0) ? 1 : 0}")
    if [[ "$load_high" == "1" ]]; then
        issues+=("Very high system load: $load_per_core per core")
        health_score=$((health_score - 15))
    fi
    
    # Check failed services
    if command_exists systemctl; then
        local failed_count=$(systemctl --failed --no-legend | wc -l)
        if [[ $failed_count -gt 0 ]]; then
            issues+=("$failed_count failed services")
            health_score=$((health_score - 10))
        fi
    fi
    
    # Display results
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "${GREEN}Health Score:${NC} $health_score/100"
        
        if [[ ${#issues[@]} -eq 0 ]] && [[ ${#warnings[@]} -eq 0 ]]; then
            echo -e "${GREEN}Status:${NC} All systems operational ✓"
        else
            if [[ ${#issues[@]} -gt 0 ]]; then
                echo -e "${RED}Critical Issues:${NC}"
                for issue in "${issues[@]}"; do
                    echo "  ❌ $issue"
                done
            fi
            
            if [[ ${#warnings[@]} -gt 0 ]]; then
                echo -e "${YELLOW}Warnings:${NC}"
                for warning in "${warnings[@]}"; do
                    echo "  ⚠️  $warning"
                done
            fi
        fi
    elif [[ "$HTML_OUTPUT" == true ]]; then
        html_health_score "$health_score"
        html_progress_bar "$root_usage" "Disk Usage"
        html_progress_bar "$mem_usage" "Memory Usage"
        
        if [[ ${#issues[@]} -gt 0 ]]; then
            echo "                <h4 style='color: var(--error);'>Critical Issues:</h4>"
            echo "                <ul>"
            for issue in "${issues[@]}"; do
                echo "                    <li style='color: var(--error);'>$issue</li>"
            done
            echo "                </ul>"
        fi
        
        if [[ ${#warnings[@]} -gt 0 ]]; then
            echo "                <h4 style='color: var(--warning);'>Warnings:</h4>"
            echo "                <ul>"
            for warning in "${warnings[@]}"; do
                echo "                    <li style='color: var(--warning);'>$warning</li>"
            done
            echo "                </ul>"
        fi
    else
        json_field "health_score" "$health_score"
        json_field "disk_usage_percent" "$root_usage"
        json_field "memory_usage_percent" "$mem_usage"
        json_field "critical_issues_count" "${#issues[@]}"
        json_field "warnings_count" "${#warnings[@]}"
    fi
    
    json_section_end
    html_section_end
}

# System Basic Information
get_system_info() {
    print_header "SYSTEM INFORMATION"
    html_section "System Information"
    json_section "system"
    show_progress "Gathering system information..."
    
    # Basic system info
    local hostname=$(hostname)
    local username=$(whoami)
    local uptime_info=$(uptime -p)
    local current_date=$(date '+%Y-%m-%d %H:%M:%S %Z')
    
    # System load
    local load_1min load_5min load_15min
    read load_1min load_5min load_15min < /proc/loadavg
    
    # Distribution Info
    local distro_info=""
    local kernel_version=$(uname -r)
    local architecture=$(uname -m)
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro_info="$PRETTY_NAME"
    fi
    
    # Output information
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "${GREEN}Hostname:${NC} $hostname"
        echo -e "${GREEN}Username:${NC} $username (UID: $UID)"
        echo -e "${GREEN}Distribution:${NC} $distro_info"
        echo -e "${GREEN}Kernel:${NC} $kernel_version"
        echo -e "${GREEN}Architecture:${NC} $architecture"
        echo -e "${GREEN}Uptime:${NC} $uptime_info"
        echo -e "${GREEN}Load Average:${NC} $load_1min, $load_5min, $load_15min"
        echo -e "${GREEN}Current Time:${NC} $current_date"
    elif [[ "$HTML_OUTPUT" == true ]]; then
        echo "                <div class=\"info-grid\">"
        html_info_item "Hostname" "$hostname"
        html_info_item "Username" "$username (UID: $UID)"
        html_info_item "Distribution" "$distro_info"
        html_info_item "Kernel" "$kernel_version"
        html_info_item "Architecture" "$architecture"
        html_info_item "Uptime" "$uptime_info"
        html_info_item "Load Average" "$load_1min, $load_5min, $load_15min"
        html_info_item "Current Time" "$current_date"
        echo "                </div>"
    else
        json_field "hostname" "$hostname"
        json_field "username" "$username"
        json_field "distribution" "$distro_info"
        json_field "kernel" "$kernel_version"
        json_field "architecture" "$architecture"
        json_field "uptime" "$uptime_info"
        json_field "current_time" "$current_date"
    fi
    
    json_section_end
    html_section_end
}

# CPU Information
get_cpu_info() {
    print_header "CPU INFORMATION"
    html_section "CPU Information"
    json_section "cpu"
    show_progress "Analyzing CPU..."
    
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
        local cpu_vendor=$(grep "vendor_id" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
        local cpu_cores=$(nproc)
        local cpu_threads=$(grep -c "processor" /proc/cpuinfo)
        
        # CPU Usage
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' 2>/dev/null || echo "0")
        
        # Temperature
        local cpu_temps=()
        readarray -t cpu_temps < <(get_temperatures)
        local avg_temp="N/A"
        if [[ ${#cpu_temps[@]} -gt 0 ]]; then
            avg_temp="${cpu_temps[0]}"
        fi
        
        # Output CPU information
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo -e "${GREEN}Vendor:${NC} $cpu_vendor"
            echo -e "${GREEN}Model:${NC} $cpu_model"
            echo -e "${GREEN}Cores:${NC} $cpu_cores"
            echo -e "${GREEN}Threads:${NC} $cpu_threads"
            echo -e "${GREEN}Usage:${NC} ${cpu_usage}%"
            echo -e "${GREEN}Temperature:${NC} $avg_temp"
        elif [[ "$HTML_OUTPUT" == true ]]; then
            echo "                <div class=\"info-grid\">"
            html_info_item "Vendor" "$cpu_vendor"
            html_info_item "Model" "$cpu_model"
            html_info_item "Cores" "$cpu_cores"
            html_info_item "Threads" "$cpu_threads"
            html_info_item "Temperature" "$avg_temp"
            echo "                </div>"
            
            local usage_int=$(printf "%.0f" "$cpu_usage")
            html_progress_bar "$usage_int" "CPU Usage"
        else
            json_field "vendor" "$cpu_vendor"
            json_field "model" "$cpu_model"
            json_field "cores" "$cpu_cores"
            json_field "threads" "$cpu_threads"
            json_field "usage_percent" "$cpu_usage"
            json_field "temperature" "$avg_temp"
        fi
    fi
    
    json_section_end
    html_section_end
}

# Memory Information
get_memory_info() {
    print_header "MEMORY INFORMATION"
    html_section "Memory Information"
    json_section "memory"
    show_progress "Analyzing memory..."
    
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        local mem_available=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
        local mem_used=$((mem_total - mem_available))
        local swap_total=$(grep "SwapTotal" /proc/meminfo | awk '{print $2}')
        local swap_free=$(grep "SwapFree" /proc/meminfo | awk '{print $2}')
        local swap_used=$((swap_total - swap_free))
        
        # Calculate percentages
        local mem_usage_percent=$(calculate_percentage $mem_used $mem_total)
        local swap_usage_percent=0
        if [[ $swap_total -gt 0 ]]; then
            swap_usage_percent=$(calculate_percentage $swap_used $swap_total)
        fi
        
        # Convert to human readable
        local mem_total_hr=$(human_readable $((mem_total * 1024)))
        local mem_used_hr=$(human_readable $((mem_used * 1024)))
        local mem_available_hr=$(human_readable $((mem_available * 1024)))
        
        # Output memory information
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo -e "${GREEN}Total RAM:${NC} $mem_total_hr"
            echo -e "${GREEN}Used RAM:${NC} $mem_used_hr (${mem_usage_percent}%)"
            echo -e "${GREEN}Available RAM:${NC} $mem_available_hr"
            
            if [[ "$swap_total" -gt 0 ]]; then
                local swap_total_hr=$(human_readable $((swap_total * 1024)))
                local swap_used_hr=$(human_readable $((swap_used * 1024)))
                echo -e "${GREEN}Total Swap:${NC} $swap_total_hr"
                echo -e "${GREEN}Used Swap:${NC} $swap_used_hr (${swap_usage_percent}%)"
            else
                echo -e "${GREEN}Swap:${NC} Not configured"
            fi
        elif [[ "$HTML_OUTPUT" == true ]]; then
            echo "                <div class=\"info-grid\">"
            html_info_item "Total RAM" "$mem_total_hr"
            html_info_item "Available RAM" "$mem_available_hr"
            
            if [[ "$swap_total" -gt 0 ]]; then
                local swap_total_hr=$(human_readable $((swap_total * 1024)))
                html_info_item "Total Swap" "$swap_total_hr"
            else
                html_info_item "Swap" "Not configured"
            fi
            echo "                </div>"
            
            # Add memory usage progress bars
            html_progress_bar "$mem_usage_percent" "Memory Usage"
            if [[ "$swap_total" -gt 0 ]]; then
                html_progress_bar "$swap_usage_percent" "Swap Usage"
            fi
        else
            json_field "total_ram" "$mem_total_hr"
            json_field "used_ram" "$mem_used_hr"
            json_field "available_ram" "$mem_available_hr"
            json_field "memory_usage_percent" "$mem_usage_percent"
            json_field "total_swap" "$(human_readable $((swap_total * 1024)))"
            json_field "swap_usage_percent" "$swap_usage_percent"
        fi
    fi
    
    json_section_end
    html_section_end
}

# Disk Information
get_disk_info() {
    print_header "DISK INFORMATION"
    html_section "Disk Information"
    json_section "disk"
    show_progress "Analyzing storage..."
    
    print_subheader "Mounted Filesystems"
    if [[ "$HTML_OUTPUT" == true ]]; then
        echo "                <table>"
        echo "                    <thead><tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Available</th><th>Use%</th><th>Mounted on</th></tr></thead>"
        echo "                    <tbody>"
        
        df -h --type=ext4 --type=ext3 --type=ext2 --type=btrfs --type=xfs --type=zfs --type=f2fs | grep -v "tmpfs" | tail -n +2 | while read -r line; do
            local filesystem=$(echo "$line" | awk '{print $1}')
            local size=$(echo "$line" | awk '{print $2}')
            local used=$(echo "$line" | awk '{print $3}')
            local available=$(echo "$line" | awk '{print $4}')
            local use_percent=$(echo "$line" | awk '{print $5}')
            local mounted=$(echo "$line" | awk '{print $6}')
            
            echo "                        <tr><td>$filesystem</td><td>$size</td><td>$used</td><td>$available</td><td>$use_percent</td><td>$mounted</td></tr>"
        done
        
        echo "                    </tbody>"
        echo "                </table>"
    elif [[ "$JSON_OUTPUT" == false ]]; then
        df -h --type=ext4 --type=ext3 --type=ext2 --type=btrfs --type=xfs --type=zfs --type=f2fs | grep -v "tmpfs"
    fi
    
    # Block devices
    print_subheader "Block Devices"
    if command_exists lsblk; then
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
        fi
    fi
    
    # Enhanced filesystem analysis - direct function calls
    if [[ "$BRIEF_MODE" == false ]] && [[ "$SKIP_FILESYSTEM" == false ]]; then
        print_subheader "Filesystem Analysis"
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo "Analyzing filesystems..."
            
            # Direct Btrfs analysis
            get_btrfs_info
            
            echo ""
            
            # Direct Ext4 analysis  
            get_ext4_info
        elif [[ "$HTML_OUTPUT" == true ]]; then
            echo "                <h4>Btrfs Information</h4>"
            echo "                <pre>"
            get_btrfs_info | sed 's/^/                /'
            echo "                </pre>"
            echo "                <h4>Ext4 Information</h4>"
            echo "                <pre>"
            get_ext4_info | sed 's/^/                /'
            echo "                </pre>"
        fi
    elif [[ "$SKIP_FILESYSTEM" == true ]]; then
        print_subheader "Filesystem Analysis"
        echo "Filesystem analysis skipped (--skip-fs flag used)"
    fi
    
    json_section_end
    html_section_end
}

# Network Information
get_network_info() {
    print_header "NETWORK INFORMATION"
    html_section "Network Information"
    json_section "network"
    show_progress "Analyzing network..."
    
    # Network interfaces
    print_subheader "Network Interfaces"
    if command_exists ip; then
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            ip addr show | grep -E "^[0-9]+:|inet "
        elif [[ "$HTML_OUTPUT" == true ]]; then
            echo "                <table>"
            echo "                    <thead><tr><th>Interface</th><th>Type</th><th>State</th><th>IP Address</th></tr></thead>"
            echo "                    <tbody>"
            
            ip addr show | grep -E "^[0-9]+:" | while read -r line; do
                local interface=$(echo "$line" | awk '{print $2}' | tr -d ':')
                local state=$(echo "$line" | grep -o "state [A-Z]*" | awk '{print $2}')
                local ip=$(ip addr show "$interface" | grep "inet " | head -1 | awk '{print $2}' | cut -d'/' -f1)
                local type="Ethernet"
                
                if [[ $interface =~ ^wl ]]; then
                    type="WiFi"
                elif [[ $interface =~ ^lo ]]; then
                    type="Loopback"
                fi
                
                local state_class="status-active"
                if [[ "$state" != "UP" ]]; then
                    state_class="status-inactive"
                fi
                
                echo "                        <tr><td>$interface</td><td>$type</td><td class=\"$state_class\">$state</td><td>$ip</td></tr>"
            done
            
            echo "                    </tbody>"
            echo "                </table>"
        fi
    fi
    
    # Connectivity test
    if [[ "$BRIEF_MODE" == false ]]; then
        print_subheader "Connectivity Test"
        local connectivity="FAILED"
        if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
            connectivity="OK"
        fi
        
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            if [[ "$connectivity" == "OK" ]]; then
                echo -e "${GREEN}Internet connectivity: OK${NC}"
            else
                echo -e "${RED}Internet connectivity: FAILED${NC}"
            fi
        elif [[ "$HTML_OUTPUT" == true ]]; then
            local status_class="status-active"
            if [[ "$connectivity" == "FAILED" ]]; then
                status_class="status-inactive"
            fi
            html_info_item "Internet Connectivity" "<span class='$status_class'>$connectivity</span>"
        else
            json_field "internet_connectivity" "$connectivity"
        fi
    fi
    
    json_section_end
    html_section_end
}

# Graphics Information
get_graphics_info() {
    print_header "GRAPHICS INFORMATION"
    html_section "Graphics Information"
    json_section "graphics"
    show_progress "Analyzing graphics..."
    
    # GPU Information
    if command_exists lspci; then
        local gpu_info=$(lspci | grep -i "vga\|3d\|display")
        
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo -e "${GREEN}GPU:${NC} $gpu_info"
        elif [[ "$HTML_OUTPUT" == true ]]; then
            html_info_item "GPU Hardware" "$gpu_info"
        else
            json_field "gpu" "$gpu_info"
        fi
    fi
    
    # Enhanced display server detection
    local display_server="Unknown"
    local window_manager="Unknown"
    local session_type="${XDG_SESSION_TYPE:-Unknown}"
    
    # Check for Wayland first (more reliable)
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ "$session_type" == "wayland" ]] || [[ -n "${SWAYSOCK:-}" ]]; then
        display_server="Wayland"
        
        # Detect Wayland compositor/window manager
        if [[ -n "${SWAYSOCK:-}" ]] || pgrep -x sway >/dev/null 2>&1; then
            window_manager="Sway"
            
            # Get Sway version if available
            if command_exists swaymsg; then
                local sway_version=$(swaymsg -t get_version 2>/dev/null | grep -o '"version":"[^"]*' | cut -d'"' -f4 || echo "Unknown")
                window_manager="Sway v$sway_version"
            fi
        elif pgrep -x weston >/dev/null 2>&1; then
            window_manager="Weston"
        elif pgrep -x mutter >/dev/null 2>&1; then
            window_manager="GNOME Shell (Mutter)"
        elif pgrep -x kwin_wayland >/dev/null 2>&1; then
            window_manager="KWin (KDE)"
        elif pgrep -x river >/dev/null 2>&1; then
            window_manager="River"
        elif pgrep -x wayfire >/dev/null 2>&1; then
            window_manager="Wayfire"
        elif pgrep -x hyprland >/dev/null 2>&1; then
            window_manager="Hyprland"
        else
            # Try to detect from environment or processes
            local wayland_compositor=$(ps aux | grep -E "(sway|weston|mutter|kwin_wayland|river|wayfire|hyprland)" | grep -v grep | head -1 | awk '{print $11}' | xargs basename 2>/dev/null || echo "Unknown")
            if [[ "$wayland_compositor" != "Unknown" ]]; then
                window_manager="$wayland_compositor"
            fi
        fi
    elif [[ -n "${DISPLAY:-}" ]] && [[ "$session_type" == "x11" ]]; then
        display_server="X11"
        
        # Detect X11 window manager
        if pgrep -x i3 >/dev/null 2>&1; then
            window_manager="i3"
        elif pgrep -x awesome >/dev/null 2>&1; then
            window_manager="Awesome"
        elif pgrep -x dwm >/dev/null 2>&1; then
            window_manager="dwm"
        elif pgrep -x bspwm >/dev/null 2>&1; then
            window_manager="bspwm"
        elif pgrep -x openbox >/dev/null 2>&1; then
            window_manager="Openbox"
        elif pgrep -x xfwm4 >/dev/null 2>&1; then
            window_manager="Xfwm4 (XFCE)"
        elif pgrep -x kwin >/dev/null 2>&1; then
            window_manager="KWin (KDE)"
        else
            window_manager="Unknown X11 WM"
        fi
    elif [[ -n "${DISPLAY:-}" ]]; then
        # DISPLAY is set but session type is not x11, might still be X11
        display_server="X11 (legacy detection)"
    else
        display_server="Console/TTY"
    fi
    
    # Output display server and window manager info
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "${GREEN}Display Server:${NC} $display_server"
        echo -e "${GREEN}Session Type:${NC} $session_type"
        echo -e "${GREEN}Window Manager:${NC} $window_manager"
        
        # Additional Wayland/Sway specific info
        if [[ "$display_server" == "Wayland" ]] && [[ "$window_manager" =~ "Sway" ]]; then
            if command_exists swaymsg; then
                echo -e "${GREEN}Wayland Display:${NC} ${WAYLAND_DISPLAY:-Not set}"
                echo -e "${GREEN}Sway Socket:${NC} ${SWAYSOCK:-Not set}"
                
                # Get active workspace info
                local active_workspace=$(swaymsg -t get_workspaces 2>/dev/null | grep '"focused":true' | grep -o '"name":"[^"]*' | cut -d'"' -f4 || echo "Unknown")
                if [[ "$active_workspace" != "Unknown" ]]; then
                    echo -e "${GREEN}Active Workspace:${NC} $active_workspace"
                fi
                
                # Get output info
                local outputs_count=$(swaymsg -t get_outputs 2>/dev/null | grep -c '"name"' || echo "0")
                echo -e "${GREEN}Connected Outputs:${NC} $outputs_count"
            fi
        fi
    elif [[ "$HTML_OUTPUT" == true ]]; then
        html_info_item "Display Server" "$display_server"
        html_info_item "Session Type" "$session_type"
        html_info_item "Window Manager" "$window_manager"
        
        if [[ "$display_server" == "Wayland" ]]; then
            html_info_item "Wayland Display" "${WAYLAND_DISPLAY:-Not set}"
            if [[ "$window_manager" =~ "Sway" ]]; then
                html_info_item "Sway Socket" "${SWAYSOCK:-Not set}"
            fi
        fi
    else
        json_field "display_server" "$display_server"
        json_field "session_type" "$session_type"
        json_field "window_manager" "$window_manager"
        json_field "wayland_display" "${WAYLAND_DISPLAY:-}"
        json_field "sway_socket" "${SWAYSOCK:-}"
    fi
    
    # Display configuration (for Sway/Wayland)
    if [[ "$BRIEF_MODE" == false ]] && [[ "$window_manager" =~ "Sway" ]] && command_exists swaymsg; then
        print_subheader "Display Configuration"
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo "Sway Output Configuration:"
            swaymsg -t get_outputs 2>/dev/null | grep -E '"name"|"current_mode"|"scale"|"transform"' | while read -r line; do
                echo "  $line"
            done | head -10 || echo "  Unable to get display configuration"
        fi
    fi
    
    json_section_end
    html_section_end
}

# Package Information
get_package_info() {
    print_header "PACKAGE INFORMATION"
    html_section "Package Information"
    json_section "packages"
    show_progress "Analyzing packages..."
    
    if command_exists pacman; then
        # Installed packages count
        local installed_packages=$(pacman -Q | wc -l)
        local orphaned_packages=$(pacman -Qtdq 2>/dev/null | wc -l || echo "0")
        
        # AUR helper info
        local aur_helper="None"
        if command_exists yay; then
            aur_helper="yay"
        elif command_exists paru; then
            aur_helper="paru"
        fi
        
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo -e "${GREEN}Installed Packages:${NC} $installed_packages"
            echo -e "${GREEN}Orphaned Packages:${NC} $orphaned_packages"
            echo -e "${GREEN}AUR Helper:${NC} $aur_helper"
        elif [[ "$HTML_OUTPUT" == true ]]; then
            echo "                <div class=\"info-grid\">"
            html_info_item "Installed Packages" "$installed_packages"
            html_info_item "Orphaned Packages" "$orphaned_packages"
            html_info_item "AUR Helper" "$aur_helper"
            echo "                </div>"
        else
            json_field "installed_packages" "$installed_packages"
            json_field "orphaned_packages" "$orphaned_packages"
            json_field "aur_helper" "$aur_helper"
        fi
    fi
    
    json_section_end
    html_section_end
}

# System Services
get_services_info() {
    print_header "SYSTEM SERVICES"
    html_section "System Services"
    json_section "services"
    show_progress "Analyzing services..."
    
    if command_exists systemctl; then
        # Failed services
        local failed_services=$(systemctl --failed --no-legend | wc -l)
        
        if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
            echo -e "${GREEN}Failed Services:${NC} $failed_services"
            
            if [[ "$failed_services" -gt 0 ]] && [[ "$BRIEF_MODE" == false ]]; then
                print_subheader "Failed Services"
                systemctl --failed --no-legend
            fi
        elif [[ "$HTML_OUTPUT" == true ]]; then
            html_info_item "Failed Services" "$failed_services"
            
            if [[ "$failed_services" -gt 0 ]] && [[ "$BRIEF_MODE" == false ]]; then
                echo "                <h4>Failed Services</h4>"
                echo "                <table>"
                echo "                    <thead><tr><th>Service</th><th>Load</th><th>Active</th><th>Sub</th></tr></thead>"
                echo "                    <tbody>"
                
                systemctl --failed --no-legend | while read -r line; do
                    local service=$(echo "$line" | awk '{print $1}')
                    local load=$(echo "$line" | awk '{print $2}')
                    local active=$(echo "$line" | awk '{print $3}')
                    local sub=$(echo "$line" | awk '{print $4}')
                    
                    echo "                        <tr><td class='status-inactive'>$service</td><td>$load</td><td>$active</td><td>$sub</td></tr>"
                done
                
                echo "                    </tbody>"
                echo "                </table>"
            fi
        else
            json_field "failed_services" "$failed_services"
        fi
    fi
    
    json_section_end
    html_section_end
}

# Benchmark function
run_benchmark() {
    print_header "SYSTEM BENCHMARK"
    html_section "System Benchmark"
    json_section "benchmark"
    show_progress "Running system benchmarks..."
    
    # CPU benchmark
    print_subheader "CPU Performance Test"
    local cpu_start=$(date +%s.%N)
    
    # Simple CPU intensive task
    local result=0
    for i in {1..10000}; do
        result=$((result + i))
    done
    
    local cpu_end=$(date +%s.%N)
    local cpu_time=$(awk "BEGIN {printf \"%.3f\", $cpu_end - $cpu_start}")
    
    # Memory benchmark
    print_subheader "Memory Performance Test"
    local mem_start=$(date +%s.%N)
    dd if=/dev/zero of="$TEMP_DIR/benchmark" bs=1M count=100 2>/dev/null || true
    local mem_end=$(date +%s.%N)
    local mem_time=$(awk "BEGIN {printf \"%.3f\", $mem_end - $mem_start}")
    rm -f "$TEMP_DIR/benchmark"
    
    # Output results
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "${GREEN}CPU Test Time:${NC} ${cpu_time}s - arithmetic operations"
        echo -e "${GREEN}Memory Test Time:${NC} ${mem_time}s - 100MB write"
        echo -e "${CYAN}Note: Lower times indicate better performance${NC}"
    elif [[ "$HTML_OUTPUT" == true ]]; then
        html_info_item "CPU Test Time" "${cpu_time}s"
        html_info_item "Memory Test Time" "${mem_time}s"
    else
        json_field "cpu_test_time" "$cpu_time"
        json_field "memory_test_time" "$mem_time"
    fi
    
    json_section_end
    html_section_end
}

# Save output function
save_output() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local hostname=$(hostname)
    local output_file
    local script_args=""
    
    # Determine output file and arguments based on current mode
    if [[ "$HTML_OUTPUT" == true ]]; then
        output_file="${OUTPUT_FILE:-${CONFIG_DIR}/sysinfo_${hostname}_${timestamp}.html}"
        script_args="--html"
    elif [[ "$JSON_OUTPUT" == true ]]; then
        output_file="${OUTPUT_FILE:-${CONFIG_DIR}/sysinfo_${hostname}_${timestamp}.json}"
        script_args="--json"
    else
        output_file="${OUTPUT_FILE:-${CONFIG_DIR}/sysinfo_${hostname}_${timestamp}.txt}"
        script_args=""
    fi
    
    # Add brief mode if enabled
    if [[ "$BRIEF_MODE" == true ]]; then
        script_args="$script_args --brief"
    fi
    
    echo "Saving system information to: $output_file"
    
    # Run the script again with the correct arguments and save output
    "$0" $script_args > "$output_file"
    
    echo "System information saved to: $output_file"
    
    # Keep only last 10 reports
    find "$CONFIG_DIR" -name "sysinfo_*.txt" -o -name "sysinfo_*.html" -o -name "sysinfo_*.json" | sort | head -n -10 | xargs rm -f 2>/dev/null || true
}

# Compare with previous report
compare_reports() {
    local latest_report=$(find "$CONFIG_DIR" -name "sysinfo_*.txt" -type f | sort | tail -1)
    
    if [[ -z "$latest_report" ]]; then
        echo "No previous reports found. Run with --save first."
        return 1
    fi
    
    echo "Comparing with: $latest_report"
    echo "Generating current report..."
    
    local temp_current="$TEMP_DIR/current_report.txt"
    "$0" ${JSON_OUTPUT:+--json} ${BRIEF_MODE:+--brief} > "$temp_current"
    
    echo "Differences from last report:"
    diff "$latest_report" "$temp_current" || echo "No differences found."
}

# Main execution function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --html)
                HTML_OUTPUT=true
                shift
                ;;
            --brief)
                BRIEF_MODE=true
                shift
                ;;
            --skip-fs)
                SKIP_FILESYSTEM=true
                shift
                ;;
            --save)
                SAVE_OUTPUT=true
                shift
                ;;
            --compare)
                COMPARE_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE_MODE=true
                shift
                ;;
            --benchmark)
                run_benchmark
                exit 0
                ;;
            --health)
                system_health_check
                exit 0
                ;;
            --output|-o)
                OUTPUT_FILE="$2"
                SAVE_OUTPUT=true
                shift 2
                ;;
            --help|-h)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --json              Output in JSON format"
                echo "  --html              Output in HTML format"
                echo "  --brief             Brief output - skip detailed sections"
                echo "  --save              Save output to file"
                echo "  --compare           Compare with previous saved report"
                echo "  --verbose, -v       Verbose output with progress indicators"
                echo "  --benchmark         Run system performance benchmarks"
                echo "  --health            Run system health check only"
                echo "  --output FILE, -o   Save output to specific file"
                echo "  --help, -h          Show this help message"
                echo ""
                echo "Features:"
                echo "  • Comprehensive system analysis with 10+ categories"
                echo "  • Smart sudo handling with automatic privilege detection"
                echo "  • Multiple output formats - colored text, JSON, HTML"
                echo "  • Interactive HTML reports with collapsible sections"
                echo "  • Historical comparison and trend analysis"
                echo "  • Built-in system benchmarking and health monitoring"
                echo "  • Advanced filesystem support (Btrfs snapshots, Ext4 analysis)"
                echo "  • Enhanced graphics hardware and software detection"
                echo "  • Arch Linux + Sway/Wayland specific optimizations"
                echo "  • Automatic report archiving and cleanup"
                echo ""
                echo "Examples:"
                echo "  $0                    # Full system report (console)"
                echo "  $0 --html             # Interactive HTML report"
                echo "  $0 --brief --json    # Quick JSON summary"
                echo "  $0 --html --save     # Save HTML report for later viewing"
                echo "  $0 --compare         # Compare with last saved report"
                echo "  $0 --benchmark       # Run performance tests"
                echo "  $0 --health          # Quick health check"
                echo "  $0 --html -o report.html  # Save HTML to specific file"
                echo ""
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate output format combinations
    if [[ "$JSON_OUTPUT" == true ]] && [[ "$HTML_OUTPUT" == true ]]; then
        show_error "Cannot use both --json and --html options simultaneously"
        exit 1
    fi
    
    # Handle special modes
    if [[ "$SAVE_OUTPUT" == true ]]; then
        save_output
        exit 0
    fi
    
    if [[ "$COMPARE_MODE" == true ]]; then
        compare_reports
        exit 0
    fi
    
    # Start output
    if [[ "$HTML_OUTPUT" == true ]]; then
        html_start
    else
        json_start
    fi
    
    # Display header
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║${NC}${WHITE}                    $SCRIPT_NAME v$SCRIPT_VERSION                     ${NC}${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}${WHITE}              Comprehensive Arch Linux + Sway Analysis               ${NC}${PURPLE}║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "${YELLOW}Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
        echo -e "${YELLOW}Script location: $SCRIPT_DIR${NC}"
        echo -e "${YELLOW}Report ID: $(hostname)_$(date +%s)${NC}"
        
        if [[ "$BRIEF_MODE" == true ]]; then
            echo -e "${CYAN}Running in brief mode - detailed sections skipped${NC}"
        fi
        
        if [[ "$VERBOSE_MODE" == true ]]; then
            echo -e "${CYAN}Verbose mode enabled - showing progress indicators${NC}"
        fi
    fi
    
    # Run system health check first
    if [[ "$BRIEF_MODE" == false ]]; then
        system_health_check
    fi
    
    # Execute all information gathering functions
    get_system_info
    get_cpu_info
    get_memory_info
    get_disk_info
    get_network_info
    get_graphics_info
    get_services_info
    get_package_info
    
    # Run benchmark if verbose mode
    if [[ "$VERBOSE_MODE" == true ]]; then
        run_benchmark
    fi
    
    # End output
    if [[ "$HTML_OUTPUT" == true ]]; then
        html_end
    else
        # End JSON output if requested
        if [[ "$JSON_OUTPUT" == true ]]; then
            # Remove trailing comma from last section
            echo "  \"script_info\": {"
            echo "    \"version\": \"$SCRIPT_VERSION\","
            echo "    \"name\": \"$SCRIPT_NAME\","
            echo "    \"generated\": \"$(date '+%Y-%m-%d %H:%M:%S %Z')\","
            echo "    \"hostname\": \"$(hostname)\","
            echo "    \"brief_mode\": \"$BRIEF_MODE\","
            echo "    \"verbose_mode\": \"$VERBOSE_MODE\","
            echo "    \"html_output\": \"$HTML_OUTPUT\""
            echo "  }"
        fi
        json_end
    fi
    
    # Footer for console output
    if [[ "$JSON_OUTPUT" == false ]] && [[ "$HTML_OUTPUT" == false ]]; then
        echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║${NC}${WHITE}                         ANALYSIS COMPLETE                           ${NC}${PURPLE}║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "${GREEN}System information gathering completed successfully!${NC}"
        
        # Show useful tips
        echo -e "\n${CYAN}Pro Tips:${NC}"
        echo -e "   • HTML report: $0 --html"
        echo -e "   • Save report: $0 --save"
        echo -e "   • Compare changes: $0 --compare"
        echo -e "   • Run benchmarks: $0 --benchmark"
        echo -e "   • Health check: $0 --health"
        echo -e "   • JSON output: $0 --json"
        
        if command_exists neofetch; then
            echo -e "   • Quick overview: neofetch"
        fi
        
        # Show next actions based on health
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        local disk_usage=$(df / | awk 'NR==2 {print substr($5, 1, length($5)-1)}')
        
        if [[ $mem_usage -gt 80 ]] || [[ $disk_usage -gt 80 ]]; then
            echo -e "\n${YELLOW}Warning - Consider cleaning up:${NC}"
            if [[ $mem_usage -gt 80 ]]; then
                echo -e "   • High memory usage detected ($mem_usage%)"
            fi
            if [[ $disk_usage -gt 80 ]]; then
                echo -e "   • Low disk space on root filesystem ($disk_usage%)"
            fi
        fi
    fi
}

# Error handling with better reporting
trap 'show_error "Script interrupted or error occurred at line $LINENO! Use --verbose for more details."; cleanup; exit 1' ERR INT TERM

# Check if running as root (warn but don't prevent)
if [[ $EUID -eq 0 ]]; then
    show_warning "Running as root. Some information may be different than normal user experience."
fi

# Validate environment
if [[ ! -d /proc ]]; then
    show_error "This script requires a Linux system with /proc filesystem."
    exit 1
fi

# Check for required commands
missing_commands=()
for cmd in awk grep sed cut tr head tail; do
    if ! command_exists "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    show_error "Missing required commands: ${missing_commands[*]}"
    echo "Please install the missing commands and try again."
    exit 1
fi

# Execute main function
main "$@"