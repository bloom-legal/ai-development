#!/usr/bin/env bash
# Common functions and utilities for all bash scripts
# Source this file in scripts: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Initialize colors (with fallback for non-color terminals)
init_colors() {
    if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
        export COLOR_GREEN='\033[0;32m'
        export COLOR_RED='\033[0;31m'
        export COLOR_YELLOW='\033[1;33m'
        export COLOR_BLUE='\033[0;34m'
        export COLOR_CYAN='\033[0;36m'
        export COLOR_RESET='\033[0m'
        export COLOR_DIM='\033[2m'
        export COLOR_BOLD='\033[1m'
    else
        export COLOR_GREEN=''
        export COLOR_RED=''
        export COLOR_YELLOW=''
        export COLOR_BLUE=''
        export COLOR_CYAN=''
        export COLOR_RESET=''
        export COLOR_DIM=''
        export COLOR_BOLD=''
    fi
}

# Logging functions
log() { echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"; }
warn() { echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"; }
error() { echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"; }
header() { echo -e "\n${COLOR_BLUE}=== $1 ===${COLOR_RESET}"; }
info() { echo -e "${COLOR_CYAN}$1${COLOR_RESET}"; }

# Get script directory (works when sourced or executed)
get_script_dir() {
    local script_path="${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
    if [[ -z "$script_path" ]]; then
        script_path="$0"
    fi
    cd "$(dirname "$script_path")" && pwd
}

# Setup Homebrew PATH
setup_brew_path() {
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export PATH="/opt/homebrew/bin:$PATH"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        export PATH="/usr/local/bin:$PATH"
    fi
}

# Check if terminal supports TUI
check_tui_support() {
    if [[ -t 0 ]] && [[ -t 1 ]] && command -v tput &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Hide/show cursor for TUI
hide_cursor() {
    if check_tui_support; then
        tput civis 2>/dev/null || true
    fi
}

show_cursor() {
    if check_tui_support; then
        tput cnorm 2>/dev/null || true
    fi
}

# Retry function for network operations
retry_command() {
    local cmd="$1"
    local desc="$2"
    local max_attempts="${3:-3}"
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if eval "$cmd"; then
            return 0
        fi
        warn "Attempt $attempt/$max_attempts failed: $desc"
        ((attempt++))
        sleep 2
    done
    error "Failed after $max_attempts attempts: $desc"
    return 1
}

# Detect development folder in home directory
# Matches: Development, development, developpement, développement, dev (case-insensitive)
# Returns existing folder if found, or locale-appropriate default
detect_dev_folder() {
    local home_dir="${1:-$HOME}"
    
    # First, check for existing dev folders
    for dir in "$home_dir"/*/; do
        [ -d "$dir" ] || continue
        local name=$(basename "$dir")
        local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        # Remove accents: handle common French accents
        local name_normalized=$(echo "$name_lower" | sed 's/[éèêë]/e/g; s/[àâä]/a/g; s/[ùûü]/u/g; s/[îï]/i/g; s/[ôö]/o/g; s/ç/c/g')
        
        # Match: dev, development, developpement (after accent removal)
        if [[ "$name_normalized" =~ ^(dev|development|developpement)$ ]]; then
            echo "${dir%/}"
            return 0
        fi
    done
    
    # No existing folder found - return locale-appropriate default (don't create it)
    local locale=$(defaults read -g AppleLocale 2>/dev/null || echo "en_US")
    if [[ "$locale" =~ ^fr ]]; then
        echo "$home_dir/Développement"
    else
        echo "$home_dir/Development"
    fi
    return 1
}

# Get the dev folder (cached for performance)
get_dev_folder() {
    if [ -z "${DEV_FOLDER:-}" ]; then
        DEV_FOLDER=$(detect_dev_folder)
        export DEV_FOLDER
    fi
    echo "$DEV_FOLDER"
}

# Initialize colors on load
init_colors
