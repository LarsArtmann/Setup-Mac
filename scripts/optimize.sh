#!/bin/bash

# Automated Performance Optimization Script for Setup-Mac Project
# ==============================================================
# Applies various performance optimizations based on system analysis
# Supports different optimization profiles and safe rollback

set -euo pipefail

# Configuration
DRY_RUN=false
PROFILE="balanced"
CREATE_BACKUP=true
VERBOSE=false
SKIP_VERIFICATION=false

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
Automated Performance Optimization Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --dry-run                     Preview optimizations without applying them
    --profile PROFILE             Optimization profile: conservative, balanced, aggressive (default: balanced)
    --no-backup                   Skip creating backup before applying optimizations
    --verbose                     Show detailed information about operations
    --skip-verification           Skip post-optimization verification
    --help                        Show this help message

PROFILES:
    conservative                  Safe optimizations with minimal risk
    balanced                      Good performance gains with low risk (default)
    aggressive                    Maximum performance with higher risk

OPTIMIZATIONS APPLIED:
    - Shell configuration optimizations
    - Nix configuration tuning
    - macOS system optimizations
    - Development tool optimizations
    - Claude configuration optimizations
    - Memory and cache optimizations

EXAMPLES:
    $0 --dry-run                  Preview all optimizations
    $0 --profile aggressive       Apply aggressive optimizations
    $0 --no-backup --verbose      Apply without backup, show details

SAFETY:
    - Always creates backup by default (use --no-backup to skip)
    - Dry-run mode available for safe testing
    - Automatic verification after optimization
    - Rollback instructions provided in case of issues
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --no-backup)
            CREATE_BACKUP=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --skip-verification)
            SKIP_VERIFICATION=true
            shift
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

# Validate profile
case "$PROFILE" in
    conservative|balanced|aggressive)
        log_info "Using $PROFILE optimization profile"
        ;;
    *)
        log_error "Invalid profile: $PROFILE. Valid options: conservative, balanced, aggressive"
        exit 1
        ;;
esac

# Function to execute command with dry-run support
execute_command() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would execute: $cmd"
        log_warning "[DRY-RUN] Description: $description"
    else
        log_verbose "Executing: $cmd"
        log_info "$description"
        if eval "$cmd"; then
            log_success "✓ $description completed"
        else
            log_error "✗ $description failed"
            return 1
        fi
    fi
}

# Function to create backup
create_optimization_backup() {
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        local backup_dir="optimization-backup-$(date +%Y%m%d_%H%M%S)"

        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would create backup directory: $backup_dir"
        else
            log_info "Creating optimization backup..."
            mkdir -p "$backup_dir"

            # Backup important configuration files
            [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/zshrc.bak"
            [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$backup_dir/bashrc.bak"
            [[ -f "$HOME/.claude.json" ]] && cp "$HOME/.claude.json" "$backup_dir/claude.json.bak"
            [[ -f "/etc/nix/nix.conf" ]] && cp "/etc/nix/nix.conf" "$backup_dir/nix.conf.bak" 2>/dev/null || true

            # Backup current configuration
            cp -r dotfiles "$backup_dir/dotfiles.bak" 2>/dev/null || true

            log_success "✓ Backup created: $backup_dir"
            echo "$backup_dir" > .last_optimization_backup
        fi
    fi
}

# Profile-specific optimization settings
set_optimization_parameters() {
    case "$PROFILE" in
        conservative)
            # Conservative settings - safe optimizations only
            NIX_MAX_JOBS=2
            NIX_CORES=2
            SHELL_CACHE_ENABLED=true
            AGGRESSIVE_GC=false
            SYSTEM_TWEAKS=false
            ;;
        balanced)
            # Balanced settings - good performance with safety
            NIX_MAX_JOBS=4
            NIX_CORES=4
            SHELL_CACHE_ENABLED=true
            AGGRESSIVE_GC=true
            SYSTEM_TWEAKS=true
            ;;
        aggressive)
            # Aggressive settings - maximum performance
            NIX_MAX_JOBS=8
            NIX_CORES=8
            SHELL_CACHE_ENABLED=true
            AGGRESSIVE_GC=true
            SYSTEM_TWEAKS=true
            ;;
    esac

    log_verbose "Optimization parameters set for $PROFILE profile"
}

# Shell optimization function
optimize_shell() {
    log_info "Optimizing shell configuration..."

    # Optimize Zsh if it's the current shell
    if [[ "$SHELL" == *"zsh"* && -f "$HOME/.zshrc" ]]; then

        # Add performance monitoring if not present
        if ! grep -q "zmodload zsh/zprof" "$HOME/.zshrc" 2>/dev/null; then
            execute_command "echo '# Performance profiling (added by optimizer)' >> $HOME/.zshrc" "Adding Zsh profiling"
            execute_command "echo 'zmodload zsh/zprof' >> $HOME/.zshrc" "Enabling Zsh profiling"
        fi

        # Optimize completion system
        if ! grep -q "autoload -Uz compinit" "$HOME/.zshrc" 2>/dev/null; then
            execute_command "echo '# Optimized completion system' >> $HOME/.zshrc" "Adding completion optimization"
            execute_command "echo 'autoload -Uz compinit && compinit -C' >> $HOME/.zshrc" "Enabling fast completion"
        fi

        # Add caching for expensive operations
        if [[ "$SHELL_CACHE_ENABLED" == "true" ]]; then
            execute_command "echo '# Command caching' >> $HOME/.zshrc" "Adding command caching"
            execute_command "echo 'setopt HIST_VERIFY' >> $HOME/.zshrc" "Enabling history verification"
        fi
    fi

    log_success "✓ Shell optimization completed"
}

# Nix optimization function
optimize_nix() {
    log_info "Optimizing Nix configuration..."

    local nix_conf="/etc/nix/nix.conf"
    local temp_conf="/tmp/nix.conf.optimized"

    # Check if we can modify nix.conf
    if [[ ! -w "$nix_conf" && ! -w "$(dirname "$nix_conf")" ]]; then
        log_warning "Cannot write to $nix_conf - skipping Nix optimizations"
        return 0
    fi

    # Create optimized Nix configuration
    cat > "$temp_conf" << EOF
# Optimized Nix configuration (generated by optimizer)
max-jobs = $NIX_MAX_JOBS
cores = $NIX_CORES
auto-optimise-store = true
experimental-features = nix-command flakes
substituters = https://cache.nixos.org/ https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
EOF

    if [[ "$AGGRESSIVE_GC" == "true" ]]; then
        echo "min-free = 1073741824" >> "$temp_conf"  # 1GB minimum free space
        echo "max-free = 5368709120" >> "$temp_conf"   # 5GB maximum free space
    fi

    execute_command "sudo cp $temp_conf $nix_conf" "Updating Nix configuration"
    execute_command "rm -f $temp_conf" "Cleaning up temporary files"

    # Restart Nix daemon if not in dry-run mode
    if [[ "$DRY_RUN" != "true" ]]; then
        execute_command "sudo launchctl kickstart -k system/org.nixos.nix-daemon" "Restarting Nix daemon"
    fi

    log_success "✓ Nix optimization completed"
}

# Claude configuration optimization
optimize_claude() {
    log_info "Optimizing Claude configuration..."

    # Use the optimized claude-conf script
    local claude_script="./claude-conf-optimized.sh"

    if [[ -f "$claude_script" ]]; then
        case "$PROFILE" in
            conservative)
                execute_command "$claude_script --profile prod" "Applying conservative Claude settings"
                ;;
            balanced)
                execute_command "$claude_script --profile personal" "Applying balanced Claude settings"
                ;;
            aggressive)
                execute_command "$claude_script --profile dev" "Applying aggressive Claude settings"
                ;;
        esac
    else
        log_warning "Claude optimization script not found: $claude_script"
    fi

    log_success "✓ Claude optimization completed"
}

# macOS system optimizations
optimize_macos() {
    if [[ "$SYSTEM_TWEAKS" != "true" ]]; then
        log_verbose "System tweaks disabled for $PROFILE profile"
        return 0
    fi

    log_info "Applying macOS system optimizations..."

    # Disable visual effects for performance
    execute_command "defaults write com.apple.dock expose-animation-duration -float 0.1" "Reducing dock animation duration"
    execute_command "defaults write NSGlobalDomain NSWindowResizeTime -float 0.001" "Reducing window resize time"

    # Optimize Finder
    execute_command "defaults write com.apple.finder DisableAllAnimations -bool true" "Disabling Finder animations"
    execute_command "defaults write com.apple.finder ShowPathbar -bool true" "Enabling Finder path bar"

    # Memory management
    execute_command "sudo purge" "Purging inactive memory"

    # Restart affected services
    execute_command "killall Dock" "Restarting Dock"
    execute_command "killall Finder" "Restarting Finder"

    log_success "✓ macOS optimization completed"
}

# Development tools optimization
optimize_dev_tools() {
    log_info "Optimizing development tools..."

    # Go optimizations
    if command -v go >/dev/null 2>&1; then
        execute_command "go env -w GOPROXY=https://proxy.golang.org,direct" "Setting Go proxy"
        execute_command "go env -w GOSUMDB=sum.golang.org" "Setting Go checksum database"

        if [[ "$AGGRESSIVE_GC" == "true" ]]; then
            execute_command "go clean -modcache" "Cleaning Go module cache"
        fi
    fi

    # Node.js/Bun optimizations
    if command -v bun >/dev/null 2>&1; then
        if [[ "$AGGRESSIVE_GC" == "true" ]]; then
            execute_command "bun cache rm" "Clearing Bun cache"
        fi
    fi

    # Homebrew optimizations
    if command -v brew >/dev/null 2>&1; then
        execute_command "brew cleanup" "Cleaning Homebrew cache"
        execute_command "brew doctor || true" "Running Homebrew diagnostics"
    fi

    log_success "✓ Development tools optimization completed"
}

# Memory and cache optimization
optimize_memory() {
    log_info "Optimizing memory and cache usage..."

    # Clear system caches
    if [[ "$AGGRESSIVE_GC" == "true" ]]; then
        execute_command "sudo dscacheutil -flushcache" "Flushing DNS cache"
        execute_command "sudo killall -HUP mDNSResponder" "Restarting mDNS responder"
    fi

    # Nix garbage collection
    if command -v nix-collect-garbage >/dev/null 2>&1; then
        if [[ "$AGGRESSIVE_GC" == "true" ]]; then
            execute_command "nix-collect-garbage -d" "Running Nix garbage collection"
        else
            execute_command "nix-collect-garbage" "Running gentle Nix garbage collection"
        fi
    fi

    log_success "✓ Memory optimization completed"
}

# Verification function
verify_optimizations() {
    if [[ "$SKIP_VERIFICATION" == "true" ]]; then
        log_info "Skipping verification as requested"
        return 0
    fi

    log_info "Verifying optimizations..."
    local verification_failed=false

    # Check Nix configuration
    if command -v nix >/dev/null 2>&1; then
        if ! nix show-config >/dev/null 2>&1; then
            log_error "✗ Nix configuration verification failed"
            verification_failed=true
        else
            log_success "✓ Nix configuration verified"
        fi
    fi

    # Check Claude configuration
    if command -v claude >/dev/null 2>&1; then
        if ! claude config ls >/dev/null 2>&1; then
            log_error "✗ Claude configuration verification failed"
            verification_failed=true
        else
            log_success "✓ Claude configuration verified"
        fi
    fi

    # Check shell configuration
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! zsh -n "$HOME/.zshrc" 2>/dev/null; then
            log_error "✗ Zsh configuration syntax check failed"
            verification_failed=true
        else
            log_success "✓ Zsh configuration verified"
        fi
    fi

    if [[ "$verification_failed" == "true" ]]; then
        log_error "Some verifications failed. Check the issues above."
        return 1
    else
        log_success "✓ All optimizations verified successfully"
    fi
}

# Rollback function
show_rollback_instructions() {
    if [[ -f ".last_optimization_backup" ]]; then
        local backup_dir=$(cat .last_optimization_backup)
        cat << EOF

${YELLOW}ROLLBACK INSTRUCTIONS:${NC}
If you experience issues after optimization, you can rollback using:

1. Restore configuration files:
   cp "$backup_dir/zshrc.bak" ~/.zshrc       # (if exists)
   cp "$backup_dir/bashrc.bak" ~/.bashrc     # (if exists)
   cp "$backup_dir/claude.json.bak" ~/.claude.json  # (if exists)

2. Restart your terminal or run:
   source ~/.zshrc  # or ~/.bashrc

3. Restart affected services:
   sudo launchctl kickstart -k system/org.nixos.nix-daemon

4. For Nix configuration rollback (requires sudo):
   sudo cp "$backup_dir/nix.conf.bak" /etc/nix/nix.conf  # (if exists)

Backup location: $backup_dir
EOF
    fi
}

# Main optimization function
main() {
    log_info "Starting performance optimization..."
    log_info "Profile: $PROFILE"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be applied"
    fi

    # Set optimization parameters based on profile
    set_optimization_parameters

    # Create backup if requested
    create_optimization_backup

    # Apply optimizations
    optimize_shell
    optimize_nix
    optimize_claude
    optimize_macos
    optimize_dev_tools
    optimize_memory

    # Verify optimizations
    if [[ "$DRY_RUN" != "true" ]]; then
        verify_optimizations
    fi

    echo
    log_success "Optimization completed successfully!"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Run without --dry-run to apply optimizations"
    else
        log_info "You may need to restart your terminal to see all changes"
        show_rollback_instructions
    fi

    log_info "Consider running the benchmark script to measure improvements:"
    log_info "  ./shell-performance-benchmark.sh"
}

# Run main function
main "$@"