#!/bin/bash

# General Utility Script
# Provides various helper functions

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Check if user is root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Check operating system
get_os_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$NAME $VERSION_ID"
    elif type lsb_release >/dev/null 2>&1; then
        lsb_release -d | cut -f2
    else
        uname -s
    fi
}

# Check architecture
get_arch() {
    uname -m
}

# Get CPU information
get_cpu_info() {
    if command_exists lscpu; then
        lscpu | grep "Model name" | cut -d: -f2 | xargs
    else
        cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2 | xargs
    fi
}

# Get memory information
get_memory_info() {
    if command_exists free; then
        free -h | grep "Mem:" | awk '{print $2}'
    else
        echo "Unknown"
    fi
}

# Get disk information
get_disk_info() {
    if command_exists df; then
        df -h / | tail -1 | awk '{print $2}'
    else
        echo "Unknown"
    fi
}

# Check network connectivity
check_network() {
    if command_exists ping; then
        ping -c 1 8.8.8.8 >/dev/null 2>&1
    else
        return 1
    fi
}

# Download file
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists wget; then
        wget -O "$output" "$url"
    elif command_exists curl; then
        curl -L -o "$output" "$url"
    else
        log_error "Neither wget nor curl is installed, cannot download file"
        return 1
    fi
}

# Extract file
extract_file() {
    local file="$1"
    local output_dir="$2"
    
    case "$file" in
        *.tar.gz|*.tgz)
            tar -xzf "$file" -C "$output_dir"
            ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "$file" -C "$output_dir"
            ;;
        *.zip)
            if command_exists unzip; then
                unzip "$file" -d "$output_dir"
            else
                log_error "unzip not installed, cannot extract zip file"
                return 1
            fi
            ;;
        *.rar)
            if command_exists unrar; then
                unrar x "$file" "$output_dir"
            else
                log_error "unrar not installed, cannot extract rar file"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported file format: $file"
            return 1
            ;;
    esac
}

# Create backup
create_backup() {
    local source="$1"
    local backup_dir="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="$(basename "$source")_${timestamp}.bak"
    
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
    fi
    
    if [[ -f "$source" ]]; then
        cp "$source" "$backup_dir/$backup_name"
        log_info "Backup created: $backup_dir/$backup_name"
    elif [[ -d "$source" ]]; then
        tar -czf "$backup_dir/$backup_name.tar.gz" -C "$(dirname "$source")" "$(basename "$source")"
        log_info "Backup created: $backup_dir/$backup_name.tar.gz"
    else
        log_error "Source file does not exist: $source"
        return 1
    fi
}

# Restore backup
restore_backup() {
    local backup_file="$1"
    local target_dir="$2"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file does not exist: $backup_file"
        return 1
    fi
    
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    case "$backup_file" in
        *.tar.gz)
            tar -xzf "$backup_file" -C "$target_dir"
            ;;
        *.bak)
            cp "$backup_file" "$target_dir/"
            ;;
        *)
            log_error "Unsupported backup format: $backup_file"
            return 1
            ;;
    esac
    
    log_info "Backup restored: $backup_file"
}

# Check if port is in use
check_port() {
    local port="$1"
    
    if command_exists netstat; then
        netstat -tuln | grep ":$port " >/dev/null 2>&1
    elif command_exists ss; then
        ss -tuln | grep ":$port " >/dev/null 2>&1
    else
        log_error "Neither netstat nor ss is installed, cannot check port"
        return 1
    fi
}

# Get available port
get_available_port() {
    local start_port="${1:-8000}"
    local end_port="${2:-9000}"
    
    for port in $(seq "$start_port" "$end_port"); do
        if ! check_port "$port"; then
            echo "$port"
            return 0
        fi
    done
    
    log_error "No available port in range $start_port-$end_port"
    return 1
}

# Generate random string
generate_random_string() {
    local length="${1:-8}"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$length" | head -n 1
}

# Generate UUID
generate_uuid() {
    if command_exists uuidgen; then
        uuidgen
    else
        python3 -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || echo "uuid-generator-not-available"
    fi
}

# Format file size
format_file_size() {
    local bytes="$1"
    
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Get file size
get_file_size() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Check Python environment
check_python_env() {
    if ! command_exists python3; then
        log_error "Python3 not installed"
        return 1
    fi
    
    local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    log_info "Python version: $python_version"
    
    # Check pip
    if ! command_exists pip3; then
        log_warn "pip3 not installed"
        return 1
    fi
    
    return 0
}

# Install Python package
install_python_package() {
    local package="$1"
    
    if ! check_python_env; then
        return 1
    fi
    
    log_info "Installing Python package: $package"
    pip3 install "$package"
}

# Check Docker environment
check_docker_env() {
    if ! command_exists docker; then
        log_error "Docker not installed"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker service not running or insufficient permissions"
        return 1
    fi
    
    local docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
    log_info "Docker version: $docker_version"
    
    return 0
}

# Show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Wait for user confirmation
confirm() {
    local message="${1:-Continue?}"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " -n 1 -r
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
    else
        read -p "$message [y/N]: " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Show system information
show_system_info() {
    log_info "System information:"
    echo "  Operating System: $(get_os_info)"
    echo "  Architecture: $(get_arch)"
    echo "  CPU: $(get_cpu_info)"
    echo "  Memory: $(get_memory_info)"
    echo "  Disk: $(get_disk_info)"
    echo "  Network: $(check_network && echo "Normal" || echo "Abnormal")"
}

# Clean up temporary files
cleanup_temp_files() {
    local temp_dir="${1:-/tmp}"
    local pattern="${2:-xpu_bench_*}"
    local max_age="${3:-7}"  # days
    
    log_info "Cleaning up temporary files..."
    
    if [[ -d "$temp_dir" ]]; then
        find "$temp_dir" -name "$pattern" -mtime +$max_age -delete 2>/dev/null || true
        log_info "Temporary files cleaned up in $temp_dir"
    fi
}

# Check and create directory
ensure_dir() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

# Check and set permissions
set_permissions() {
    local path="$1"
    local permissions="${2:-755}"
    
    if [[ -e "$path" ]]; then
        chmod "$permissions" "$path"
        log_info "Set permissions $permissions: $path"
    else
        log_warn "File does not exist: $path"
    fi
}

# Export all functions (if needed)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If this script is run directly, show help information
    echo "This is a utility script containing various helper functions."
    echo "Please source this file in other scripts to use these functions."
    echo ""
    echo "Example:"
    echo "  source scripts/utils.sh"
    echo "  log_info 'Hello World'"
fi 