#!/usr/bin/env python3
"""
Comprehensive File Search Script for Arch Linux
Author: okubax
Description: A powerful file search tool with Catppuccin color scheme
"""

import os
import sys
import argparse
import re
import subprocess
import json
import csv
import time
from pathlib import Path
from typing import List, Dict, Set, Optional, Tuple
from datetime import datetime, timedelta
import fnmatch
import threading

# Catppuccin Mocha Color Scheme
class Colors:
    # Base colors
    ROSEWATER = "\033[38;2;245;224;220m"
    FLAMINGO = "\033[38;2;242;205;205m"
    PINK = "\033[38;2;245;194;231m"
    MAUVE = "\033[38;2;203;166;247m"
    RED = "\033[38;2;243;139;168m"
    MAROON = "\033[38;2;235;160;172m"
    PEACH = "\033[38;2;250;179;135m"
    YELLOW = "\033[38;2;249;226;175m"
    GREEN = "\033[38;2;166;227;161m"
    TEAL = "\033[38;2;148;226;213m"
    SKY = "\033[38;2;137;220;235m"
    SAPPHIRE = "\033[38;2;116;199;236m"
    BLUE = "\033[38;2;137;180;250m"
    LAVENDER = "\033[38;2;180;190;254m"
    
    # Text colors
    TEXT = "\033[38;2;205;214;244m"
    SUBTEXT1 = "\033[38;2;186;194;222m"
    SUBTEXT0 = "\033[38;2;166;173;200m"
    OVERLAY2 = "\033[38;2;147;153;178m"
    OVERLAY1 = "\033[38;2;127;132;156m"
    OVERLAY0 = "\033[38;2;108;112;134m"
    SURFACE2 = "\033[38;2;88;91;112m"
    SURFACE1 = "\033[38;2;69;71;90m"
    SURFACE0 = "\033[38;2;49;50;68m"
    BASE = "\033[38;2;30;30;46m"
    MANTLE = "\033[38;2;24;24;37m"
    CRUST = "\033[38;2;17;17;27m"
    
    # Special
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    UNDERLINE = "\033[4m"

class ProgressIndicator:
    """Show search progress with a spinner and stats."""
    def __init__(self, show_progress: bool = True):
        self.show_progress = show_progress
        self.is_running = False
        self.files_scanned = 0
        self.dirs_scanned = 0
        self.matches_found = 0
        self.thread = None
        self.lock = threading.Lock()

    def start(self):
        """Start the progress indicator."""
        if not self.show_progress or not sys.stderr.isatty():
            return

        self.is_running = True
        self.thread = threading.Thread(target=self._show_progress, daemon=True)
        self.thread.start()

    def update(self, files: int = 0, dirs: int = 0, matches: int = 0):
        """Update progress counters."""
        with self.lock:
            self.files_scanned += files
            self.dirs_scanned += dirs
            self.matches_found += matches

    def stop(self):
        """Stop the progress indicator."""
        if not self.show_progress or not sys.stderr.isatty():
            return

        self.is_running = False
        if self.thread:
            self.thread.join()
        # Clear the progress line
        sys.stderr.write('\r' + ' ' * 80 + '\r')
        sys.stderr.flush()

    def _show_progress(self):
        """Show animated progress (runs in separate thread)."""
        spinner = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
        idx = 0

        while self.is_running:
            with self.lock:
                msg = (f"\r{Colors.SAPPHIRE}{spinner[idx]}{Colors.RESET} "
                      f"Scanned: {Colors.YELLOW}{self.dirs_scanned}{Colors.RESET} dirs, "
                      f"{Colors.YELLOW}{self.files_scanned}{Colors.RESET} files | "
                      f"Found: {Colors.GREEN}{self.matches_found}{Colors.RESET} matches")
                sys.stderr.write(msg)
                sys.stderr.flush()

            idx = (idx + 1) % len(spinner)
            time.sleep(0.1)

class FileSearcher:
    def __init__(self):
        self.config_file = Path.home() / ".config" / "filesearch" / "config.json"
        self.load_config()
        self.file_type_colors = {
            # Directories
            'directory': Colors.SAPPHIRE,
            # Audio files
            'audio': Colors.PINK,
            # Video files
            'video': Colors.MAUVE,
            # Images
            'image': Colors.PEACH,
            # Documents
            'document': Colors.BLUE,
            # Archives
            'archive': Colors.YELLOW,
            # Code files
            'code': Colors.GREEN,
            # Config files
            'config': Colors.TEAL,
            # Executables
            'executable': Colors.RED,
            # Web files
            'web': Colors.LAVENDER,
            # System files
            'system': Colors.MAROON,
            # Symlinks
            'symlink': Colors.SKY,
            # Default files
            'default': Colors.TEXT
        }
        
        self.file_extensions = {
            'audio': {'.mp3', '.wav', '.flac', '.ogg', '.m4a', '.aac', '.wma', '.opus'},
            'video': {'.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'},
            'image': {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.tiff', '.webp', '.ico'},
            'document': {'.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.md', '.tex', '.epub'},
            'archive': {'.zip', '.tar', '.gz', '.bz2', '.xz', '.7z', '.rar', '.deb', '.rpm'},
            'code': {'.py', '.js', '.html', '.css', '.cpp', '.c', '.java', '.rs', '.go', '.php', '.rb', '.sh', '.bash', '.zsh'},
            'config': {'.conf', '.cfg', '.ini', '.yaml', '.yml', '.json', '.xml', '.toml'},
            'web': {'.html', '.htm', '.css', '.js', '.php', '.jsp', '.asp'},
            'system': {'.so', '.a', '.o', '.ko', '.service', '.socket', '.timer'}
        }

    def load_config(self):
        """Load configuration from file or create default config"""
        default_config = {
            "ignored_paths": [
                "/proc",
                "/sys",
                "/dev",
                "/run",
                "/tmp",
                "/var/tmp",
                "/mnt/btr_pool",
                "/lost+found"
            ],
            "exclude_patterns": [
                "*.pyc",
                "__pycache__",
                ".git",
                ".svn",
                "node_modules"
            ],
            "max_results": 1000,
            "case_sensitive": False,
            "show_hidden": False,
            "follow_symlinks": False,
            "show_progress": True,
            "skip_permission_errors": True
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    self.config = json.load(f)
                # Merge with defaults for missing keys
                for key, value in default_config.items():
                    if key not in self.config:
                        self.config[key] = value
            except (json.JSONDecodeError, IOError):
                self.config = default_config
        else:
            self.config = default_config
            self.save_config()

    def save_config(self):
        """Save current configuration to file"""
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except IOError as e:
            print(f"{Colors.RED}Warning: Could not save config: {e}{Colors.RESET}")

    def get_file_type(self, filepath: Path) -> str:
        """Determine file type based on extension and file properties"""
        try:
            # Check if it's a directory
            if filepath.is_dir():
                return 'directory'
            
            # Check if it's a symbolic link
            if filepath.is_symlink():
                return 'symlink'
            
            # For regular files, check extension
            suffix = filepath.suffix.lower()
            
            for file_type, extensions in self.file_extensions.items():
                if suffix in extensions:
                    return file_type
            
            # Check if executable
            if filepath.is_file() and os.access(filepath, os.X_OK):
                return 'executable'
                
        except (OSError, IOError):
            pass
            
        return 'default'

    def colorize_path(self, filepath: Path, file_type: str) -> str:
        """Apply color coding to file path with type indicators"""
        color = self.file_type_colors.get(file_type, Colors.TEXT)
        
        # Add type indicators
        type_indicator = ""
        if file_type == 'directory':
            type_indicator = "📁 "
        elif file_type == 'symlink':
            type_indicator = "🔗 "
        elif file_type == 'executable':
            type_indicator = "⚡ "
        
        # Highlight the filename
        parent = str(filepath.parent)
        filename = filepath.name
        
        if parent == '.':
            return f"{type_indicator}{color}{Colors.BOLD}{filename}{Colors.RESET}"
        else:
            return f"{Colors.SUBTEXT1}{parent}/{Colors.RESET}{type_indicator}{color}{Colors.BOLD}{filename}{Colors.RESET}"

    def should_ignore_path(self, path: str) -> bool:
        """Check if path should be ignored based on configuration"""
        path_str = str(path)
        for ignored in self.config['ignored_paths']:
            if path_str.startswith(ignored):
                return True
        return False

    def should_exclude(self, name: str) -> bool:
        """Check if file/dir name matches exclude patterns."""
        for pattern in self.config.get('exclude_patterns', []):
            if fnmatch.fnmatch(name, pattern):
                return True
        return False

    def matches_size_filter(self, size: int, min_size: Optional[int] = None,
                           max_size: Optional[int] = None) -> bool:
        """Check if file size matches filter criteria."""
        if min_size is not None and size < min_size:
            return False
        if max_size is not None and size > max_size:
            return False
        return True

    def matches_date_filter(self, mtime: float, newer_than: Optional[datetime] = None,
                           older_than: Optional[datetime] = None) -> bool:
        """Check if file modification time matches filter criteria."""
        file_time = datetime.fromtimestamp(mtime)

        if newer_than is not None and file_time < newer_than:
            return False
        if older_than is not None and file_time > older_than:
            return False
        return True

    def search_files(self, pattern: str, search_paths: List[str], use_regex: bool = False,
                    search_content: bool = False, min_size: Optional[int] = None,
                    max_size: Optional[int] = None, newer_than: Optional[datetime] = None,
                    older_than: Optional[datetime] = None,
                    progress: Optional[ProgressIndicator] = None) -> List[Path]:
        """Search for files and directories matching the pattern"""
        results = []
        seen_inodes = set()  # Prevent duplicate results from hard links

        for search_path in search_paths:
            try:
                # Check if we need sudo for this path
                needs_sudo = not os.access(search_path, os.R_OK)

                if needs_sudo and os.geteuid() != 0:
                    if not self.config.get('skip_permission_errors', True):
                        print(f"{Colors.YELLOW}Warning: {search_path} requires sudo access{Colors.RESET}")
                    continue

                for root, dirs, files in os.walk(search_path, followlinks=self.config['follow_symlinks']):
                    # Skip ignored paths
                    if self.should_ignore_path(root):
                        dirs.clear()  # Don't recurse into ignored directories
                        continue

                    # Remove hidden directories and excluded patterns
                    if not self.config['show_hidden']:
                        dirs[:] = [d for d in dirs if not d.startswith('.')]

                    # Apply exclude patterns
                    dirs[:] = [d for d in dirs if not self.should_exclude(d)]

                    if progress:
                        progress.update(dirs=len(dirs))
                    
                    # Search in directory names
                    for dirname in dirs:
                        if not self.config['show_hidden'] and dirname.startswith('.'):
                            continue
                            
                        dirpath = Path(root) / dirname
                        
                        # Skip if we've already seen this inode
                        try:
                            stat_info = dirpath.stat()
                            inode_key = (stat_info.st_dev, stat_info.st_ino)
                            if inode_key in seen_inodes:
                                continue
                            seen_inodes.add(inode_key)
                        except (OSError, IOError):
                            continue
                        
                        # Match pattern for directories
                        if self.matches_pattern(dirname, pattern, use_regex):
                            results.append(dirpath)
                        
                        # Limit results
                        if len(results) >= self.config['max_results']:
                            return results
                    
                    # Search in filenames
                    for filename in files:
                        if not self.config['show_hidden'] and filename.startswith('.'):
                            continue

                        # Skip excluded patterns
                        if self.should_exclude(filename):
                            continue

                        filepath = Path(root) / filename

                        # Skip if we've already seen this inode (hard links)
                        try:
                            stat_info = filepath.stat()
                            inode_key = (stat_info.st_dev, stat_info.st_ino)
                            if inode_key in seen_inodes:
                                continue
                            seen_inodes.add(inode_key)

                            # Apply size and date filters
                            if not self.matches_size_filter(stat_info.st_size, min_size, max_size):
                                continue
                            if not self.matches_date_filter(stat_info.st_mtime, newer_than, older_than):
                                continue

                        except (OSError, IOError):
                            continue

                        if progress:
                            progress.update(files=1)

                        # Match pattern
                        matched = False
                        if self.matches_pattern(filename, pattern, use_regex):
                            matched = True
                        elif search_content and filepath.is_file():
                            if self.search_file_content(filepath, pattern, use_regex):
                                matched = True

                        if matched:
                            results.append(filepath)
                            if progress:
                                progress.update(matches=1)

                        # Limit results
                        if len(results) >= self.config['max_results']:
                            return results

            except PermissionError:
                if not self.config.get('skip_permission_errors', True):
                    print(f"{Colors.RED}Permission denied: {search_path}{Colors.RESET}")
            except Exception as e:
                print(f"{Colors.RED}Error searching {search_path}: {e}{Colors.RESET}", file=sys.stderr)

        return results

    def matches_pattern(self, text: str, pattern: str, use_regex: bool) -> bool:
        """Check if text matches the search pattern"""
        if not self.config['case_sensitive']:
            text = text.lower()
            pattern = pattern.lower()
        
        if use_regex:
            try:
                return bool(re.search(pattern, text))
            except re.error:
                print(f"{Colors.RED}Invalid regex pattern: {pattern}{Colors.RESET}")
                return False
        else:
            return fnmatch.fnmatch(text, f"*{pattern}*")

    def search_file_content(self, filepath: Path, pattern: str, use_regex: bool) -> bool:
        """Search for pattern within file content"""
        try:
            # Skip binary files and large files
            if filepath.stat().st_size > 10 * 1024 * 1024:  # 10MB limit
                return False
            
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                return self.matches_pattern(content, pattern, use_regex)
        except (IOError, UnicodeDecodeError, PermissionError):
            return False

    def print_results(self, results: List[Path], pattern: str):
        """Print search results with color coding and type differentiation"""
        if not results:
            print(f"{Colors.RED}No files or directories found matching '{pattern}'{Colors.RESET}")
            return
        
        # Count files vs directories
        file_count = sum(1 for r in results if not r.is_dir())
        dir_count = sum(1 for r in results if r.is_dir())
        
        print(f"{Colors.GREEN}{Colors.BOLD}Found {len(results)} items matching '{pattern}' "
              f"({dir_count} directories, {file_count} files):{Colors.RESET}\n")
        
        # Group results by file type for better organization
        grouped_results = {}
        for filepath in results:
            file_type = self.get_file_type(filepath)
            if file_type not in grouped_results:
                grouped_results[file_type] = []
            grouped_results[file_type].append(filepath)
        
        # Print results grouped by type, with directories first
        type_order = ['directory', 'symlink'] + [t for t in sorted(grouped_results.keys()) 
                     if t not in ['directory', 'symlink']]
        
        for file_type in type_order:
            if file_type not in grouped_results:
                continue
                
            type_color = self.file_type_colors.get(file_type, Colors.TEXT)
            type_name = file_type.upper()
            if file_type == 'directory':
                type_name = "DIRECTORIES"
            elif file_type == 'symlink':
                type_name = "SYMBOLIC LINKS"
            else:
                type_name = f"{file_type.upper()} FILES"
                
            print(f"{type_color}{Colors.BOLD}{type_name}:{Colors.RESET}")
            
            for filepath in sorted(grouped_results[file_type]):
                colored_path = self.colorize_path(filepath, file_type)
                
                # Add file/directory info
                try:
                    stat_info = filepath.stat()
                    
                    if filepath.is_dir():
                        # For directories, show item count if possible
                        try:
                            item_count = len(list(filepath.iterdir()))
                            info = f"{item_count} items"
                        except (PermissionError, OSError):
                            info = "access denied"
                        mtime = self.format_time(stat_info.st_mtime)
                        print(f"  {colored_path} {Colors.DIM}({info}, {mtime}){Colors.RESET}")
                    else:
                        # For files, show size and modification time
                        size = self.format_size(stat_info.st_size)
                        mtime = self.format_time(stat_info.st_mtime)
                        
                        # Add symlink target info
                        extra_info = ""
                        if filepath.is_symlink():
                            try:
                                target = filepath.readlink()
                                extra_info = f" → {target}"
                            except (OSError, IOError):
                                extra_info = " → broken link"
                        
                        print(f"  {colored_path} {Colors.DIM}({size}, {mtime}){extra_info}{Colors.RESET}")
                        
                except (OSError, IOError):
                    print(f"  {colored_path}")
            print()

    def format_size(self, size_bytes: int) -> str:
        """Format file size in human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024:
                return f"{size_bytes:.1f}{unit}"
            size_bytes /= 1024
        return f"{size_bytes:.1f}TB"

    def format_time(self, timestamp: float) -> str:
        """Format timestamp in human readable format"""
        dt = datetime.fromtimestamp(timestamp)
        return dt.strftime('%Y-%m-%d %H:%M')

    def export_json(self, results: List[Path], output_file: str):
        """Export search results to JSON file."""
        try:
            data = []
            for filepath in results:
                try:
                    stat_info = filepath.stat()
                    item = {
                        'path': str(filepath),
                        'name': filepath.name,
                        'type': 'directory' if filepath.is_dir() else 'file',
                        'size': stat_info.st_size if not filepath.is_dir() else None,
                        'modified': datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
                        'is_symlink': filepath.is_symlink()
                    }

                    if filepath.is_symlink():
                        try:
                            item['symlink_target'] = str(filepath.readlink())
                        except (OSError, IOError):
                            item['symlink_target'] = None

                    data.append(item)
                except (OSError, IOError) as e:
                    print(f"{Colors.YELLOW}Warning: Could not stat {filepath}: {e}{Colors.RESET}",
                          file=sys.stderr)

            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2)

            print(f"{Colors.GREEN}Results exported to {output_file}{Colors.RESET}")

        except IOError as e:
            print(f"{Colors.RED}Error writing to {output_file}: {e}{Colors.RESET}", file=sys.stderr)

    def export_csv(self, results: List[Path], output_file: str):
        """Export search results to CSV file."""
        try:
            with open(output_file, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['Path', 'Name', 'Type', 'Size (bytes)', 'Modified', 'Is Symlink', 'Symlink Target'])

                for filepath in results:
                    try:
                        stat_info = filepath.stat()
                        row = [
                            str(filepath),
                            filepath.name,
                            'directory' if filepath.is_dir() else 'file',
                            stat_info.st_size if not filepath.is_dir() else '',
                            datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
                            'yes' if filepath.is_symlink() else 'no',
                            str(filepath.readlink()) if filepath.is_symlink() else ''
                        ]
                        writer.writerow(row)
                    except (OSError, IOError) as e:
                        print(f"{Colors.YELLOW}Warning: Could not stat {filepath}: {e}{Colors.RESET}",
                              file=sys.stderr)

            print(f"{Colors.GREEN}Results exported to {output_file}{Colors.RESET}")

        except IOError as e:
            print(f"{Colors.RED}Error writing to {output_file}: {e}{Colors.RESET}", file=sys.stderr)

    def run_with_sudo(self, args):
        """Re-run the script with sudo if needed"""
        if os.geteuid() != 0:
            print(f"{Colors.YELLOW}Requesting sudo access for system-wide search...{Colors.RESET}")
            try:
                subprocess.run(['sudo', sys.executable] + sys.argv, check=True)
                return True
            except subprocess.CalledProcessError:
                print(f"{Colors.RED}Sudo access denied or failed{Colors.RESET}")
                return False
        return True

def parse_size(size_str: str) -> int:
    """Parse size string like '10M', '1G', '500K' to bytes."""
    size_str = size_str.strip().upper()
    multipliers = {'B': 1, 'K': 1024, 'M': 1024**2, 'G': 1024**3, 'T': 1024**4}

    if size_str[-1] in multipliers:
        return int(float(size_str[:-1]) * multipliers[size_str[-1]])
    else:
        return int(size_str)

def parse_date(date_str: str) -> datetime:
    """Parse date string or relative time like '7d', '2w', '3m' to datetime."""
    date_str = date_str.strip().lower()

    # Relative time
    if date_str[-1] in ['d', 'w', 'm', 'y']:
        unit = date_str[-1]
        value = int(date_str[:-1])

        if unit == 'd':
            return datetime.now() - timedelta(days=value)
        elif unit == 'w':
            return datetime.now() - timedelta(weeks=value)
        elif unit == 'm':
            return datetime.now() - timedelta(days=value * 30)
        elif unit == 'y':
            return datetime.now() - timedelta(days=value * 365)

    # Absolute date (YYYY-MM-DD)
    try:
        return datetime.strptime(date_str, '%Y-%m-%d')
    except ValueError:
        raise ValueError(f"Invalid date format: {date_str}. Use YYYY-MM-DD or relative like '7d', '2w'")

def main():
    parser = argparse.ArgumentParser(
        description="Comprehensive file search tool with Catppuccin colors",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s "*.py"                        # Find all Python files and matching directories
  %(prog)s "config" -r                   # Regex search for files/dirs containing 'config'
  %(prog)s "TODO" -c                     # Search file contents (files only)
  %(prog)s "*.txt" -p /home              # Search only in /home
  %(prog)s "Downloads" -d                # Find directories named Downloads
  %(prog)s "script" -f                   # Find files only (no directories)
  %(prog)s "*.log" --sudo                # Search system-wide with sudo
  %(prog)s "*.mp4" --min-size 100M       # Find video files larger than 100MB
  %(prog)s "*.txt" --newer-than 7d       # Find text files modified in last 7 days
  %(prog)s "report" --export-json out.json  # Export results to JSON
  %(prog)s "*.py" --exclude "test_*"     # Exclude test files
        """
    )

    parser.add_argument('pattern', help='Search pattern for files and directories (supports wildcards)')
    parser.add_argument('-r', '--regex', action='store_true',
                       help='Use regular expressions')
    parser.add_argument('-c', '--content', action='store_true',
                       help='Search file contents (slower, files only)')
    parser.add_argument('-f', '--files-only', action='store_true',
                       help='Search files only (exclude directories)')
    parser.add_argument('-d', '--dirs-only', action='store_true',
                       help='Search directories only (exclude files)')
    parser.add_argument('-p', '--path', action='append', dest='paths',
                       help='Search paths (can be used multiple times)')
    parser.add_argument('--sudo', action='store_true',
                       help='Run with sudo for system-wide access')
    parser.add_argument('--config', action='store_true',
                       help='Show current configuration')
    parser.add_argument('--max-results', type=int, metavar='N',
                       help='Maximum number of results to show')
    parser.add_argument('--case-sensitive', action='store_true',
                       help='Case sensitive search')
    parser.add_argument('--show-hidden', action='store_true',
                       help='Include hidden files and directories')

    # Size filters
    parser.add_argument('--min-size', type=str, metavar='SIZE',
                       help='Minimum file size (e.g., 10M, 1G, 500K)')
    parser.add_argument('--max-size', type=str, metavar='SIZE',
                       help='Maximum file size (e.g., 10M, 1G, 500K)')

    # Date filters
    parser.add_argument('--newer-than', type=str, metavar='DATE',
                       help='Files modified after date (YYYY-MM-DD or relative like 7d, 2w, 3m)')
    parser.add_argument('--older-than', type=str, metavar='DATE',
                       help='Files modified before date (YYYY-MM-DD or relative like 7d, 2w, 3m)')

    # Export options
    parser.add_argument('--export-json', type=str, metavar='FILE',
                       help='Export results to JSON file')
    parser.add_argument('--export-csv', type=str, metavar='FILE',
                       help='Export results to CSV file')

    # Exclude patterns
    parser.add_argument('--exclude', action='append', dest='exclude_patterns',
                       help='Exclude pattern (can be used multiple times)')

    # Progress
    parser.add_argument('--no-progress', action='store_true',
                       help='Disable progress indicator')

    args = parser.parse_args()

    searcher = FileSearcher()

    # Show configuration if requested
    if args.config:
        print(f"{Colors.BLUE}{Colors.BOLD}Current Configuration:{Colors.RESET}")
        print(json.dumps(searcher.config, indent=2))
        return

    # Update config based on command line arguments
    if args.max_results:
        searcher.config['max_results'] = args.max_results
    if args.case_sensitive:
        searcher.config['case_sensitive'] = True
    if args.show_hidden:
        searcher.config['show_hidden'] = True
    if args.no_progress:
        searcher.config['show_progress'] = False

    # Add exclude patterns from command line
    if args.exclude_patterns:
        searcher.config['exclude_patterns'].extend(args.exclude_patterns)

    # Handle sudo requirement
    if args.sudo and os.geteuid() != 0:
        if not searcher.run_with_sudo(args):
            return

    # Parse size filters
    min_size = None
    max_size = None
    try:
        if args.min_size:
            min_size = parse_size(args.min_size)
        if args.max_size:
            max_size = parse_size(args.max_size)
    except ValueError as e:
        print(f"{Colors.RED}Error: {e}{Colors.RESET}", file=sys.stderr)
        sys.exit(1)

    # Parse date filters
    newer_than = None
    older_than = None
    try:
        if args.newer_than:
            newer_than = parse_date(args.newer_than)
        if args.older_than:
            older_than = parse_date(args.older_than)
    except ValueError as e:
        print(f"{Colors.RED}Error: {e}{Colors.RESET}", file=sys.stderr)
        sys.exit(1)

    # Determine search paths
    search_paths = args.paths if args.paths else ['/']

    # Create progress indicator
    progress = ProgressIndicator(show_progress=searcher.config['show_progress'])
    progress.start()

    # Perform search
    print(f"{Colors.SAPPHIRE}Searching for '{args.pattern}'...{Colors.RESET}")
    try:
        results = searcher.search_files(
            pattern=args.pattern,
            search_paths=search_paths,
            use_regex=args.regex,
            search_content=args.content,
            min_size=min_size,
            max_size=max_size,
            newer_than=newer_than,
            older_than=older_than,
            progress=progress
        )
    finally:
        progress.stop()

    # Filter results based on type preference
    if args.files_only:
        results = [r for r in results if not r.is_dir()]
    elif args.dirs_only:
        results = [r for r in results if r.is_dir()]

    # Export if requested
    if args.export_json:
        searcher.export_json(results, args.export_json)
    if args.export_csv:
        searcher.export_csv(results, args.export_csv)

    # Always display results to terminal (export doesn't suppress display)
    searcher.print_results(results, args.pattern)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Search interrupted by user{Colors.RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"{Colors.RED}Unexpected error: {e}{Colors.RESET}")
        sys.exit(1)
