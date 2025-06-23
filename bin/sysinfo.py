#!/usr/bin/env python3
"""
Comprehensive System Information Script
Version: 5.0
Language: Python 3
Author: Enhanced for robust hardware detection with structured output

This script gathers comprehensive system information including:
- System details (OS, kernel, hardware)
- CPU information (detailed specifications)
- Memory information (RAM, swap, hardware details)
- Graphics information (GPU, drivers, display server)
- Audio information (hardware, drivers)
- Network information (interfaces, hardware)
- Storage information (disks, filesystems)
- USB and PCI devices
- Power and thermal information
"""

import os
import sys
import json
import argparse
import subprocess
import platform
import socket
import time
from datetime import datetime, timedelta
from pathlib import Path
import re

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

class SystemInfo:
    def __init__(self, verbose=False, brief=False, output_json=False):
        self.verbose = verbose
        self.brief = brief
        self.output_json = output_json
        self.data = {}
        self.terminal_width = self.get_terminal_width()
        
    def get_terminal_width(self):
        """Get terminal width for formatting"""
        try:
            import shutil
            return shutil.get_terminal_size().columns
        except:
            return 80
    
    def safe_read_file(self, filepath):
        """Safely read a file and return its content or None"""
        try:
            with open(filepath, 'r') as f:
                return f.read().strip()
        except (IOError, OSError, PermissionError):
            return None
    
    def run_command(self, command, shell=True):
        """Run a command and return output, error, and return code"""
        try:
            if isinstance(command, str) and shell:
                result = subprocess.run(command, shell=True, capture_output=True, 
                                      text=True, timeout=30)
            else:
                result = subprocess.run(command, capture_output=True, 
                                      text=True, timeout=30)
            return result.stdout.strip(), result.stderr.strip(), result.returncode
        except subprocess.TimeoutExpired:
            return "", "Command timed out", 1
        except Exception as e:
            return "", str(e), 1
    
    def command_exists(self, command):
        """Check if a command exists in PATH"""
        try:
            subprocess.run(['which', command], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def print_section(self, title):
        """Print a section header with simple formatting"""
        if not self.output_json:
            print(f"\n{Colors.BLUE}=== {title} ==={Colors.RESET}")
    
    def print_info(self, label, value, indent=0):
        """Print formatted information"""
        if not self.output_json:
            spaces = "  " * indent
            print(f"{spaces}{Colors.GREEN}{label}:{Colors.RESET} {value}")
    
    def print_table(self, headers, rows, title=None):
        """Print data in table format"""
        if self.output_json:
            return
        
        if title:
            print(f"\n{Colors.CYAN}{title}:{Colors.RESET}")
        
        if not rows:
            print("  No data available")
            return
        
        # Calculate column widths
        col_widths = []
        for i, header in enumerate(headers):
            max_width = len(str(header))
            for row in rows:
                if i < len(row):
                    max_width = max(max_width, len(str(row[i])))
            col_widths.append(min(max_width + 2, 30))  # Max width of 30
        
        # Print header
        header_line = "  "
        separator_line = "  "
        for i, (header, width) in enumerate(zip(headers, col_widths)):
            header_line += f"{str(header):<{width}}"
            separator_line += "-" * width
        
        print(f"{Colors.WHITE}{header_line}{Colors.RESET}")
        print(f"{Colors.BLUE}{separator_line}{Colors.RESET}")
        
        # Print rows
        for row in rows:
            row_line = "  "
            for i, (cell, width) in enumerate(zip(row, col_widths)):
                if i < len(row):
                    cell_str = str(cell)
                    if len(cell_str) > width - 2:
                        cell_str = cell_str[:width-5] + "..."
                    row_line += f"{cell_str:<{width}}"
            print(row_line)
    
    def bytes_to_gb(self, bytes_val):
        """Convert bytes to GB with 2 decimal places"""
        try:
            return round(int(bytes_val) / (1024**3), 2)
        except (ValueError, TypeError):
            return 0.0
    
    def kb_to_gb(self, kb_val):
        """Convert KB to GB with 2 decimal places"""
        try:
            return round(int(kb_val) / (1024**2), 2)
        except (ValueError, TypeError):
            return 0.0

    def get_boot_time(self):
        """Get system boot time"""
        try:
            if platform.system() == 'Linux':
                with open('/proc/uptime', 'r') as f:
                    uptime_seconds = float(f.read().split()[0])
                boot_time = datetime.now() - timedelta(seconds=uptime_seconds)
                return boot_time.strftime('%Y-%m-%d %H:%M:%S')
        except:
            pass
        return "Unknown"
    
    def get_linux_distro_info(self):
        """Get Linux distribution information"""
        info = {}
        
        # Try /etc/os-release first
        try:
            with open('/etc/os-release', 'r') as f:
                for line in f:
                    if '=' in line:
                        key, value = line.strip().split('=', 1)
                        value = value.strip('"')
                        if key == 'PRETTY_NAME':
                            info['distribution'] = value
                        elif key == 'VERSION_ID':
                            info['version_id'] = value
                        elif key == 'ID':
                            info['distro_id'] = value
        except IOError:
            info['distribution'] = 'Unknown Linux'
        
        return info
    
    def get_boot_mode(self):
        """Determine if system booted with UEFI or BIOS"""
        if os.path.exists('/sys/firmware/efi'):
            return 'UEFI'
        return 'BIOS'

    def get_system_info(self):
        """Gather basic system information"""
        self.print_section("SYSTEM INFORMATION")
        
        info = {
            'hostname': socket.gethostname(),
            'username': os.getenv('USER', 'unknown'),
            'architecture': platform.machine(),
            'platform': platform.platform(),
            'system': platform.system(),
            'release': platform.release(),
            'boot_time': self.get_boot_time(),
            'current_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z'),
            'timezone': time.tzname[0] if time.tzname else 'Unknown'
        }
        
        # Get distribution info on Linux
        if platform.system() == 'Linux':
            info.update(self.get_linux_distro_info())
            info['boot_mode'] = self.get_boot_mode()
        
        # Store and display
        self.data['system'] = info
        
        # Display in simple list format
        for key, value in info.items():
            label = key.replace('_', ' ').title()
            self.print_info(label, value)
        
        return info

    def get_dmi_info(self):
        """Get DMI/SMBIOS information"""
        info = {}
        
        # Try reading from /sys/class/dmi/id/ first
        dmi_files = {
            'manufacturer': '/sys/class/dmi/id/sys_vendor',
            'product_name': '/sys/class/dmi/id/product_name',
            'product_version': '/sys/class/dmi/id/product_version',
            'serial_number': '/sys/class/dmi/id/product_serial',
            'bios_vendor': '/sys/class/dmi/id/bios_vendor',
            'bios_version': '/sys/class/dmi/id/bios_version',
            'bios_date': '/sys/class/dmi/id/bios_date',
            'board_name': '/sys/class/dmi/id/board_name',
            'board_vendor': '/sys/class/dmi/id/board_vendor'
        }
        
        for key, filepath in dmi_files.items():
            value = self.safe_read_file(filepath)
            if value and value not in ['To be filled by O.E.M.', 'Not Specified', '']:
                info[key] = value
            else:
                info[key] = 'Unknown'
        
        return info
    
    def get_chassis_info(self):
        """Get chassis type information"""
        info = {}
        
        chassis_type_map = {
            '1': 'Other', '2': 'Unknown', '3': 'Desktop', '4': 'Low Profile Desktop',
            '5': 'Pizza Box', '6': 'Mini Tower', '7': 'Tower', '8': 'Portable',
            '9': 'Laptop', '10': 'Notebook', '11': 'Hand Held', '12': 'Docking Station',
            '13': 'All In One', '14': 'Sub Notebook', '15': 'Space-saving',
            '16': 'Lunch Box', '17': 'Main Server Chassis', '18': 'Expansion Chassis',
            '19': 'Sub Chassis', '20': 'Bus Expansion Chassis', '21': 'Peripheral Chassis',
            '22': 'RAID Chassis', '23': 'Rack Mount Chassis', '24': 'Sealed-case PC'
        }
        
        chassis_code = self.safe_read_file('/sys/class/dmi/id/chassis_type')
        if chassis_code and chassis_code in chassis_type_map:
            info['chassis_type'] = chassis_type_map[chassis_code]
        else:
            info['chassis_type'] = 'Unknown'
        
        return info

    def get_hardware_info(self):
        """Gather hardware information"""
        self.print_section("HARDWARE INFORMATION")
        
        info = {}
        
        # DMI information
        dmi_info = self.get_dmi_info()
        if dmi_info:
            info.update(dmi_info)
        
        # Additional hardware detection
        info.update(self.get_chassis_info())
        
        self.data['hardware'] = info
        
        # Display in simple list format
        for key, value in info.items():
            label = key.replace('_', ' ').title()
            self.print_info(label, value)
        
        return info

    def get_linux_cpu_info(self):
        """Get detailed CPU info from /proc/cpuinfo"""
        info = {}
        
        try:
            with open('/proc/cpuinfo', 'r') as f:
                cpuinfo = f.read()
            
            # Parse CPU information
            for line in cpuinfo.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    key = key.strip()
                    value = value.strip()
                    
                    if key == 'model name' and 'model_name' not in info:
                        info['model_name'] = value
                    elif key == 'vendor_id' and 'vendor' not in info:
                        info['vendor'] = value
                    elif key == 'cpu family' and 'family' not in info:
                        info['family'] = value
                    elif key == 'model' and 'model_id' not in info:
                        info['model_id'] = value
                    elif key == 'stepping' and 'stepping' not in info:
                        info['stepping'] = value
                    elif key == 'cache size' and 'cache_size' not in info:
                        info['cache_size'] = value
                    elif key == 'flags' and 'features' not in info:
                        # Only show first few features to avoid clutter
                        features = value.split()[:10]
                        info['features'] = ' '.join(features) + '...'
            
            # Count logical processors
            logical_cores = cpuinfo.count('processor\t:')
            if logical_cores > 0:
                info['logical_cores'] = logical_cores
                
        except IOError:
            pass
        
        return info
    
    def get_cpu_frequency(self):
        """Get CPU frequency information"""
        info = {}
        
        # Try to get current frequency
        try:
            freq_file = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'
            if os.path.exists(freq_file):
                with open(freq_file, 'r') as f:
                    freq_khz = int(f.read().strip())
                    info['current_frequency_mhz'] = freq_khz // 1000
        except (IOError, ValueError):
            pass
        
        # Try to get max frequency
        try:
            max_freq_file = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq'
            if os.path.exists(max_freq_file):
                with open(max_freq_file, 'r') as f:
                    max_freq_khz = int(f.read().strip())
                    info['max_frequency_mhz'] = max_freq_khz // 1000
        except (IOError, ValueError):
            pass
        
        # CPU governor
        try:
            gov_file = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
            if os.path.exists(gov_file):
                with open(gov_file, 'r') as f:
                    info['governor'] = f.read().strip()
        except IOError:
            pass
        
        return info
    
    def get_cpu_usage(self):
        """Get current CPU usage percentage"""
        try:
            # Simple CPU usage from /proc/loadavg
            with open('/proc/loadavg', 'r') as f:
                load_avg = f.read().strip().split()
                return f"{load_avg[0]} (1min), {load_avg[1]} (5min), {load_avg[2]} (15min)"
        except IOError:
            return None

    def get_cpu_info(self):
        """Gather CPU information"""
        self.print_section("CPU INFORMATION")
        
        info = {}
        
        # Basic CPU info from platform module
        info['architecture'] = platform.machine()
        info['processor'] = platform.processor()
        
        # Linux-specific CPU information
        if platform.system() == 'Linux':
            cpu_info = self.get_linux_cpu_info()
            info.update(cpu_info)
        
        # CPU count
        info['physical_cores'] = os.cpu_count()
        
        # CPU frequency
        cpu_freq = self.get_cpu_frequency()
        if cpu_freq:
            info.update(cpu_freq)
        
        # CPU usage
        cpu_usage = self.get_cpu_usage()
        if cpu_usage:
            info['load_average'] = cpu_usage
        
        self.data['cpu'] = info
        
        # Display in simple list format
        for key, value in info.items():
            label = key.replace('_', ' ').title()
            self.print_info(label, value)
        
        return info

    def get_linux_memory_info(self):
        """Get memory information from /proc/meminfo"""
        info = {}
        
        try:
            with open('/proc/meminfo', 'r') as f:
                meminfo = f.read()
            
            mem_data = {}
            for line in meminfo.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    # Extract numeric value (in kB)
                    match = re.search(r'(\d+)', value)
                    if match:
                        mem_data[key.strip()] = int(match.group(1))
            
            # Calculate memory values in GB
            if 'MemTotal' in mem_data:
                info['total_ram_gb'] = self.kb_to_gb(mem_data['MemTotal'])
            
            if 'MemAvailable' in mem_data:
                info['available_ram_gb'] = self.kb_to_gb(mem_data['MemAvailable'])
            
            if 'MemTotal' in mem_data and 'MemAvailable' in mem_data:
                used_kb = mem_data['MemTotal'] - mem_data['MemAvailable']
                info['used_ram_gb'] = self.kb_to_gb(used_kb)
                usage_percent = (used_kb / mem_data['MemTotal']) * 100
                info['usage_percent'] = round(usage_percent, 1)
            
            if 'SwapTotal' in mem_data:
                info['total_swap_gb'] = self.kb_to_gb(mem_data['SwapTotal'])
            
            if 'SwapFree' in mem_data and 'SwapTotal' in mem_data:
                swap_used_kb = mem_data['SwapTotal'] - mem_data['SwapFree']
                info['used_swap_gb'] = self.kb_to_gb(swap_used_kb)
                
        except IOError:
            pass
        
        return info
    
    def get_memory_hardware_info(self):
        """Get memory hardware information using dmidecode"""
        info = {}
        
        if self.command_exists('dmidecode'):
            stdout, stderr, returncode = self.run_command('sudo dmidecode -t memory 2>/dev/null')
            
            if returncode == 0 and stdout:
                # Parse memory information
                slots = 0
                speed = None
                mem_type = None
                
                for line in stdout.split('\n'):
                    if 'Memory Device' in line:
                        slots += 1
                    elif 'Type:' in line and 'Error' not in line:
                        if not mem_type:
                            mem_type = line.split(':', 1)[1].strip()
                    elif 'Speed:' in line and 'Unknown' not in line:
                        if not speed:
                            speed = line.split(':', 1)[1].strip()
                
                if slots > 0:
                    info['memory_slots'] = slots
                if mem_type:
                    info['memory_type'] = mem_type
                if speed:
                    info['memory_speed'] = speed
        
        return info

    def get_memory_info(self):
        """Gather memory information"""
        self.print_section("MEMORY INFORMATION")
        
        info = {}
        
        if platform.system() == 'Linux':
            mem_info = self.get_linux_memory_info()
            info.update(mem_info)
        
        # Try to get hardware memory info
        hw_mem_info = self.get_memory_hardware_info()
        if hw_mem_info:
            info.update(hw_mem_info)
        
        self.data['memory'] = info
        
        # Display in simple list format
        for key, value in info.items():
            label = key.replace('_', ' ').title()
            self.print_info(label, value)
        
        return info

    def get_gpu_hardware(self):
        """Get GPU hardware information"""
        info = {}
        
        if self.command_exists('lspci'):
            stdout, stderr, returncode = self.run_command('lspci | grep -i "vga\\|3d\\|display"')
            
            if returncode == 0 and stdout:
                gpus = []
                for line in stdout.split('\n'):
                    if line.strip():
                        # Extract GPU info after the PCI ID
                        gpu_desc = ':'.join(line.split(':')[2:]).strip()
                        gpus.append(gpu_desc)
                
                if gpus:
                    if len(gpus) == 1:
                        info['gpu'] = gpus[0]
                    else:
                        for i, gpu in enumerate(gpus, 1):
                            info[f'gpu_{i}'] = gpu
        
        return info
    
    def get_display_server_info(self):
        """Get display server and session information"""
        info = {}
        
        # Session type
        session_type = os.getenv('XDG_SESSION_TYPE', 'Unknown')
        info['session_type'] = session_type
        
        # Display server detection
        if os.getenv('WAYLAND_DISPLAY') or session_type == 'wayland':
            info['display_server'] = 'Wayland'
            
            # Detect Wayland compositor
            compositor = self.detect_wayland_compositor()
            if compositor:
                info['compositor'] = compositor
        elif os.getenv('DISPLAY'):
            info['display_server'] = 'X11'
            
            # Detect window manager for X11
            wm = self.detect_x11_window_manager()
            if wm:
                info['window_manager'] = wm
        else:
            info['display_server'] = 'Console/TTY'
        
        return info
    
    def detect_wayland_compositor(self):
        """Detect the running Wayland compositor"""
        compositors = ['sway', 'weston', 'mutter', 'kwin_wayland', 'river', 'wayfire', 'hyprland']
        
        for compositor in compositors:
            stdout, stderr, returncode = self.run_command(f'pgrep -x {compositor}')
            if returncode == 0:
                return compositor
        
        return 'Unknown Wayland Compositor'
    
    def detect_x11_window_manager(self):
        """Detect the running X11 window manager"""
        wms = ['i3', 'awesome', 'dwm', 'bspwm', 'openbox', 'xfwm4', 'kwin']
        
        for wm in wms:
            stdout, stderr, returncode = self.run_command(f'pgrep -x {wm}')
            if returncode == 0:
                return wm
        
        return 'Unknown WM'
    
    def get_graphics_drivers(self):
        """Get graphics driver information"""
        info = {}
        
        # Check loaded kernel modules
        drivers = []
        driver_modules = ['i915', 'nouveau', 'nvidia', 'amdgpu', 'radeon']
        
        for module in driver_modules:
            if os.path.exists(f'/sys/module/{module}'):
                drivers.append(module)
        
        if drivers:
            info['graphics_drivers'] = ', '.join(drivers)
        else:
            info['graphics_drivers'] = 'Unknown'
        
        return info
    
    def get_opengl_info(self):
        """Get OpenGL information"""
        info = {}
        
        if self.command_exists('glxinfo') and os.getenv('DISPLAY'):
            stdout, stderr, returncode = self.run_command('glxinfo 2>/dev/null | head -20')
            
            if returncode == 0 and stdout:
                for line in stdout.split('\n'):
                    if 'OpenGL vendor string:' in line:
                        info['opengl_vendor'] = line.split(':', 1)[1].strip()
                    elif 'OpenGL renderer string:' in line:
                        info['opengl_renderer'] = line.split(':', 1)[1].strip()
                    elif 'OpenGL version string:' in line:
                        info['opengl_version'] = line.split(':', 1)[1].strip()
        
        return info
    
    def get_vulkan_info(self):
        """Get Vulkan information"""
        info = {}
        
        if self.command_exists('vulkaninfo'):
            stdout, stderr, returncode = self.run_command('vulkaninfo --summary 2>/dev/null | head -10')
            
            if returncode == 0 and stdout:
                for line in stdout.split('\n'):
                    if 'Vulkan Instance Version:' in line:
                        info['vulkan_version'] = line.split(':', 1)[1].strip()
                        break
            else:
                info['vulkan_support'] = 'Not available'
        
        return info

    def get_graphics_info(self):
        """Gather graphics information"""
        self.print_section("GRAPHICS INFORMATION")
        
        info = {}
        
        # GPU hardware detection
        gpu_info = self.get_gpu_hardware()
        if gpu_info:
            info.update(gpu_info)
        
        # Display server information
        display_info = self.get_display_server_info()
        if display_info:
            info.update(display_info)
        
        # Graphics drivers
        driver_info = self.get_graphics_drivers()
        if driver_info:
            info.update(driver_info)
        
        # OpenGL/Vulkan information
        if not self.brief:
            gl_info = self.get_opengl_info()
            if gl_info:
                info.update(gl_info)
            
            vulkan_info = self.get_vulkan_info()
            if vulkan_info:
                info.update(vulkan_info)
        
        self.data['graphics'] = info
        
        # Display in simple list format
        for key, value in info.items():
            label = key.replace('_', ' ').title()
            self.print_info(label, value)
        
        return info

    def get_audio_hardware(self):
        """Get audio hardware information"""
        info = {}
        
        if self.command_exists('lspci'):
            stdout, stderr, returncode = self.run_command('lspci | grep -i "audio\\|sound"')
            
            if returncode == 0 and stdout:
                audio_devices = []
                for line in stdout.split('\n'):
                    if line.strip():
                        device_desc = ':'.join(line.split(':')[2:]).strip()
                        audio_devices.append(device_desc)
                
                if audio_devices:
                    if len(audio_devices) == 1:
                        info['audio_hardware'] = audio_devices[0]
                    else:
                        for i, device in enumerate(audio_devices, 1):
                            info[f'audio_device_{i}'] = device
        
        return info
    
    def get_audio_system_info(self):
        """Get audio system information (ALSA, PulseAudio, PipeWire)"""
        info = {}
        
        # ALSA
        if self.command_exists('aplay'):
            stdout, stderr, returncode = self.run_command('aplay -l 2>/dev/null | grep "^card" | wc -l')
            if returncode == 0 and stdout:
                try:
                    card_count = int(stdout.strip())
                    info['alsa_sound_cards'] = card_count
                except ValueError:
                    pass
        
        # PulseAudio
        if self.command_exists('pactl'):
            stdout, stderr, returncode = self.run_command('pactl info 2>/dev/null')
            if returncode == 0 and stdout:
                for line in stdout.split('\n'):
                    if 'Server Version:' in line:
                        info['pulseaudio_version'] = line.split(':', 1)[1].strip()
                        break
        
        # PipeWire
        if self.command_exists('pw-cli'):
            stdout, stderr, returncode = self.run_command('pw-cli info 2>/dev/null')
            if returncode == 0 and stdout:
                for line in stdout.split('\n'):
                    if 'version' in line.lower():
                        # Extract version from pw-cli output
                        version_match = re.search(r'"([0-9.]+)"', line)
                        if version_match:
                            info['pipewire_version'] = version_match.group(1)
                            break
        
        return info

    def get_audio_info(self):
        """Gather audio information"""
        self.print_section("AUDIO INFORMATION")
        
        info = {}
        
        # Audio hardware
        audio_hw = self.get_audio_hardware()
        if audio_hw:
            info.update(audio_hw)
        
        # Audio system information
        audio_sys = self.get_audio_system_info()
        if audio_sys:
            info.update(audio_sys)
        
        self.data['audio'] = info
        
        # Display in simple list format
        for key, value in info.items():
            label = key.replace('_', ' ').title()
            self.print_info(label, value)
        
        return info

    def get_network_interfaces(self):
        """Get network interface information"""
        interfaces = {}
        
        if self.command_exists('ip'):
            # Get interface list
            stdout, stderr, returncode = self.run_command('ip link show')
            
            if returncode == 0 and stdout:
                current_interface = None
                
                for line in stdout.split('\n'):
                    # Parse interface line
                    match = re.match(r'^\d+:\s+(\w+):', line)
                    if match:
                        current_interface = match.group(1)
                        interfaces[current_interface] = {}
                        
                        # Get state
                        if 'state UP' in line:
                            interfaces[current_interface]['state'] = 'UP'
                        elif 'state DOWN' in line:
                            interfaces[current_interface]['state'] = 'DOWN'
                        else:
                            interfaces[current_interface]['state'] = 'UNKNOWN'
                    
                    # Parse MAC address
                    elif current_interface and 'link/ether' in line:
                        mac_match = re.search(r'link/ether\s+([a-f0-9:]{17})', line)
                        if mac_match:
                            interfaces[current_interface]['mac_address'] = mac_match.group(1)
            
            # Get IP addresses for each interface
            for interface in interfaces.keys():
                stdout, stderr, returncode = self.run_command(f'ip addr show {interface}')
                
                if returncode == 0 and stdout:
                    ipv4_addresses = []
                    ipv6_addresses = []
                    
                    for line in stdout.split('\n'):
                        # IPv4
                        ipv4_match = re.search(r'inet\s+([0-9.]+/\d+)', line)
                        if ipv4_match:
                            ipv4_addresses.append(ipv4_match.group(1))
                        
                        # IPv6
                        ipv6_match = re.search(r'inet6\s+([a-f0-9:]+/\d+)', line)
                        if ipv6_match and not ipv6_match.group(1).startswith('::1'):
                            ipv6_addresses.append(ipv6_match.group(1))
                    
                    if ipv4_addresses:
                        interfaces[interface]['ipv4'] = ', '.join(ipv4_addresses)
                    if ipv6_addresses:
                        interfaces[interface]['ipv6'] = ', '.join(ipv6_addresses)
        
        return interfaces
    
    def get_network_hardware(self):
        """Get network hardware information"""
        info = {}
        
        if self.command_exists('lspci'):
            stdout, stderr, returncode = self.run_command('lspci | grep -i "network\\|ethernet\\|wireless\\|wifi"')
            
            if returncode == 0 and stdout:
                network_devices = []
                for line in stdout.split('\n'):
                    if line.strip():
                        device_desc = ':'.join(line.split(':')[2:]).strip()
                        network_devices.append(device_desc)
                
                if network_devices:
                    if len(network_devices) == 1:
                        info['network_hardware'] = network_devices[0]
                    else:
                        for i, device in enumerate(network_devices, 1):
                            info[f'network_device_{i}'] = device
        
        return info
    
    def test_connectivity(self):
        """Test internet connectivity"""
        test_hosts = ['8.8.8.8', 'google.com']
        
        for host in test_hosts:
            stdout, stderr, returncode = self.run_command(f'ping -c 1 -W 2 {host}')
            if returncode == 0:
                return 'Connected'
        
        return 'No connectivity'

    def get_network_info(self):
        """Gather network information"""
        self.print_section("NETWORK INFORMATION")
        
        info = {}
        
        # Network interfaces
        interfaces = self.get_network_interfaces()
        
        # Network hardware
        network_hw = self.get_network_hardware()
        if network_hw:
            info.update(network_hw)
        
        # Connectivity test
        if not self.brief:
            connectivity = self.test_connectivity()
            if connectivity:
                info['internet_connectivity'] = connectivity
        
        self.data['network'] = info
        
        # Display network hardware info first
        if info:
            for key, value in info.items():
                label = key.replace('_', ' ').title()
                self.print_info(label, value)
        
        # Display interfaces in table format
        if interfaces:
            interface_rows = []
            for interface_name, interface_info in interfaces.items():
                row = [
                    interface_name,
                    interface_info.get('state', 'Unknown'),
                    interface_info.get('mac_address', 'N/A'),
                    interface_info.get('ipv4', 'N/A'),
                    interface_info.get('ipv6', 'N/A')
                ]
                interface_rows.append(row)
            
            headers = ['Interface', 'State', 'MAC Address', 'IPv4', 'IPv6']
            self.print_table(headers, interface_rows, "Network Interfaces")
        
        return info

    def get_block_devices(self):
        """Get block device information"""
        devices = {}
        
        if self.command_exists('lsblk'):
            stdout, stderr, returncode = self.run_command('lsblk -J')
            
            if returncode == 0 and stdout:
                try:
                    data = json.loads(stdout)
                    for device in data.get('blockdevices', []):
                        name = device.get('name', 'unknown')
                        devices[name] = {
                            'size': device.get('size', 'Unknown'),
                            'type': device.get('type', 'Unknown'),
                            'mountpoint': device.get('mountpoint', 'Not mounted'),
                            'fstype': device.get('fstype', 'Unknown')
                        }
                        
                        # Add model if available
                        if device.get('model'):
                            devices[name]['model'] = device['model']
                        
                        # Process children (partitions)
                        if device.get('children'):
                            for child in device['children']:
                                child_name = child.get('name', 'unknown')
                                devices[child_name] = {
                                    'size': child.get('size', 'Unknown'),
                                    'type': child.get('type', 'Unknown'),
                                    'mountpoint': child.get('mountpoint', 'Not mounted'),
                                    'fstype': child.get('fstype', 'Unknown')
                                }
                except json.JSONDecodeError:
                    pass
        
        return devices
    
    def get_filesystem_usage(self):
        """Get filesystem usage information"""
        filesystems = {}
        
        if self.command_exists('df'):
            stdout, stderr, returncode = self.run_command('df -h -t ext4 -t ext3 -t ext2 -t btrfs -t xfs -t zfs')
            
            if returncode == 0 and stdout:
                lines = stdout.split('\n')[1:]  # Skip header
                
                for line in lines:
                    if line.strip():
                        parts = line.split()
                        if len(parts) >= 6:
                            filesystem = parts[0]
                            size = parts[1]
                            used = parts[2]
                            available = parts[3]
                            use_percent = parts[4]
                            mountpoint = parts[5]
                            
                            filesystems[filesystem] = {
                                'size': size,
                                'used': used,
                                'available': available,
                                'use_percent': use_percent,
                                'mountpoint': mountpoint
                            }
        
        return filesystems
    
    def get_disk_health(self):
        """Get disk health information using SMART"""
        health_info = {}
        
        if self.command_exists('smartctl'):
            # Find disk devices
            disk_devices = []
            for device_path in ['/dev/sd?', '/dev/nvme?n1']:
                stdout, stderr, returncode = self.run_command(f'ls {device_path} 2>/dev/null')
                if returncode == 0 and stdout:
                    disk_devices.extend(stdout.split())
            
            # Check health for each device
            for device in disk_devices[:5]:  # Limit to first 5 devices
                stdout, stderr, returncode = self.run_command(f'sudo smartctl -H {device} 2>/dev/null')
                if returncode == 0 and stdout:
                    for line in stdout.split('\n'):
                        if 'SMART overall-health' in line:
                            health = line.split(':', 1)[1].strip()
                            health_info[device] = health
                            break
        
        return health_info

    def get_storage_info(self):
        """Gather storage information"""
        self.print_section("STORAGE INFORMATION")
        
        info = {}
        
        # Block devices
        block_devices = self.get_block_devices()
        
        # Filesystem usage
        filesystem_usage = self.get_filesystem_usage()
        
        # Disk health (if verbose)
        disk_health = {}
        if self.verbose:
            disk_health = self.get_disk_health()
        
        self.data['storage'] = {
            'block_devices': block_devices,
            'filesystems': filesystem_usage,
            'disk_health': disk_health
        }
        
        # Display block devices in table format
        if block_devices:
            device_rows = []
            for device, device_info in block_devices.items():
                row = [
                    device,
                    device_info.get('size', 'Unknown'),
                    device_info.get('type', 'Unknown'),
                    device_info.get('fstype', 'Unknown'),
                    device_info.get('mountpoint', 'Not mounted'),
                    device_info.get('model', 'N/A')
                ]
                device_rows.append(row)
            
            headers = ['Device', 'Size', 'Type', 'Filesystem', 'Mount Point', 'Model']
            self.print_table(headers, device_rows, "Block Devices")
        
        # Display filesystem usage in table format
        if filesystem_usage:
            fs_rows = []
            for filesystem, fs_info in filesystem_usage.items():
                row = [
                    filesystem,
                    fs_info.get('size', 'Unknown'),
                    fs_info.get('used', 'Unknown'),
                    fs_info.get('available', 'Unknown'),
                    fs_info.get('use_percent', 'Unknown'),
                    fs_info.get('mountpoint', 'Unknown')
                ]
                fs_rows.append(row)
            
            headers = ['Filesystem', 'Size', 'Used', 'Available', 'Use%', 'Mount Point']
            self.print_table(headers, fs_rows, "Filesystem Usage")
        
        # Display disk health
        if disk_health:
            health_rows = []
            for disk, health in disk_health.items():
                health_rows.append([disk, health])
            
            headers = ['Device', 'Health Status']
            self.print_table(headers, health_rows, "Disk Health (SMART)")
        
        return info

    def get_usb_info(self):
        """Gather USB device information"""
        self.print_section("USB INFORMATION")
        
        info = {}
        
        if self.command_exists('lsusb'):
            stdout, stderr, returncode = self.run_command('lsusb')
            
            if returncode == 0 and stdout:
                usb_devices = []
                device_rows = []
                
                for line in stdout.split('\n'):
                    if line.strip() and 'root hub' not in line.lower():
                        # Parse USB line: Bus 001 Device 002: ID 1234:5678 Device Name
                        parts = line.split(' ', 6)
                        if len(parts) >= 7:
                            bus = parts[1]
                            device = parts[3].rstrip(':')
                            usb_id = parts[5]
                            device_desc = parts[6]
                            
                            device_rows.append([bus, device, usb_id, device_desc])
                            usb_devices.append(device_desc)
                
                if usb_devices:
                    info['device_count'] = len(usb_devices)
                    
                    # Display in table format
                    if device_rows:
                        headers = ['Bus', 'Device', 'ID', 'Description']
                        self.print_table(headers, device_rows, "USB Devices")
                else:
                    info['devices'] = 'None detected'
                    self.print_info("USB Devices", "None detected")
        
        self.data['usb'] = info
        
        return info

    def get_battery_info(self):
        """Get battery information"""
        info = {}
        battery_count = 0
        
        # Check for batteries in /sys/class/power_supply/
        power_supply_path = Path('/sys/class/power_supply')
        if power_supply_path.exists():
            for battery_path in power_supply_path.glob('BAT*'):
                battery_count += 1
                battery_name = battery_path.name
                
                # Read battery information
                capacity = self.safe_read_file(battery_path / 'capacity')
                status = self.safe_read_file(battery_path / 'status')
                technology = self.safe_read_file(battery_path / 'technology')
                manufacturer = self.safe_read_file(battery_path / 'manufacturer')
                
                prefix = f'{battery_name.lower()}_' if battery_count == 1 else f'{battery_name.lower()}_{battery_count}_'
                
                if capacity:
                    info[f'{prefix}capacity_percent'] = capacity
                if status:
                    info[f'{prefix}status'] = status
                if technology:
                    info[f'{prefix}technology'] = technology
                if manufacturer:
                    info[f'{prefix}manufacturer'] = manufacturer
        
        if battery_count == 0:
            info['battery_status'] = 'No battery detected (Desktop system)'
        
        return info
    
    def get_ac_adapter_info(self):
        """Get AC adapter information"""
        info = {}
        
        # Check for AC adapters
        power_supply_path = Path('/sys/class/power_supply')
        if power_supply_path.exists():
            for adapter_path in power_supply_path.glob('A[CD]*'):
                adapter_name = adapter_path.name
                online = self.safe_read_file(adapter_path / 'online')
                
                if online:
                    status = 'Connected' if online == '1' else 'Disconnected'
                    info[f'{adapter_name.lower()}_status'] = status
        
        return info

    def get_power_info(self):
        """Gather power and battery information"""
        self.print_section("POWER INFORMATION")
        
        info = {}
        
        # Battery information
        battery_info = self.get_battery_info()
        if battery_info:
            info.update(battery_info)
        
        # AC adapter information
        ac_info = self.get_ac_adapter_info()
        if ac_info:
            info.update(ac_info)
        
        self.data['power'] = info
        
        # Display in simple list format
        if info:
            for key, value in info.items():
                label = key.replace('_', ' ').title()
                self.print_info(label, value)
        else:
            self.print_info("Power Information", "No power devices detected")
        
        return info

    def get_temperature_info(self):
        """Gather temperature information"""
        self.print_section("TEMPERATURE INFORMATION")
        
        info = {}
        temp_rows = []
        
        # Try sensors command first
        if self.command_exists('sensors'):
            stdout, stderr, returncode = self.run_command('sensors 2>/dev/null')
            if returncode == 0 and stdout:
                sensor_temps = []
                current_device = "Unknown"
                
                for line in stdout.split('\n'):
                    if ':' not in line and line.strip() and not line.startswith(' '):
                        # This is likely a device name
                        current_device = line.strip()
                    elif '°C' in line or '°F' in line:
                        # Extract temperature readings
                        temp_match = re.search(r'([+-]?\d+\.\d+)°[CF]', line)
                        if temp_match:
                            temp_name = line.split(':')[0].strip() if ':' in line else "Temperature"
                            temp_value = temp_match.group(0)
                            temp_rows.append([current_device, temp_name, temp_value])
                            sensor_temps.append(f"{temp_name}: {temp_value}")
                
                if sensor_temps:
                    info['sensors_available'] = True
        
        # Thermal zones
        thermal_zones = {}
        thermal_path = Path('/sys/class/thermal')
        if thermal_path.exists():
            for zone_path in thermal_path.glob('thermal_zone*'):
                temp_file = zone_path / 'temp'
                temp_raw = self.safe_read_file(temp_file)
                
                if temp_raw and temp_raw.isdigit():
                    temp_celsius = int(temp_raw) // 1000
                    zone_name = zone_path.name
                    thermal_zones[zone_name] = f'{temp_celsius}°C'
                    temp_rows.append(["Thermal Zone", zone_name, f'{temp_celsius}°C'])
        
        if thermal_zones:
            info['thermal_zones_count'] = len(thermal_zones)
        
        if not temp_rows:
            info['temperature_sensors'] = 'No sensors available'
            self.print_info("Temperature Sensors", "No sensors available")
        else:
            # Display temperature readings in table format
            headers = ['Source', 'Sensor', 'Temperature']
            self.print_table(headers, temp_rows, "Temperature Readings")
        
        self.data['temperature'] = info
        
        return info

    def generate_output(self):
        """Generate the appropriate output format"""
        if self.output_json:
            self.generate_json_output()
        else:
            self.generate_console_footer()
    
    def generate_json_output(self):
        """Generate JSON output"""
        output_data = {
            'system_info': self.data,
            'generated_at': datetime.now().isoformat(),
            'script_version': '5.0',
            'script_language': 'Python'
        }
        print(json.dumps(output_data, indent=2))
    
    def generate_console_footer(self):
        """Generate console footer"""
        print(f"\n{Colors.GREEN}System information scan completed.{Colors.RESET}")
        print(f"{Colors.CYAN}Script: Python System Information v5.0{Colors.RESET}")

    def run_all_checks(self):
        """Run all system information checks"""
        try:
            # Header
            if not self.output_json:
                print(f"{Colors.CYAN}╔══════════════════════════════════════════════════════════════╗{Colors.RESET}")
                print(f"{Colors.CYAN}║{Colors.RESET}{Colors.WHITE}           Comprehensive System Information v5.0           {Colors.RESET}{Colors.CYAN}║{Colors.RESET}")
                print(f"{Colors.CYAN}╚══════════════════════════════════════════════════════════════╝{Colors.RESET}")
                print(f"{Colors.YELLOW}Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')}{Colors.RESET}")
            
            # Run all information gathering
            self.get_system_info()
            self.get_hardware_info()
            self.get_cpu_info()
            self.get_memory_info()
            self.get_graphics_info()
            self.get_audio_info()
            self.get_network_info()
            self.get_storage_info()
            self.get_usb_info()
            self.get_power_info()
            self.get_temperature_info()
            
            # Generate output
            self.generate_output()
            
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Script interrupted by user.{Colors.RESET}")
            sys.exit(1)
        except Exception as e:
            print(f"\n{Colors.RED}An error occurred: {str(e)}{Colors.RESET}")
            if self.verbose:
                import traceback
                traceback.print_exc()
            sys.exit(1)

def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(
        description='Comprehensive System Information Script v5.0',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Full system report
  %(prog)s --brief           # Brief system report
  %(prog)s --verbose         # Verbose output with extra details
  %(prog)s --json            # JSON output format
  %(prog)s --brief --json    # Brief JSON report

Features:
  • Comprehensive hardware detection
  • CPU, Memory, Graphics, Audio information
  • Network, Storage, USB, Power details
  • Temperature monitoring
  • Clean, structured output with tables and grids
  • Multiple output formats
        """
    )
    
    parser.add_argument('--brief', action='store_true',
                       help='Show brief output (skip detailed sections)')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Show verbose output with additional details')
    parser.add_argument('--json', action='store_true',
                       help='Output in JSON format')
    parser.add_argument('--version', action='version', version='%(prog)s 5.0')
    
    args = parser.parse_args()
    
    # Create and run system info gatherer
    sysinfo = SystemInfo(verbose=args.verbose, brief=args.brief, output_json=args.json)
    sysinfo.run_all_checks()

if __name__ == '__main__':
    main()
