#!/bin/bash

# Comprehensive Cleanup Script for Setup-Mac Project
# ================================================
# Removes temporary files, logs, caches, and old backups
# Supports dry-run mode for safety

set -euo pipefail

# Configuration
DEFAULT_BACKUP_RETENTION_DAYS=30
DEFAULT_LOG_RETENTION_DAYS=7
DEFAULT_CACHE_RETENTION_DAYS=3

# Global flags
DRY_RUN=false
VERBOSE=false
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-$DEFAULT_BACKUP_RETENTION_DAYS}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-$DEFAULT_LOG_RETENTION_DAYS}"
CACHE_RETENTION_DAYS="${CACHE_RETENTION_DAYS:-$DEFAULT_CACHE_RETENTION_DAYS}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << EOF
Cleanup Script for Setup-Mac Project

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --dry-run                     Preview what would be cleaned without actually doing it
    --verbose                     Show detailed information about cleanup operations
    --backup-retention DAYS       Keep backups newer than DAYS (default: 30)
    --log-retention DAYS          Keep logs newer than DAYS (default: 7)
    --cache-retention DAYS        Keep cache files newer than DAYS (default: 3)
    --help                        Show this help message

EXAMPLES:
    $0 --dry-run                  Preview cleanup operations
    $0 --verbose                  Run cleanup with detailed output
    $0 --backup-retention 14      Keep only backups from last 14 days

CLEANED ITEMS:
    - Temporary files and directories
    - Old backup files
    - Build artifacts and caches
    - Log files
    - Claude configuration backups
    - Nix build results
    - Go module cache
    - Node.js cache files
    - macOS temporary files

ENVIRONMENT VARIABLES:
    BACKUP_RETENTION_DAYS         Default backup retention (overridden by --backup-retention)
    LOG_RETENTION_DAYS           Default log retention (overridden by --log-retention)
    CACHE_RETENTION_DAYS         Default cache retention (overridden by --cache-retention)
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --backup-retention)
            BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        --log-retention)
            LOG_RETENTION_DAYS="$2"
            shift 2
            ;;
        --cache-retention)
            CACHE_RETENTION_DAYS="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate numeric arguments
validate_number() {
    local value="$1"
    local name="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "$name must be a positive number, got: $value"
        exit 1
    fi
}

validate_number "$BACKUP_RETENTION_DAYS" "backup retention days"
validate_number "$LOG_RETENTION_DAYS" "log retention days"
validate_number "$CACHE_RETENTION_DAYS" "cache retention days"

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local description="$2"

    if [[ -e "$path" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would remove: $path ($description)"
        else
            log_verbose "Removing: $path ($description)"
            if [[ -d "$path" ]]; then
                rm -rf "$path"
            else
                rm -f "$path"
            fi
            log_success "Removed: $description"
        fi
    else
        log_verbose "Not found (skipping): $path"
    fi
}

# Function to remove files older than specified days
remove_old_files() {
    local directory="$1"
    local pattern="$2"
    local days="$3"
    local description="$4"

    if [[ ! -d "$directory" ]]; then
        log_verbose "Directory not found: $directory"
        return 0
    fi

    log_verbose "Checking for $description older than $days days in $directory"

    local count=0
    while IFS= read -r -d '' file; do
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would remove: $file"
        else
            log_verbose "Removing old file: $file"
            rm -f "$file"
        fi
        ((count++))
    done < <(find "$directory" -name "$pattern" -type f -mtime +"$days" -print0 2>/dev/null || true)

    if [[ $count -gt 0 ]]; then
        log_success "Cleaned $count old $description files"
    else
        log_verbose "No old $description files found"
    fi
}

# Function to get directory size
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1 || echo "unknown"
    else
        echo "0B"
    fi
}

# Main cleanup function
main_cleanup() {
    log_info "Starting cleanup process..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No files will actually be removed"
    fi

    log_info "Configuration:"
    log_info "  Backup retention: $BACKUP_RETENTION_DAYS days"
    log_info "  Log retention: $LOG_RETENTION_DAYS days"
    log_info "  Cache retention: $CACHE_RETENTION_DAYS days"
    echo

    # Clean temporary directories
    log_info "Cleaning temporary directories..."

    # Project-specific temporary files
    safe_remove "/tmp/claude_*" "Claude temporary files"
    safe_remove "/tmp/*_benchmark.*" "Benchmark result files"
    safe_remove "/tmp/nix-build-*" "Nix build temporary directories"

    # Clean backup directories
    log_info "Cleaning old backups..."

    # Project backup directory
    if [[ -d "10568BACKUP_DIR" ]]; then
        local backup_size=$(get_dir_size "10568BACKUP_DIR")
        log_verbose "Current backup directory size: $backup_size"
        remove_old_files "10568BACKUP_DIR" "*" "$BACKUP_RETENTION_DAYS" "backup files"
    fi

    # Claude configuration backups
    remove_old_files "$HOME" ".claude-config-*-*.json" "$BACKUP_RETENTION_DAYS" "Claude config backups"

    # Clean logs
    log_info "Cleaning old logs..."

    # System logs (if we have permission)
    remove_old_files "/var/log" "*.log" "$LOG_RETENTION_DAYS" "system logs"
    remove_old_files "$HOME/Library/Logs" "*.log" "$LOG_RETENTION_DAYS" "user logs"

    # Clean caches
    log_info "Cleaning caches..."

    # Nix store cleanup (only if we own it)
    if command -v nix-collect-garbage >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would run: nix-collect-garbage -d"
        else
            log_info "Running Nix garbage collection..."
            nix-collect-garbage -d >/dev/null 2>&1 || log_warning "Nix garbage collection failed (this is usually fine)"
            log_success "Nix garbage collection completed"
        fi
    fi

    # Go module cache
    if command -v go >/dev/null 2>&1; then
        local go_cache_dir=$(go env GOCACHE 2>/dev/null || echo "")
        if [[ -n "$go_cache_dir" && -d "$go_cache_dir" ]]; then
            local cache_size=$(get_dir_size "$go_cache_dir")
            log_verbose "Go cache size: $cache_size"
            remove_old_files "$go_cache_dir" "*" "$CACHE_RETENTION_DAYS" "Go cache files"
        fi
    fi

    # Node.js/Bun caches
    if [[ -d "$HOME/.cache/bun" ]]; then
        local bun_cache_size=$(get_dir_size "$HOME/.cache/bun")
        log_verbose "Bun cache size: $bun_cache_size"
        remove_old_files "$HOME/.cache/bun" "*" "$CACHE_RETENTION_DAYS" "Bun cache files"
    fi

    # NPM cache
    if [[ -d "$HOME/.npm" ]]; then
        local npm_cache_size=$(get_dir_size "$HOME/.npm")
        log_verbose "NPM cache size: $npm_cache_size"
        remove_old_files "$HOME/.npm" "*" "$CACHE_RETENTION_DAYS" "NPM cache files"
    fi

    # Homebrew cache
    if command -v brew >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would run: brew cleanup"
        else
            log_info "Running Homebrew cleanup..."
            brew cleanup >/dev/null 2>&1 || log_warning "Homebrew cleanup failed"
            log_success "Homebrew cleanup completed"
        fi
    fi

    # macOS caches
    log_info "Cleaning macOS caches..."

    # User caches
    if [[ -d "$HOME/Library/Caches" ]]; then
        remove_old_files "$HOME/Library/Caches" "*" "$CACHE_RETENTION_DAYS" "user cache files"
    fi

    # Clean build artifacts
    log_info "Cleaning build artifacts..."

    # Nix result symlinks
    safe_remove "result" "Nix build result symlink"
    safe_remove "result-*" "Nix build result symlinks"

    # Go build artifacts
    safe_remove "better-claude-go/better-claude" "Go binary"
    safe_remove "better-claude-go/better-claude-old" "Old Go binary"

    # Clean editor temporary files
    log_info "Cleaning editor temporary files..."

    # Vim temporary files
    safe_remove "*.swp" "Vim swap files"
    safe_remove "*.swo" "Vim swap files"
    safe_remove "*~" "Backup files"

    # VS Code temporary files
    safe_remove ".vscode/settings.json.bak" "VS Code backup settings"

    # JetBrains temporary files
    safe_remove ".idea/workspace.xml.bak" "JetBrains workspace backup"

    echo
    log_success "Cleanup completed!"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Run without --dry-run to actually perform cleanup"
    else
        log_info "Consider running 'nix-collect-garbage -d' manually for deeper Nix cleanup"
        log_info "Consider running 'brew cleanup --prune=7' for more aggressive Homebrew cleanup"
    fi
}

# Function to show disk space before and after
show_disk_usage() {
    log_info "Current disk usage:"
    df -h / | tail -1 | awk '{print "  Root filesystem: " $3 " used, " $4 " available (" $5 " used)"}'

    if [[ -d "/nix" ]]; then
        df -h /nix 2>/dev/null | tail -1 | awk '{print "  Nix store: " $3 " used, " $4 " available (" $5 " used)"}' || true
    fi
    echo
}

# Pre-cleanup disk usage
show_disk_usage

# Run main cleanup
main_cleanup

# Post-cleanup disk usage (only if not dry-run)
if [[ "$DRY_RUN" != "true" ]]; then
    echo
    log_info "Disk usage after cleanup:"
    show_disk_usage
fi

log_info "For regular maintenance, consider adding this script to a cron job:"
log_info "  0 2 * * 0 $0 --backup-retention 30 --log-retention 7 --cache-retention 3"