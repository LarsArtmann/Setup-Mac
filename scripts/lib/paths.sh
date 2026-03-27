#!/usr/bin/env bash
# Path Constants Library for Shell Scripts
# Centralized path management to eliminate hardcoded paths throughout scripts
#
# Usage:
#   source scripts/lib/paths.sh
#   echo $PROJECT_ROOT
#   cd "$DOTFILES_DIR"

set -euo pipefail

# Determine project root (SystemNix repository)
# Walk up directory tree to find flake.nix
_find_project_root() {
    local dir="${BASH_SOURCE[0]}"
    while [[ "$dir" != "/" ]]; do
        dir="$(dirname "$dir")"
        if [[ -f "$dir/flake.nix" ]]; then
            echo "$dir"
            return 0
        fi
    done
    # Fallback to relative path from this script
    dirname "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
}

# Project structure paths
export PROJECT_ROOT="$(_find_project_root)"
export DOTFILES_DIR="$PROJECT_ROOT/dotfiles"
export PLATFORMS_DIR="$PROJECT_ROOT/platforms"
export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
export DOCS_DIR="$PROJECT_ROOT/docs"
export PKGS_DIR="$PROJECT_ROOT/pkgs"

# Platform-specific paths
export COMMON_DIR="$PLATFORMS_DIR/common"
export DARWIN_DIR="$PLATFORMS_DIR/darwin"
export NIXOS_DIR="$PLATFORMS_DIR/nixos"

# Common subdirectories
export COMMON_PACKAGES="$COMMON_DIR/packages"
export COMMON_PROGRAMS="$COMMON_DIR/programs"
export COMMON_CORE="$COMMON_DIR/core"

# User-specific paths (dynamically determined)
export USER_HOME="${HOME:-$(eval echo ~$USER)}"
export USER_CONFIG="$USER_HOME/.config"
export USER_PROJECTS="$USER_HOME/projects"

# Nix-specific paths
export NIX_CONFIG_DIR="$DOTFILES_DIR/nix"
export NIX_CORE_DIR="$NIX_CONFIG_DIR/core"

# Backup directory
export BACKUP_DIR="$PROJECT_ROOT/.backups"
export BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Helper functions

# Get path to a specific platform directory
# Usage: get_platform_dir "darwin" "programs"
get_platform_dir() {
    local platform="$1"
    local subdir="${2:-}"
    local base_path

    case "$platform" in
        darwin|macos)
            base_path="$DARWIN_DIR"
            ;;
        nixos|linux)
            base_path="$NIXOS_DIR"
            ;;
        common)
            base_path="$COMMON_DIR"
            ;;
        *)
            echo "Error: Unknown platform '$platform'" >&2
            return 1
            ;;
    esac

    if [[ -n "$subdir" ]]; then
        echo "$base_path/$subdir"
    else
        echo "$base_path"
    fi
}

# Resolve a path relative to project root
# Usage: resolve_path "platforms/darwin/default.nix"
resolve_path() {
    local relative_path="$1"
    echo "$PROJECT_ROOT/$relative_path"
}

# Check if running on macOS (Darwin)
is_darwin() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Check if running on Linux (NixOS)
is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# Get current platform name
get_platform() {
    if is_darwin; then
        echo "darwin"
    elif is_linux; then
        echo "nixos"
    else
        echo "unknown"
    fi
}

# Ensure a directory exists, create if necessary
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo "Created directory: $dir"
    fi
}

# Get backup path for a file
# Usage: get_backup_path "/path/to/file.txt"
get_backup_path() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    echo "$BACKUP_DIR/${filename}.backup.$BACKUP_TIMESTAMP"
}

# Validate that project root was found correctly
validate_project_root() {
    if [[ ! -f "$PROJECT_ROOT/flake.nix" ]]; then
        echo "Error: Could not find project root (flake.nix not found)" >&2
        echo "Detected PROJECT_ROOT: $PROJECT_ROOT" >&2
        return 1
    fi
}

# Debug function to print all paths
debug_paths() {
    echo "=== Path Constants ==="
    echo "PROJECT_ROOT: $PROJECT_ROOT"
    echo "DOTFILES_DIR: $DOTFILES_DIR"
    echo "PLATFORMS_DIR: $PLATFORMS_DIR"
    echo "SCRIPTS_DIR: $SCRIPTS_DIR"
    echo "USER_HOME: $USER_HOME"
    echo "PLATFORM: $(get_platform)"
    echo "====================="
}

# Run validation on source (optional, comment out if not needed)
# validate_project_root
