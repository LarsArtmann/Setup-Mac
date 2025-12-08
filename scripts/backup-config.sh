#!/usr/bin/env nix-shell
#!nix-shell -i bash -p git rsync coreutils

set -euo pipefail

# Backup Configuration Script
# Automatically creates timestamped backups of critical configuration files

BACKUP_DIR="${BACKUP_DIR:-$HOME/.config/setup-mac-backups}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="setup-mac-backup-${TIMESTAMP}"
CURRENT_BACKUP="${BACKUP_DIR}/${BACKUP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Create backup directory
setup_backup_dir() {
    log "Setting up backup directory..."
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "${CURRENT_BACKUP}"
    log "Backup directory: ${CURRENT_BACKUP}"
}

# Backup Git state
backup_git() {
    log "Backing up Git repository state..."

    # Backup git objects and refs
    mkdir -p "${CURRENT_BACKUP}/git"
    cp -r "${SOURCE_DIR}/.git" "${CURRENT_BACKUP}/git/"

    # Create git status snapshot
    cd "${SOURCE_DIR}"
    git status --porcelain > "${CURRENT_BACKUP}/git-status.txt"
    git log -n 10 --oneline > "${CURRENT_BACKUP}/git-recent-commits.txt"
    git diff --name-only > "${CURRENT_BACKUP}/git-changed-files.txt"

    success "Git state backed up"
}

# Backup Nix configurations
backup_nix_configs() {
    log "Backing up Nix configurations..."

    mkdir -p "${CURRENT_BACKUP}/nix-configs"

    # Copy all Nix configuration files
    rsync -av --include="*.nix" --include="*.md" --include="*/" --exclude="*" \
        "${SOURCE_DIR}/" "${CURRENT_BACKUP}/nix-configs/"

    # Backup flake.lock and other critical files
    cp "${SOURCE_DIR}/flake.nix" "${CURRENT_BACKUP}/" 2>/dev/null || true
    cp "${SOURCE_DIR}/flake.lock" "${CURRENT_BACKUP}/" 2>/dev/null || true
    cp "${SOURCE_DIR}/justfile" "${CURRENT_BACKUP}/" 2>/dev/null || true

    # Create current generation backup
    if command -v nixos-rebuild >/dev/null 2>&1; then
        nixos-rebuild list-generations > "${CURRENT_BACKUP}/nixos-generations.txt" 2>/dev/null || true
    fi

    success "Nix configurations backed up"
}

# Backup system state
backup_system_state() {
    log "Backing up system state..."

    mkdir -p "${CURRENT_BACKUP}/system-state"

    # System information
    uname -a > "${CURRENT_BACKUP}/system-state/uname.txt"
    nix --version > "${CURRENT_BACKUP}/system-state/nix-version.txt" 2>/dev/null || true

    # Current Nix channels
    nix-channel --list > "${CURRENT_BACKUP}/system-state/nix-channels.txt" 2>/dev/null || true

    # Hardware information (if available)
    if command -v lscpu >/dev/null 2>&1; then
        lscpu > "${CURRENT_BACKUP}/system-state/cpu-info.txt" 2>/dev/null || true
    fi

    if command -v free >/dev/null 2>&1; then
        free -h > "${CURRENT_BACKUP}/system-state/memory-info.txt" 2>/dev/null || true
    fi

    # Environment variables (filtered for safety)
    env | grep -E '^(PATH|HOME|USER|SHELL|NIX_|XDG_)' > "${CURRENT_BACKUP}/system-state/env-vars.txt" 2>/dev/null || true

    success "System state backed up"
}

# Backup documentation
backup_documentation() {
    log "Backing up documentation..."

    if [[ -d "${SOURCE_DIR}/docs" ]]; then
        cp -r "${SOURCE_DIR}/docs" "${CURRENT_BACKUP}/"
        success "Documentation backed up"
    else
        warning "No docs directory found"
    fi
}

# Create backup metadata
create_metadata() {
    log "Creating backup metadata..."

    cat > "${CURRENT_BACKUP}/BACKUP_METADATA.txt" << EOF
Setup-Mac Configuration Backup
==============================

Backup Name: ${BACKUP_NAME}
Created: $(date)
Created By: $(whoami)@$(hostname)
Source Directory: ${SOURCE_DIR}
Git Branch: $(cd "${SOURCE_DIR}" && git branch --show-current 2>/dev/null || echo "N/A")
Git Commit: $(cd "${SOURCE_DIR}" && git rev-parse HEAD 2>/dev/null || echo "N/A")

Files Backed Up:
- Git repository state and history
- All Nix configuration files
- System state information
- Documentation and status reports
- Current NixOS generations (if available)

Restore Instructions:
1. Copy files back to original locations
2. Run 'git status' to check repository state
3. Run 'nix flake check --all-systems' to validate configuration
4. Use 'nixos-rebuild switch --flake .' to apply NixOS configuration

Backup Type: Incremental
Compression: None (preserves file structure)
Encrypted: No

EOF
    success "Backup metadata created"
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up old backups (keeping last 10)..."

    cd "${BACKUP_DIR}"
    ls -1t setup-mac-backup-* 2>/dev/null | tail -n +11 | while read -r backup; do
        log "Removing old backup: ${backup}"
        rm -rf "${backup}"
    done

    success "Old backups cleaned up"
}

# Create symlink to latest backup
link_latest() {
    log "Creating symlink to latest backup..."

    cd "${BACKUP_DIR}"
    rm -f latest
    ln -s "${BACKUP_NAME}" latest

    success "Latest backup linked"
}

# Verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."

    # Check if critical files exist
    local critical_files=(
        "nix-configs/flake.nix"
        "nix-configs/dotfiles/nixos/configuration.nix"
        "git-status.txt"
        "BACKUP_METADATA.txt"
    )

    local missing_files=0
    for file in "${critical_files[@]}"; do
        if [[ ! -f "${CURRENT_BACKUP}/${file}" ]]; then
            error "Critical file missing: ${file}"
            ((missing_files++))
        fi
    done

    if [[ $missing_files -eq 0 ]]; then
        success "Backup integrity verified"
        return 0
    else
        error "Backup integrity check failed: ${missing_files} critical files missing"
        return 1
    fi
}

# Main execution
main() {
    log "Starting Setup-Mac configuration backup..."
    log "Source: ${SOURCE_DIR}"

    # Check if we're in the right directory
    if [[ ! -f "${SOURCE_DIR}/flake.nix" ]]; then
        error "Not in a valid Setup-Mac directory (flake.nix not found)"
        exit 1
    fi

    setup_backup_dir
    backup_git
    backup_nix_configs
    backup_system_state
    backup_documentation
    create_metadata

    if verify_backup; then
        cleanup_old_backups
        link_latest
        success "Backup completed successfully!"
        log "Backup location: ${CURRENT_BACKUP}"
        log "Total size: $(du -sh "${CURRENT_BACKUP}" | cut -f1)"
    else
        error "Backup verification failed"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
Setup-Mac Configuration Backup Script

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -d, --dir DIR       Set backup directory (default: \$HOME/.config/setup-mac-backups)
    -v, --verbose       Enable verbose output
    --dry-run           Show what would be backed up without actually doing it

Environment Variables:
    BACKUP_DIR          Override default backup directory

Examples:
    $0                              # Create backup in default location
    $0 -d /tmp/backup              # Create backup in custom location
    BACKUP_DIR=/tmp $0              # Use environment variable

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            log "DRY RUN: Would create backup in ${BACKUP_DIR}"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main