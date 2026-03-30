# SystemNix Justfile
# Task runner for cross-platform Nix configuration management

# Shared function to detect package manager from lockfile
_detect_pkg_manager:
    @if [ -f "bun.lockb" ]; then \
        echo "bun"; \
    elif [ -f "pnpm-lock.yaml" ]; then \
        echo "pnpm"; \
    elif [ -f "package-lock.json" ]; then \
        echo "npm"; \
    elif [ -f "yarn.lock" ]; then \
        echo "yarn"; \
    else \
        echo "none"; \
    fi

# Detect current platform (Darwin or Linux)
_detect_platform:
    @if [ "$(uname -s)" = "Darwin" ]; then \
        echo "darwin"; \
    elif [ "$(uname -s)" = "Linux" ]; then \
        echo "linux"; \
    else \
        echo "unknown"; \
    fi

# Get Nix host name based on platform
_get_nix_host:
    @if [ "$(just _detect_platform)" = "darwin" ]; then \
        echo "Lars-MacBook-Air"; \
    else \
        echo "evo-x2"; \
    fi

# Default recipe to display help
default:
    @just --list

# Initial system setup - run this after cloning the repository
setup:
    @PLATFORM=$(just _detect_platform); \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🚀 Setting up macOS configuration..."; \
        PLATFORM_NAME="macOS"; \
    elif [ "$PLATFORM" = "linux" ]; then \
        echo "🚀 Setting up NixOS configuration..."; \
        PLATFORM_NAME="NixOS"; \
    else \
        echo "🚀 Setting up configuration..."; \
        PLATFORM_NAME="Unknown"; \
    fi; \
    just ssh-setup; \
    echo "ℹ️  Dotfiles are now managed by Home Manager (manual linking deprecated)"; \
    just switch; \
    just pre-commit-install; \
    echo "✅ Setup complete! Your $PLATFORM_NAME configuration is ready."

# Create SSH directories (manual work mentioned in README)
ssh-setup:
    @echo "📁 Creating SSH directories..."
    mkdir -p ~/.ssh/sockets
    @echo "✅ SSH directories created"

# Apply Nix configuration changes (equivalent to nixup alias)
switch:
    @PLATFORM=$(just _detect_platform); \
    HOST=$(just _get_nix_host); \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🔄 Applying macOS configuration..."; \
        sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ./ --print-build-logs; \
    elif [ "$PLATFORM" = "linux" ]; then \
        echo "🔄 Applying NixOS configuration for $HOST..."; \
        sudo nixos-rebuild switch --flake ./#"$HOST" --print-build-logs; \
    else \
        echo "❌ Unknown platform: $PLATFORM"; \
        exit 1; \
    fi; \
    echo "✅ Nix configuration applied"

# Update Nix itself using nix upgrade-nix (works without switch)
update-nix:
    echo "🔄 Updating Nix package manager..."
    nix upgrade-nix
    echo "✅ Nix updated to $(nix --version | cut -d' ' -f3)"
    echo "⚠️  Run 'just switch' to rebuild system with new Nix version"

# Update system and packages
update:
    @echo "📦 Updating system packages..."
    @echo "Updating Nix flake..."
    nix flake update
    @echo "✅ System updated"
    @echo ""
    @echo "💡 Next steps:"
    @echo "   - Run 'just switch' to apply changes"

# ActivityWatch manual control commands
activitywatch-start:
    @echo "🚀 Starting ActivityWatch..."
    @osascript -e 'tell application "ActivityWatch" to launch'
    @sleep 3
    @pgrep -f ActivityWatch > /dev/null && echo "✅ ActivityWatch started" || echo "❌ Failed to start"

activitywatch-stop:
    @echo "🛑 Stopping ActivityWatch..."
    @pkill -f ActivityWatch || echo "  (ActivityWatch not running)"
    @sleep 2
    @pgrep -f ActivityWatch > /dev/null && echo "❌ ActivityWatch still running" || echo "✅ ActivityWatch stopped"

# Fix ActivityWatch permissions (macOS Accessibility)
activitywatch-fix-permissions:
    @echo "🔧 Fixing ActivityWatch permissions..."
    @echo ""
    @echo "This will reset and re-grant Accessibility permissions for URL tracking."
    @echo ""
    @bash dotfiles/activitywatch/fix-permissions.sh

# Install aw-watcher-utilization on macOS (manual install for Homebrew ActivityWatch)
activitywatch-install-utilization:
    @echo "📊 Installing aw-watcher-utilization..."
    @echo ""
    @echo "This installs the utilization watcher for ActivityWatch."
    @echo "Monitors: CPU, RAM, disk, network, and hardware sensors"
    @echo ""
    @bash dotfiles/activitywatch/install-utilization.sh

# Clean up caches and old packages (comprehensive cleanup)
clean:
    @PLATFORM=$(just _detect_platform); \
    echo "🧹 Starting comprehensive system cleanup..."; \
    echo ""; \
    echo "=== Quick Cache Cleanup ==="; \
    echo "💡 Tip: Run 'just clean-storage' for safe cache-only cleanup (no sudo)"; \
    ./scripts/storage-cleanup.sh; \
    echo ""; \
    echo "=== Nix Store Cleanup ==="; \
    echo "📊 Current store size:"; \
    du -sh /nix/store || echo "Could not measure store size"; \
    echo "🗑️  Cleaning Nix generations older than 1 day..."; \
    echo "  Note: Use 'sudo -S' if password prompt appears"; \
    nix-collect-garbage -d --delete-older-than 1d || sudo -S nix-collect-garbage -d --delete-older-than 1d; \
    echo "⚡ Optimizing Nix store (deduplicating files)..."; \
    echo "  This may take several minutes for large stores..."; \
    nix-store --optimize || sudo -S nix-store --optimize; \
    echo "🧹 Cleaning user Nix profiles..."; \
    if [ "$PLATFORM" = "darwin" ]; then \
        nix profile wipe-history --profile /Users/$(whoami)/.local/state/nix/profiles/profile || true; \
    else \
        nix profile wipe-history --profile ~/.local/state/nix/profiles/profile || true; \
    fi; \
    echo ""; \
    echo "=== Package Manager Cleanup ==="; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🍺 Cleaning Homebrew..."; \
        brew autoremove || echo "  ⚠️  Homebrew autoremove failed or not needed"; \
        brew cleanup --prune=all -s || echo "  ⚠️  Homebrew cleanup failed"; \
    fi; \
    echo "📦 Cleaning npm/pnpm caches..."; \
    npm cache clean --force || echo "  ⚠️  npm cache clean failed (npm not installed?)"; \
    pnpm store prune || echo "  ⚠️  pnpm store prune failed (pnpm not installed?)"; \
    echo "🐹 Cleaning Go caches..."; \
    go clean -cache -testcache -modcache || echo "  ⚠️  Go cache clean failed (Go not installed?)"; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🗑️  Cleaning Go build cache folders..."; \
        find /private/var/folders/07/y9f_lh8s1zq2kr67_k94w22h0000gn/T -name "go-build*" -type d -print0 2>/dev/null | xargs -0 trash 2>/dev/null || echo "  ⚠️  Go build cache folders not found or couldn't be removed"; \
    fi; \
    echo "🦀 Cleaning Rust/Cargo cache..."; \
    cargo cache --autoclean || echo "  ⚠️  Cargo cache clean failed (cargo-cache not installed?)"; \
    echo "🔧 Cleaning build caches..."; \
    rm -rf ~/.bun/install/cache || echo "  ⚠️  Bun cache not found"; \
    rm -rf ~/.gradle/caches/* || echo "  ⚠️  Gradle cache not found"; \
    rm -rf ~/.cache/puppeteer || echo "  ⚠️  Puppeteer cache not found"; \
    rm -rf ~/.nuget/packages || echo "  ⚠️  NuGet cache not found"; \
    echo ""; \
    echo "=== System Cache Cleanup ==="; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🔦 Cleaning Spotlight metadata..."; \
        [ -d ~/Library/Metadata/CoreSpotlight/SpotlightKnowledgeEvents ] && rm -r ~/Library/Metadata/CoreSpotlight/SpotlightKnowledgeEvents || echo "  ⚠️  Spotlight metadata not found"; \
    fi; \
    echo "🗂️  Cleaning system temp files..."; \
    rm -rf /tmp/nix-build-* || echo "  ⚠️  No nix-build temp files found"; \
    rm -rf /tmp/nix-shell-* || echo "  ⚠️  No nix-shell temp files found"; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "📱 Cleaning iOS simulators (if Xcode installed)..."; \
        xcrun simctl delete unavailable 2>/dev/null || echo "  ⚠️  Xcode/simulators not found or no unavailable simulators"; \
    fi; \
    echo "🐳 Cleaning Docker (if installed)..."; \
    docker system prune -af 2>/dev/null || echo "  ⚠️  Docker not installed or no containers to clean"; \
    echo ""; \
    echo "=== Final Results ==="; \
    echo "📊 New store size:"; \
    du -sh /nix/store || echo "Could not measure store size"; \
    echo "💽 Free disk space:"; \
    df -h / | tail -1 | awk '{print "  Available: " $4 " of " $2 " (" $5 " used)"}'; \
    echo ""; \
    echo "✅ Comprehensive cleanup complete!"; \
    echo "💡 Tip: Run 'just clean-aggressive' for nuclear cleanup options"

# Quick daily cleanup (fast, safe, no store optimization)
clean-quick:
    @PLATFORM=$(just _detect_platform); \
    echo "🚀 Quick daily cleanup..."; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🍺 Cleaning Homebrew..."; \
        brew autoremove && brew cleanup || echo "  ⚠️  Homebrew cleanup failed"; \
    fi; \
    echo "📦 Cleaning package managers..."; \
    npm cache clean --force || echo "  ⚠️  npm not available"; \
    pnpm store prune || echo "  ⚠️  pnpm not available"; \
    go clean -cache || echo "  ⚠️  Go not available"; \
    echo "🗂️  Cleaning temp files..."; \
    rm -rf /tmp/nix-build-* /tmp/nix-shell-* || echo "  ⚠️  No temp files found"; \
    echo "🐳 Cleaning Docker (light)..."; \
    docker system prune -f 2>/dev/null || echo "  ⚠️  Docker not available"; \
    echo "✅ Quick cleanup done! (No Nix store changes)"

# Aggressive cleanup - removes more data but might need reinstalls
clean-aggressive:
    @PLATFORM=$(just _detect_platform); \
    echo "⚠️  AGGRESSIVE CLEANUP MODE - This will remove more data!"; \
    echo "📋 This will clean:"; \
    echo "  - All Nix generations (not just 1+ days old)"; \
    echo "  - All user Nix profiles"; \
    echo "  - All language version managers"; \
    echo "  - All development caches"; \
    echo "  - Docker images and containers"; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "  - iOS simulators and Xcode derived data"; \
    fi; \
    echo ""; \
    echo "🚨 Some tools may need reinstalling after this!"; \
    echo "Continue? (Ctrl+C to abort, Enter to proceed)"; \
    read; \
    echo ""; \
    echo "🧹 Starting aggressive cleanup..."; \
    echo ""; \
    echo "=== Nix Nuclear Option ==="; \
    nix-collect-garbage -d || sudo -S nix-collect-garbage -d; \
    nix profile wipe-history || true; \
    nix-store --optimize || sudo -S nix-store --optimize; \
    echo ""; \
    echo "=== Language Managers ==="; \
    echo "🟢 Cleaning Node.js versions..."; \
    rm -rf ~/.nvm/versions/node/* || true; \
    echo "🐍 Cleaning Python versions..."; \
    rm -rf ~/.pyenv/versions/* || true; \
    echo "💎 Cleaning Ruby versions..."; \
    rm -rf ~/.rbenv/versions/* || true; \
    echo ""; \
    echo "=== Development Caches ==="; \
    echo "🏗️  Cleaning all build caches..."; \
    rm -rf ~/.cache || true && mkdir -p ~/.cache; \
    if [ "$PLATFORM" = "darwin" ]; then \
        rm -rf ~/Library/Caches/CocoaPods || true; \
        rm -rf ~/Library/Caches/Homebrew || true; \
        rm -rf ~/Library/Developer/Xcode/DerivedData || true; \
    fi; \
    echo "🐳 Removing all Docker data..."; \
    docker system prune -af --volumes 2>/dev/null || true; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "📱 Removing all iOS simulators..."; \
        xcrun simctl delete all 2>/dev/null || true; \
    fi; \
    echo ""; \
    echo "=== Final Optimization ==="; \
    echo "📊 Final store size:"; \
    du -sh /nix/store || echo "Could not measure"; \
    echo "💾 Disk space recovered:"; \
    df -h / | tail -1 | awk '{print "  " $4 " available of " $2}'; \
    echo ""; \
    echo "✅ Aggressive cleanup complete!"; \
    echo "⚡ You may need to reinstall some development tools"

# KeyChain management commands
keychain-list:
    @echo "🔑 Listing KeyChain items..."
    @echo ""
    @echo "=== Available KeyChains ==="
    @security list-keychains | sed 's/^/  /'
    @echo ""
    @echo "=== Keys (SSH, Signing, Encryption) ==="
    @security find-key -v ~/Library/Keychains/login.keychain-db 2>/dev/null | grep -A 5 "class: \"keys\"" | head -30 || echo "  No keys found"
    @echo ""
    @echo "=== Certificates ==="
    @security find-certificate -v ~/Library/Keychains/login.keychain-db 2>/dev/null | grep -A 2 "SHA-1 hash" | head -20 || echo "  No certificates found"
    @echo ""
    @echo "=== Identities (Certificate + Private Key) ==="
    @security find-identity -v ~/Library/Keychains/login.keychain-db 2>/dev/null | grep "identity:" | head -20 || echo "  No identities found"

keychain-status:
    @echo "🔐 KeyChain Status"
    @echo "==============="
    @echo ""
    @echo "=== KeyChain Info ==="
    @security show-keychain-info ~/Library/Keychains/login.keychain-db 2>&1 || echo "  Keychain info not available"
    @echo ""
    @echo "=== Available KeyChains ==="
    @security list-keychains | sed 's/^/  /'
    @echo ""
    @echo "=== Touch ID Status ==="
    @if [ -f /etc/pam.d/sudo_local ]; then \
        if grep -q "pam_tid.so" /etc/pam.d/sudo_local; then \
            echo "  ✓ Touch ID enabled for sudo"; \
        else \
            echo "  ✗ Touch ID not enabled for sudo"; \
        fi; \
    else \
        echo "  ✗ sudo_local file not found"; \
    fi

keychain-add account service password:
    @echo "🔑 Adding password to KeyChain..."
    @security add-generic-password -a {{account}} -s {{service}} -w {{password}} -U && \
        echo "✅ Password added to KeyChain" || \
        echo "❌ Failed to add password"
    @echo ""
    @echo "💡 To enable Touch ID for this item:"
    @echo "   1. Open Keychain Access app"
    @echo "   2. Find the item for service: {{service}}"
    @echo "   3. Right-click → Get Info"
    @echo "   4. Access Control tab → Check 'Touch ID'"

# List all keys (SSH, signing, encryption)
keychain-keys:
    @echo "🔑 Listing All Keys..."
    @echo ""
    @echo "=== Private Keys (Signing, Encryption, SSH) ==="
    @security find-key -v ~/Library/Keychains/login.keychain-db 2>/dev/null || echo "  No private keys found"
    @echo ""
    @echo "=== SSH Keys ==="
    @ssh-add -l 2>/dev/null || echo "  No SSH keys loaded in agent"
    @echo ""
    @echo "=== System Keys ==="
    @security find-key -v /Library/Keychains/System.keychain 2>/dev/null | grep -A 5 "class: \"keys\"" | head -20 || echo "  No system keys found"

# List all certificates
keychain-certs:
    @echo "📜 Listing Certificates..."
    @echo ""
    @echo "=== User Certificates ==="
    @security find-certificate -v ~/Library/Keychains/login.keychain-db 2>/dev/null | grep -E "(SHA-1 hash|label:|class: \"cert\")" | head -40 || echo "  No certificates found"
    @echo ""
    @echo "=== System Certificates ==="
    @security find-certificate -v /Library/Keychains/System.keychain 2>/dev/null | grep -E "(SHA-1 hash|label:)" | head -20 || echo "  No system certificates"

# List all identities (certificate + private key pairs)
keychain-identities:
    @echo "🎫 Listing Identities (Certificate + Private Key) ==="
    @echo ""
    @echo "=== User Identities ==="
    @security find-identity -v ~/Library/Keychains/login.keychain-db 2>/dev/null || echo "  No identities found"
    @echo ""
    @echo "=== System Identities ==="
    @security find-identity -v /Library/Keychains/System.keychain 2>/dev/null | head -20 || echo "  No system identities"

# Add SSH key to KeyChain with Touch ID prompt
keychain-ssh-add:
    @echo "🔐 Adding SSH Key to KeyChain..."
    @echo ""
    @echo "Usage: just keychain-ssh-add [key-path]"
    @echo ""
    @echo "Examples:"
    @echo "  just keychain-ssh-add ~/.ssh/id_ed25519"
    @echo "  just keychain-ssh-add ~/.ssh/id_rsa"
    @echo ""
    @echo "This will:"
    @echo "  1. Prompt for key passphrase (if encrypted)"
    @echo "  2. Add key to SSH agent with KeyChain storage"
    @echo "  3. Prompt for Touch ID on first use"
    @echo ""
    @echo "To add all SSH keys from ~/.ssh/:"
    @for key in ~/.ssh/id_*; do \
        if [ -f "$$key" ] && ! echo "$$key" | grep -q ".pub$$"; then \
            echo "Adding $$key..."; \
            ssh-add -K "$$key" 2>/dev/null || echo "  Failed to add $$key"; \
        fi; \
    done

# Configure keychain partition for SSH key
keychain-ssh-partition keypath:
    @echo "🔐 Configuring SSH Key for Touch ID..."
    @echo ""
    @echo "Setting partition list for SSH key: {{keypath}}"
    @security set-key-partition-list -S apple-tool:,ssh: -k "" -T /usr/bin/ssh-agent -T /usr/bin/ssh {{keypath}} 2>&1 && \
        echo "✅ SSH key configured for Touch ID" || \
        echo "❌ Failed to configure SSH key"
    @echo ""
    @echo "Note: This configures the key to work with ssh-agent"

keychain-biometric service:
    @echo "🔐 Enabling Touch ID for existing KeyChain item: {{service}}"
    @echo ""
    @echo "⚠️  This requires updating the access control of the item"
    @echo "⚠️  You'll need to use the Keychain Access app for this operation"
    @echo ""
    @echo "Steps:"
    @echo "1. Open Keychain Access app"
    @echo "2. Find the item for service: {{service}}"
    @echo "3. Right-click → Get Info"
    @echo "4. Access Control tab → Add Touch ID requirement"

keychain-lock:
    @echo "🔒 Locking all KeyChains..."
    @security lock-keychain ~/Library/Keychains/login.keychain-db && \
        echo "✅ KeyChains locked" || \
        echo "❌ Failed to lock KeyChains"

keychain-unlock:
    @echo "🔓 Unlocking KeyChain..."
    @security unlock-keychain ~/Library/Keychains/login.keychain-db && \
        echo "✅ KeyChain unlocked" || \
        echo "❌ Failed to unlock KeyChain (requires password)"

keychain-settings:
    @echo "⚙️  Configuring KeyChain security settings..."
    @echo "Setting: Lock after 5 minutes of inactivity"
    @security set-keychain-settings -l -u -t 300 login.keychain-db 2>/dev/null && \
        echo "✅ KeyChain settings updated" || \
        echo "❌ Failed to update KeyChain settings"

keychain-help:
    @echo "🔑 KeyChain Management Commands"
    @echo "================================"
    @echo ""
    @echo "Available commands:"
    @echo "  just keychain-list        - List all KeyChain items (keys, certificates, identities)"
    @echo "  just keychain-status       - Show KeyChain status and Touch ID info"
    @echo "  just keychain-add account service password"
    @echo "                           - Add password/application data"
    @echo "  just keychain-keys        - List all keys (SSH, signing, encryption)"
    @echo "  just keychain-certs       - List all certificates"
    @echo "  just keychain-identities  - List all identities (cert + private key)"
    @echo "  just keychain-ssh-add     - Add SSH key to KeyChain with Touch ID"
    @echo "  just keychain-biometric service"
    @echo "                           - Instructions for enabling Touch ID (manual)"
    @echo "  just keychain-lock         - Lock all KeyChains"
    @echo "  just keychain-unlock       - Unlock KeyChain (requires password)"
    @echo "  just keychain-settings     - Configure KeyChain security settings"
    @echo ""
    @echo "Key Types:"
    @echo "  • SSH keys - For Git, remote servers"
    @echo "  • Signing keys - Code signing, document signing"
    @echo "  • Encryption keys - PGP, file encryption"
    @echo "  • Application keys - API tokens, service credentials"
    @echo "  • Identities - Certificate + private key pairs"
    @echo ""
    @echo "Note: Touch ID for KeyChain items must be configured per-item"
    @echo "      Use Keychain Access app for existing items"
    @echo "      Use 'just keychain-ssh-add' for SSH keys"

# Check system status and outdated packages
check:
    @PLATFORM=$(just _detect_platform); \
    echo "🔍 Checking system status..."; \
    echo "=== Nix System Info ==="; \
    nix --version; \
    if [ "$$PLATFORM" = "darwin" ]; then \
        darwin-version; \
        echo "\n=== Homebrew Status ==="; \
        brew doctor || true; \
        echo "\n=== Outdated Homebrew Packages ==="; \
        brew outdated || echo "All Homebrew packages are up to date"; \
    else \
        echo "\n=== NixOS Version ==="; \
        nixos-version; \
    fi; \
    echo "\n=== Git Status ==="; \
    git status --porcelain || true; \
    echo "✅ System check complete"

# Validate Nix configuration syntax
validate:
    @echo "🔍 Validating Nix configuration..."
    nix --extra-experimental-features "nix-command flakes" flake check --no-build
    @echo "✅ Nix configuration validated"

# Quick Nix syntax check (called by pre-commit hook)
check-nix-syntax:
    @echo "🔍 Checking Nix syntax..."
    nix --extra-experimental-features "nix-command flakes" flake check --no-build
    @echo "✅ Nix syntax valid"

# Check for unresolved merge conflict markers in all tracked files
conflict-check:
    @echo "🔍 Checking for merge conflicts..."
    @if grep -rnE '^<{7} |^={7}$$|^>{7} ' --include='*.nix' --include='*.lock' --include='*.json' --include='*.yaml' --include='*.yml' --include='*.toml' . 2>/dev/null; then \
        echo "❌ Found merge conflict markers above - resolve before committing"; \
        exit 1; \
    else \
        echo "✅ No merge conflict markers found"; \
    fi

# Format code using treefmt
format:
    @echo "🎨 Formatting code..."
    treefmt
    @echo "✅ Code formatted"

# Install pre-commit hooks
pre-commit-install:
    @echo "🔒 Installing pre-commit hooks..."
    pre-commit install
    @echo "✅ Pre-commit hooks installed"

# Run pre-commit hooks on all files
pre-commit-run:
    @echo "🔒 Running pre-commit hooks..."
    pre-commit run --all-files
    @echo "✅ Pre-commit hooks completed"

# Create backup of current configuration
backup:
    @echo "💾 Creating configuration backup..."
    #!/usr/bin/env bash
    BACKUP_DIR="backups/$(date '+%Y-%m-%d_%H-%M-%S')"
    mkdir -p "$BACKUP_DIR"

    # Backup entire directories platform structure
    cp -r platforms "$BACKUP_DIR/"
    cp -r dotfiles "$BACKUP_DIR/"  # Keep dotfiles for historical reference

    # Backup justfile (manual-linking.sh removed - now managed by Home Manager)
    cp justfile "$BACKUP_DIR/" || true

    # Backup current shell state
    mkdir -p "$BACKUP_DIR/shell_state"
    cp ~/.zcompdump* "$BACKUP_DIR/shell_state/" 2>/dev/null || true

    # Create comprehensive backup info
    echo "Backup created: $(date)" > "$BACKUP_DIR/backup_info.txt"
    echo "Git commit: $(git rev-parse HEAD)" >> "$BACKUP_DIR/backup_info.txt"
    echo "Git branch: $(git branch --show-current)" >> "$BACKUP_DIR/backup_info.txt"
    echo "System: $(uname -a)" >> "$BACKUP_DIR/backup_info.txt"
    echo "Zsh version: $(zsh --version)" >> "$BACKUP_DIR/backup_info.txt"
    echo "Shell startup time: $(time zsh -i -c exit 2>&1 | grep real)" >> "$BACKUP_DIR/backup_info.txt"

    echo "✅ Backup created in $BACKUP_DIR"

# Auto-backup before making changes (internal use)
auto-backup:
    @echo "🔄 Creating automatic backup before changes..."
    #!/usr/bin/env bash
    BACKUP_DIR="backups/auto_$(date '+%Y-%m-%d_%H-%M-%S')"
    mkdir -p "$BACKUP_DIR"
    cp -r platforms "$BACKUP_DIR/"
    cp -r dotfiles "$BACKUP_DIR/"
    cp justfile "$BACKUP_DIR/" 2>/dev/null || true
    echo "$(date): Auto-backup before changes" > "$BACKUP_DIR/backup_info.txt"
    echo "Git commit: $(git rev-parse HEAD)" >> "$BACKUP_DIR/backup_info.txt"
    echo "✅ Auto-backup created in $BACKUP_DIR"

# List available backups
list-backups:
    @echo "📋 Available backups:"
    @ls -la backups/ 2>/dev/null | grep "^d" | awk '{print $9, $6, $7, $8}' | sort -r || echo "No backups found"

# Restore from a backup
restore BACKUP_NAME:
    @echo "🔄 Restoring from backup: {{ BACKUP_NAME }}"
    #!/usr/bin/env bash
    BACKUP_PATH="backups/{{ BACKUP_NAME }}"
    if [ ! -d "$BACKUP_PATH" ]; then
    echo "❌ Backup not found: $BACKUP_PATH"
    exit 1
    fi

    # Create safety backup first
    just auto-backup

    # Restore dotfiles
    if [ -d "$BACKUP_PATH/dotfiles" ]; then
    echo "Restoring dotfiles..."
    cp -r "$BACKUP_PATH/dotfiles"/* dotfiles/
    fi

    # Restore other files
    if [ -f "$BACKUP_PATH/justfile" ]; then
    echo "Restoring justfile..."
    cp "$BACKUP_PATH/justfile" .
    fi

    echo "✅ Restore complete. Run 'just switch' to apply changes."
    echo "💡 Original state backed up automatically before restore."
    echo "ℹ️  Note: Manual dotfile linking is deprecated; use Home Manager configs"

# Clean old backups (keep last 10)
clean-backups:
    @echo "🧹 Cleaning old backups (keeping last 10)..."
    #!/usr/bin/env bash
    cd backups 2>/dev/null || exit 0
    ls -1t | tail -n +11 | xargs rm -rf
    echo "✅ Old backups cleaned"

# Quick storage cleanup (no Nix GC, safe to run)
clean-storage:
    @echo "🧹 Quick storage cleanup (safe, no sudo required)..."
    @echo "  Note: This cleans caches, temp files, and build outputs"
    @echo "  For Nix GC, use 'just clean' (requires sudo)"
    ./scripts/storage-cleanup.sh
    @echo "✅ Storage cleanup complete!"
    @echo "💡 For comprehensive cleanup: just clean"
    @echo "💡 For Nix GC: sudo nix-collect-garbage -d --delete-older-than 3d && sudo nix-store --optimize"

# Rebuild zsh completion cache
rebuild-completions:
    @echo "🔄 Rebuilding zsh completion cache..."
    #!/usr/bin/env bash
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    mkdir -p "$CACHE_DIR"

    # Remove old completion cache
    rm -f "$CACHE_DIR"/zcompdump-*

    # Rebuild completions
    zsh -c "autoload -Uz compinit && compinit -d '$CACHE_DIR/zcompdump-$ZSH_VERSION'"

    echo "✅ Completion cache rebuilt"
    echo "💡 Next shell startup will use the fresh cache"

# Show system information
info:
    @echo "ℹ️  System Information"
    @echo "===================="
    @PLATFORM=$(just _detect_platform); \
    echo "Platform: $$PLATFORM"; \
    echo "Nix Version: $(nix --version)"; \
    echo "Git Version: $(git --version)"; \
    echo "Shell: $$SHELL"; \
    echo "Current Directory: $$(pwd)"; \
    if [ "$$PLATFORM" = "darwin" ]; then \
        echo "macOS Version: $$(sw_vers -productVersion)"; \
        echo "Darwin Rebuild: $$(darwin-version)"; \
        echo "Homebrew Version: $$(brew --version | head -1)"; \
    else \
        echo "NixOS Version: $$(nixos-version)"; \
    fi

# Test configuration without applying changes
test:
    @echo "🧪 Testing Nix configuration..."
    nix --extra-experimental-features "nix-command flakes" flake check --all-systems
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" = "darwin" ]; then \
        sudo /run/current-system/sw/bin/darwin-rebuild check --flake ./; \
    else \
        sudo nixos-rebuild test --flake .#evo-x2; \
    fi
    @echo "✅ Configuration test passed"

# Fast test - syntax validation only (skips heavy packages)
test-fast:
    @echo "🚀 Fast testing Nix configuration (syntax only)..."
    nix --extra-experimental-features "nix-command flakes" flake check --no-build
    @echo "✅ Fast configuration test passed"

# Deploy Home Manager configuration (same as switch, but named for clarity)
deploy:
    @echo "🚀 Deploying Home Manager configuration..."
    @echo "ℹ️  Note: This requires sudo access"
    @echo "ℹ️  Note: Open new terminal after deployment for shell changes to take effect"
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" = "darwin" ]; then \
        sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ./; \
    else \
        sudo nixos-rebuild switch --flake .#evo-x2; \
    fi
    @echo "✅ Home Manager deployment complete!"
    @echo ""
    @echo "🔄 Next steps:"
    @echo "  1. Open new terminal window (required for shell changes)"
    @echo "  2. Run: just verify"
    @echo "  3. Run: just test"

# Verify Home Manager installation and configuration
verify:
    @echo "🧪 Verifying Home Manager integration..."
    ./scripts/test-home-manager.sh

# Rollback to previous generation
rollback:
    @echo "↩️  Rolling back to previous generation..."
    @echo "ℹ️  Note: This requires sudo access"
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" = "darwin" ]; then \
        sudo /run/current-system/sw/bin/darwin-rebuild switch --rollback; \
    else \
        sudo nixos-rebuild switch --rollback; \
    fi
    @echo "✅ Rollback complete!"
    @echo ""
    @echo "ℹ️  Note: Open new terminal window for shell changes to take effect"

# List available generations
list-generations:
    @echo "📋 Listing available generations..."
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" = "darwin" ]; then \
        /run/current-system/sw/bin/darwin-rebuild --list-generations; \
    else \
        sudo nix-env --list-generations --profile /nix/var/nix/profiles/system; \
    fi

# Show git status and recent commits
status:
    @echo "📊 Repository Status"
    @echo "==================="
    @echo "Git Status:"
    git status --short
    @echo "\nRecent Commits:"
    git log --oneline -5
    @echo "\nBranch Info:"
    git branch -v

# Quick development workflow - format, check, and test
dev:
    @echo "🛠️  Development workflow..."
    @just format
    @just pre-commit-run
    @just test
    @echo "✅ Development checks complete"

# Create private environment file for secrets
env-private:
    @echo "🔒 Creating private environment file..."
    @echo "# Private environment variables - DO NOT COMMIT" > ~/.env.private
    @echo "# This file is sourced by .zshrc but not tracked in git" >> ~/.env.private
    @echo "" >> ~/.env.private
    @echo "# GitHub CLI integration" >> ~/.env.private
    @echo 'export GITHUB_TOKEN=$$(gh auth token 2>/dev/null || echo "")' >> ~/.env.private
    @echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="$$GITHUB_TOKEN"' >> ~/.env.private
    @echo "" >> ~/.env.private
    @echo "# Add other private environment variables here" >> ~/.env.private
    @echo "# export SOME_API_KEY=\"your-key-here\"" >> ~/.env.private
    @echo "✅ Private environment file created at ~/.env.private"

# Benchmark commands - unified interface
# Usage: just benchmark [all|shells|build|system|files|report|clean|legacy]
benchmark TYPE="all":
    @case "{{ TYPE }}" in \
        all) \
            echo "🚀 Running comprehensive system benchmarks..."; \
            ./scripts/benchmark-system.sh; \
            echo "✅ All benchmarks complete"; \
            ;; \
        shells) \
            echo "🐚 Benchmarking shell startup performance..."; \
            ./scripts/benchmark-system.sh --shells; \
            echo "✅ Shell benchmarks complete"; \
            ;; \
        build) \
            echo "🔨 Benchmarking build tools performance..."; \
            ./scripts/benchmark-system.sh --build-tools; \
            echo "✅ Build tool benchmarks complete"; \
            ;; \
        system) \
            echo "⚙️  Benchmarking system commands..."; \
            ./scripts/benchmark-system.sh --system; \
            echo "✅ System command benchmarks complete"; \
            ;; \
        files) \
            echo "📁 Benchmarking file operations..."; \
            ./scripts/benchmark-system.sh --file-ops; \
            echo "✅ File operation benchmarks complete"; \
            ;; \
        report) \
            echo "📊 Generating performance report..."; \
            ./scripts/benchmark-system.sh --report; \
            echo "✅ Report generated"; \
            ;; \
        clean) \
            echo "🧹 Cleaning old benchmark results..."; \
            ./scripts/benchmark-system.sh --cleanup; \
            echo "✅ Benchmark cleanup complete"; \
            ;; \
        legacy) \
            echo "🏃 Benchmarking shell startup performance (legacy)..."; \
            echo "Testing zsh startup time (10 runs):"; \
            hyperfine --warmup 3 --runs 10 'zsh -i -c exit'; \
            echo ""; \
            echo "Testing bash startup time for comparison:"; \
            hyperfine --warmup 3 --runs 10 'bash -i -c exit'; \
            echo "✅ Legacy benchmark complete"; \
            ;; \
        *) \
            echo "❌ Unknown benchmark type: {{ TYPE }}"; \
            echo "Usage: just benchmark [all|shells|build|system|files|report|clean|legacy]"; \
            exit 1; \
            ;; \
    esac

# Performance Monitoring commands - unified interface
# Usage: just perf [setup|benchmark|report|alerts|cache-clear] [args]
perf ACTION="benchmark" *ARGS="7":
    @case "{{ ACTION }}" in \
        setup) \
            echo "🔧 Setting up performance monitoring..."; \
            ./scripts/performance-monitor.sh setup-monitoring; \
            echo "✅ Performance monitoring setup complete"; \
            ;; \
        benchmark) \
            echo "📊 Running performance monitoring benchmark..."; \
            ./scripts/performance-monitor.sh benchmark-all; \
            echo "✅ Performance benchmark complete"; \
            ;; \
        report) \
            days="${1:-7}"; \
            echo "📈 Generating performance report ($$days days)..."; \
            ./scripts/performance-monitor.sh report "$$days"; \
            echo "✅ Performance report generated"; \
            ;; \
        alerts) \
            echo "🚨 Showing performance alerts..."; \
            ./scripts/performance-monitor.sh alerts; \
            echo "✅ Alerts displayed"; \
            ;; \
        cache-clear) \
            pattern="${1:-*}"; \
            echo "🧹 Clearing performance cache (pattern: $$pattern)..."; \
            ./scripts/performance-monitor.sh cache-clear "$$pattern"; \
            echo "✅ Performance cache cleared"; \
            ;; \
        *) \
            echo "❌ Unknown perf action: {{ ACTION }}"; \
            echo "Usage: just perf [setup|benchmark|report|alerts|cache-clear] [args]"; \
            exit 1; \
            ;; \
    esac

# Network and System Monitoring
# ==============================

# Start system monitoring with Netdata
netdata-start:
    @echo "🔧 Starting Netdata system monitoring..."
    launchctl load ~/Library/LaunchAgents/com.netdata.agent.plist || netdata -c ~/monitoring/netdata/config/netdata.conf -D
    @echo "✅ Netdata started - Dashboard available at http://localhost:19999"

# Stop Netdata monitoring
netdata-stop:
    @echo "🛑 Stopping Netdata monitoring..."
    launchctl unload ~/Library/LaunchAgents/com.netdata.agent.plist || sudo killall netdata || echo "Netdata was not running"
    @echo "✅ Netdata stopped"

# Start network monitoring with ntopng
ntopng-start:
    @echo "🌐 Starting ntopng network monitoring..."
    launchctl load ~/Library/LaunchAgents/com.ntopng.daemon.plist || sudo ntopng --config-file ~/monitoring/ntopng/config/ntopng.conf --daemon
    @echo "✅ ntopng started - Dashboard available at http://localhost:3000"

# Stop ntopng monitoring
ntopng-stop:
    @echo "🛑 Stopping ntopng monitoring..."
    launchctl unload ~/Library/LaunchAgents/com.ntopng.daemon.plist || sudo killall ntopng || echo "ntopng was not running"
    @echo "✅ ntopng stopped"

# Start comprehensive monitoring (both tools)
monitor-all:
    @echo "📊 Starting comprehensive monitoring..."
    just netdata-start
    just ntopng-start
    @echo "✅ All monitoring tools started"
    @echo "   Netdata: http://localhost:19999"
    @echo "   ntopng:  http://localhost:3000"

# Stop all monitoring tools
monitor-stop:
    @echo "🛑 Stopping all monitoring tools..."
    just netdata-stop
    just ntopng-stop
    @echo "✅ All monitoring stopped"

# Check monitoring status
monitor-status:
    @echo "📊 Checking monitoring status..."
    @echo "Netdata:" && (pgrep netdata > /dev/null && echo "✅ Running" || echo "❌ Not running")
    @echo "ntopng:" && (pgrep ntopng > /dev/null && echo "✅ Running" || echo "❌ Not running")

# Restart all monitoring tools
monitor-restart:
    @echo "🔄 Restarting monitoring tools..."
    just monitor-stop
    sleep 2
    just monitor-all
    @echo "✅ Monitoring tools restarted"

# Context Detection and Analysis
# ==============================

# Context detection commands - unified interface
# Usage: just context [detect|log|analyze|recommend|setup]
context ACTION="detect":
    @case "{{ ACTION }}" in \
        detect) \
            echo "🔍 Detecting current shell context..."; \
            ./scripts/shell-context-detector.sh detect; \
            echo "✅ Context detection complete"; \
            ;; \
        log) \
            echo "📝 Logging current shell session..."; \
            ./scripts/shell-context-detector.sh log; \
            echo "✅ Session logged"; \
            ;; \
        analyze) \
            echo "📊 Analyzing shell usage patterns..."; \
            ./scripts/shell-context-detector.sh analyze; \
            echo "✅ Analysis complete"; \
            ;; \
        recommend) \
            echo "💡 Generating loading recommendations..."; \
            ./scripts/shell-context-detector.sh recommend; \
            echo "✅ Recommendations generated"; \
            ;; \
        setup) \
            echo "🔧 Creating context-aware loading hook..."; \
            ./scripts/shell-context-detector.sh create-hook; \
            echo "✅ Context-aware loading hook created"; \
            ;; \
        *) \
            echo "❌ Unknown context action: {{ ACTION }}"; \
            echo "Usage: just context [detect|log|analyze|recommend|setup]"; \
            exit 1; \
            ;; \
    esac

# Comprehensive Performance Analysis
# ==================================

# Run full performance analysis
perf-full-analysis:
    @echo "🚀 Running comprehensive performance analysis..."
    @just benchmark all
    @just perf benchmark
    @just context analyze
    @just context recommend
    @just perf report
    @echo "✅ Full performance analysis complete"

# Setup all automation systems
automation-setup:
    @echo "🤖 Setting up all automation systems..."
    @just perf setup
    @just context setup
    @echo "✅ All automation systems setup complete"

# Debug shell startup with verbose logging
debug:
    @echo "🐛 Running shell startup in debug mode..."
    @echo "This will show detailed timing and command tracing."
    @echo "----------------------------------------"
    ZSH_DEBUG=1 zsh -i -c 'echo "Debug startup complete"'
    @echo "----------------------------------------"
    @echo "✅ Debug run complete"

# Health check for shell and development environment
health:
    @echo "🏥 Running health check for development environment..."
    @echo ""
    @echo "=== Shell Configuration ==="
    @echo -n "Starship prompt: "
    @if command -v starship >/dev/null 2>&1; then echo "✅ Available"; else echo "❌ Missing"; fi
    @echo -n "Fish completions: "
    @if command -v fish >/dev/null 2>&1; then echo "✅ Working"; else echo "❌ Broken"; fi
    @echo -n "Fish integration: "
    @if command -v fish >/dev/null 2>&1; then echo "✅ Working"; else echo "❌ Missing"; fi
    @echo ""
    @echo "=== Essential Tools ==="
    @echo -n "Bun: "
    @if command -v bun >/dev/null 2>&1; then echo "✅ $(bun --version)"; else echo "❌ Missing"; fi
    @echo -n "FZF: "
    @if command -v fzf >/dev/null 2>&1; then echo "✅ Available"; else echo "❌ Missing"; fi
    @echo -n "Git: "
    @if command -v git >/dev/null 2>&1; then echo "✅ $(git --version | cut -d' ' -f3)"; else echo "❌ Missing"; fi
    @echo -n "Just: "
    @if command -v just >/dev/null 2>&1; then echo "✅ $(just --version | cut -d' ' -f2)"; else echo "❌ Missing"; fi
    @echo -n "D2: "
    @if command -v d2 >/dev/null 2>&1; then echo "✅ $(d2 --version | head -1)"; else echo "❌ Missing"; fi
    @echo ""
    @echo "=== Go Development Tools ==="
    @echo -n "Go: "
    @if command -v go >/dev/null 2>&1; then echo "✅ $(go version)"; else echo "❌ Missing"; fi
    @echo -n "gopls: "
    @if command -v gopls >/dev/null 2>&1; then echo "✅ Available"; else echo "❌ Missing"; fi
    @echo -n "modernize: "
    @if command -v modernize >/dev/null 2>&1; then \
        echo "✅ Built with $(go version -m $(which modernize) 2>&1 | head -1 | awk '{print $NF}')"; \
    else \
        echo "❌ Missing"; \
    fi
    @echo ""
    @echo "=== Dotfile Links ==="
    @echo -n "Fish config: "
    @if [ -f ~/.config/fish/config.fish ]; then echo "✅ Present"; else echo "❌ Missing"; fi
    @echo -n "Starship config: "
    @if [ -f ~/.config/starship.toml ]; then echo "✅ Present"; else echo "❌ Missing"; fi
    @echo -n "Git config: "
    @if [ -f ~/.config/git/config ] || [ -f ~/.gitconfig ]; then echo "✅ Present"; else echo "❌ Missing"; fi
    @echo ""
    @echo "=== Shell Startup Test ==="
    @echo -n "Fish startup errors: "
    @if fish -c 'exit' 2>&1 | grep -q "error\|Error\|ERROR\|WARN"; then echo "❌ Has errors/warnings"; else echo "✅ Clean startup"; fi
    @echo ""
    @echo "✅ Health check complete"

# Verify d2 installation and file association
d2-verify:
    @echo "🔍 Verifying d2 installation..."
    @echo ""
    @echo "=== D2 Binary ==="
    @if command -v d2 >/dev/null 2>&1; then \
        echo "✅ Binary found: $$(which d2)"; \
        echo "✅ Version: $$(d2 --version | head -1)"; \
    else \
        echo "❌ d2 binary not found in PATH"; \
    fi
    @echo ""
    @echo "=== D2 File Association ==="
    @verify_d2=$$(duti -x .d2 2>/dev/null | head -1); \
    if [[ "$$verify_d2" == *"Sublime"* ]]; then \
        echo "✅ .d2 → Sublime Text"; \
    else \
        echo "⚠️ .d2 association: $$verify_d2"; \
    fi
    @echo ""
    @echo "=== D2 Syntax Check ==="
    @echo 'x -> y' | d2 - >/dev/null 2>&1 && echo "✅ D2 syntax works" || echo "❌ D2 syntax check failed"
    @echo ""
    @echo "✅ D2 verification complete"

# Go Development Tools
# ===================

# Run Go linter with golangci-lint on current directory
go-lint *ARGS="./...":
    @echo "🔍 Running Go linters..."
    golangci-lint run {{ ARGS }}
    @echo "✅ Go linting complete"

# Format Go code with gofumpt (stricter than gofmt)
go-format *ARGS=".":
    @echo "🎨 Formatting Go code with gofumpt..."
    gofumpt -l -w {{ ARGS }}
    @echo "✅ Go code formatted"

# Modernize Go code with Go 1.26rc2 modernize tool
go-modernize *ARGS="./...":
    @echo "🔄 Modernizing Go code (built with Go 1.26rc2)..."
    modernize -fix {{ ARGS }}
    @echo "✅ Go code modernized"

# Generate Go tests for a package using gotests
go-gen-tests package *ARGS="":
    @echo "🧪 Generating Go tests for package: {{ package }}"
    gotests -all -w {{ ARGS }} {{ package }}
    @echo "✅ Go tests generated"

# Generate mocks for Go interfaces using mockgen
go-gen-mocks source destination *ARGS="":
    @echo "🎭 Generating Go mocks..."
    mockgen -source={{ source }} -destination={{ destination }} {{ ARGS }}
    @echo "✅ Go mocks generated"

# Generate wire dependency injection code
go-wire *ARGS="":
    @echo "🔌 Generating wire dependency injection..."
    wire {{ ARGS }}
    @echo "✅ Wire generation complete"

# Start Go debugger (delve) for a Go binary
go-debug binary *ARGS="":
    @echo "🐛 Starting Go debugger for: {{ binary }}"
    dlv exec {{ binary }} {{ ARGS }}

# Start Go debugger for tests
go-debug-test package *ARGS="":
    @echo "🐛 Starting Go debugger for tests in: {{ package }}"
    dlv test {{ package }} {{ ARGS }}

# Run gopls language server check on current directory
go-check *ARGS=".":
    @echo "🔍 Running gopls check..."
    gopls check {{ ARGS }}
    @echo "✅ Gopls check complete"

# Generate protobuf Go code using buf
go-proto-gen *ARGS="":
    @echo "🔧 Generating protobuf Go code..."
    buf generate {{ ARGS }}
    @echo "✅ Protobuf generation complete"

# Lint protobuf files using buf
go-proto-lint *ARGS="":
    @echo "🔍 Linting protobuf files..."
    buf lint {{ ARGS }}
    @echo "✅ Protobuf linting complete"

# Full Go development workflow - format, lint, test, build
go-dev package="./...":
    @echo "🛠️  Running full Go development workflow..."
    @just go-format
    @just go-lint {{ package }}
    go test {{ package }}
    go build {{ package }}
    @echo "✅ Go development workflow complete"

# Auto-update all Go binaries using gup (recommended)
go-auto-update:
    @echo "🚀 Auto-updating all Go binaries with gup..."
    gup update
    @echo "✅ All Go binaries updated automatically"

# Check which Go binaries need updates
go-check-updates:
    @echo "🔍 Checking which Go binaries need updates..."
    gup check
    @echo "✅ Update check complete"

# List all Go binaries installed via 'go install'
go-list-binaries:
    @echo "📋 Listing all Go binaries..."
    gup list
    @echo "✅ Binary list complete"

# Export current Go binary list to gup.conf for reproducible installs
go-export-config:
    @echo "📦 Exporting Go binary configuration..."
    gup export
    @echo "✅ Configuration exported to gup.conf"

# Import Go binaries from gup.conf (useful for new machines)
go-import-config:
    @echo "📥 Importing Go binaries from configuration..."
    gup import
    @echo "✅ Binaries imported from gup.conf"

# Update Go tools (manual method using go install)
go-update-tools-manual:
    @echo "⚙️  Go development tools are now managed by Nix packages"
    @echo "ℹ️  Location: platforms/common/packages/base.nix"
    @echo "ℹ️  To update tools: just update && just switch"
    @echo "ℹ️  Note: wire not in Nixpkgs, still uses 'go install'"
    @echo ""
    @echo "🔄 Updating wire (not in Nixpkgs)..."
    go install github.com/google/wire/cmd/wire@latest
    @echo "✅ Go tools (except wire) updated via Nix"

# Complete Go setup (now Nix-managed)
go-setup:
    @echo "🛠️  Go development tools are now managed by Nix"
    @echo "ℹ️  Location: platforms/common/packages/base.nix"
    @echo "ℹ️  To install tools: just switch"
    @echo "ℹ️  To update tools: just update && just switch"
    @echo "✅ Go development environment setup via Nix"

# Show Go tools versions
go-tools-version:
    @echo "📋 Go Development Tools Versions"
    @echo "================================="
    @echo -n "Go: "; go version | cut -d' ' -f3
    @echo -n "golangci-lint: "; golangci-lint --version | head -1
    @echo -n "gofumpt: "; gofumpt -version 2>/dev/null || echo "installed"
    @echo -n "gopls: "; gopls version | head -1
    @echo -n "gotests: "; gotests -version 2>/dev/null || echo "installed"
    @echo -n "wire: "; wire version 2>/dev/null || echo "installed"
    @echo -n "mockgen: "; mockgen --version 2>/dev/null || echo "installed"
    @echo -n "protoc-gen-go: "; protoc-gen-go --version 2>/dev/null || echo "installed"
    @echo -n "buf: "; buf --version 2>/dev/null | head -1 || echo "installed"
    @echo -n "delve: "; dlv version | head -1

# Node.js/TypeScript development commands (Nix-managed)
# Lint TypeScript/JavaScript code with oxlint (faster than ESLint)
node-lint *ARGS="./src":
    @echo "🔍 Running oxlint on TypeScript/JavaScript code..."
    oxlint {{ ARGS }}
    @echo "✅ Linting complete"

# Format TypeScript/JavaScript code with oxfmt
node-format *ARGS="./src":
    @echo "🎨 Formatting TypeScript/JavaScript code with oxfmt..."
    oxfmt --write {{ ARGS }}
    @echo "✅ Formatting complete"

# Check TypeScript types with tsgolint (better than tsc)
node-check *ARGS="./src":
    @echo "🔎 Checking TypeScript types with tsgolint..."
    tsgolint {{ ARGS }}
    @echo "✅ Type checking complete"

# Run tests (supports npm, pnpm, bun, and yarn)
node-test *ARGS="":
    @pkg_manager=$$(just _detect_pkg_manager); \
    case $$pkg_manager in \
        bun) \
            echo "🧪 Running tests with bun..."; \
            bun test {{ ARGS }}; \
            ;; \
        pnpm) \
            echo "🧪 Running tests with pnpm..."; \
            pnpm test {{ ARGS }}; \
            ;; \
        npm) \
            echo "🧪 Running tests with npm..."; \
            npm test {{ ARGS }}; \
            ;; \
        yarn) \
            echo "🧪 Running tests with yarn..."; \
            yarn test {{ ARGS }}; \
            ;; \
        *) \
            echo "❌ No lockfile found (bun.lockb, pnpm-lock.yaml, package-lock.json, or yarn.lock)"; \
            exit 1; \
            ;; \
    esac

# Build project (supports npm, pnpm, bun, and yarn)
node-build *ARGS="":
    @pkg_manager=$$(just _detect_pkg_manager); \
    case $$pkg_manager in \
        bun) \
            echo "🔨 Building with bun..."; \
            bun run build {{ ARGS }}; \
            ;; \
        pnpm) \
            echo "🔨 Building with pnpm..."; \
            pnpm run build {{ ARGS }}; \
            ;; \
        npm) \
            echo "🔨 Building with npm..."; \
            npm run build {{ ARGS }}; \
            ;; \
        yarn) \
            echo "🔨 Building with yarn..."; \
            yarn build {{ ARGS }}; \
            ;; \
        *) \
            echo "❌ No lockfile found (bun.lockb, pnpm-lock.yaml, package-lock.json, or yarn.lock)"; \
            exit 1; \
            ;; \
    esac

# Full Node.js/TypeScript development workflow (format, lint, test, build)
node-dev *ARGS="./src":
    @echo "🛠️  Running full Node.js/TypeScript development workflow..."
    @just node-format {{ ARGS }}
    @just node-lint {{ ARGS }}
    @just node-check {{ ARGS }}
    @just node-test
    @just node-build
    @echo "✅ Node.js/TypeScript development workflow complete"

# Show Node.js/TypeScript tools versions
node-tools-version:
    @echo "📋 Node.js/TypeScript Development Tools Versions"
    @echo "=============================================="
    @echo -n "Node.js: "; node --version
    @echo -n "Bun: "; bun --version
    @echo -n "pnpm: "; pnpm --version
    @echo -n "esbuild: "; esbuild --version 2>/dev/null || echo "installed"
    @echo -n "vtsls: "; vtsls --version 2>/dev/null | head -1 || echo "installed"
    @echo -n "oxlint: "; oxlint --version 2>/dev/null | head -1 || echo "installed"
    @echo -n "tsgolint: "; tsgolint --version 2>/dev/null | head -1 || echo "installed"
    @echo -n "oxfmt: "; oxfmt --version 2>/dev/null | head -1 || echo "installed"

# Configure Claude AI settings using the Go tool
claude-config profile="personal" *ARGS="":
    @echo "🤖 Configuring Claude AI with profile: {{ profile }}"
    better-claude configure --profile {{ profile }} {{ ARGS }}
    @echo "✅ Claude configuration complete"

# Configure Claude AI with backup (recommended for production)
claude-config-safe profile="personal" *ARGS="":
    @echo "🤖 Configuring Claude AI with profile: {{ profile }} (with backup)"
    better-claude configure --profile {{ profile }} --backup {{ ARGS }}
    @echo "✅ Claude configuration complete with backup"

# Create a backup of current Claude configuration
claude-backup profile="personal":
    @echo "💾 Creating Claude configuration backup for profile: {{ profile }}"
    better-claude backup --profile {{ profile }}
    @echo "✅ Backup complete"

# Restore Claude configuration from backup
claude-restore backup_file:
    @echo "🔄 Restoring Claude configuration from: {{ backup_file }}"
    better-claude restore {{ backup_file }}
    @echo "✅ Restore complete"

# Test Claude configuration (dry-run mode)
claude-test profile="personal":
    @echo "🧪 Testing Claude configuration for profile: {{ profile }} (dry-run)"
    better-claude configure --profile {{ profile }} --dry-run
    @echo "✅ Test complete - no changes made"

# Show help with detailed descriptions
help:
    @echo "SystemNix Task Runner"
    @echo "====================="
    @echo ""
    @echo "Main Commands:"
    @echo "  setup          - Complete initial setup (run after cloning)"
    @echo "  switch         - Apply Nix configuration changes"
    @echo "  update         - Update Nix flake and packages"
    @echo "  clean          - Clean up caches and old packages (comprehensive, needs sudo)"
    @echo "  clean-storage  - Quick cache cleanup (safe, no sudo needed)"
    @echo ""
    @echo "Development:"
    @echo "  format         - Format code with treefmt"
    @echo "  test           - Test configuration without applying"
    @echo "  dev            - Run development workflow (format, check, test)"
    @echo "  debug          - Debug shell startup with verbose logging"
    @echo "  health         - Health check for shell and dev environment"
    @echo "  health-dashboard - Comprehensive system health dashboard"
    @echo ""
    @echo "Performance & Benchmarking:"
    @echo "  benchmark [all|shells|build|system|files|report|clean|legacy]"
    @echo "                 - Run benchmarks (default: all)"
    @echo "  perf [setup|benchmark|report|alerts|cache-clear]"
    @echo "                 - Performance monitoring (default: benchmark)"
    @echo "  context [detect|log|analyze|recommend|setup]"
    @echo "                 - Shell context analysis (default: detect)"
    @echo ""
    @echo "Go Development Tools (Nix-managed):"
    @echo "  go-lint               - Run golangci-lint on Go code"
    @echo "  go-format             - Format Go code with gofumpt"
    @echo "  go-gen-tests          - Generate Go tests with gotests"
    @echo "  go-gen-mocks          - Generate Go mocks with mockgen"
    @echo "  go-wire               - Generate wire dependency injection (go install)"
    @echo "  go-debug              - Start Go debugger (delve) for binary"
    @echo "  go-debug-test         - Start Go debugger for tests"
    @echo "  go-check              - Run gopls language server check"
    @echo "  go-proto-gen          - Generate protobuf Go code with buf"
    @echo "  go-proto-lint         - Lint protobuf files with buf"
    @echo "  go-dev                - Full Go development workflow"
    @echo "  go-auto-update        - Auto-update all Go binaries with gup"
    @echo "  go-check-updates      - Check which Go binaries need updates"
    @echo "  go-list-binaries      - List all Go binaries"
    @echo "  go-export-config      - Export Go binary config to gup.conf"
    @echo "  go-import-config      - Import Go binaries from gup.conf"
    @echo "  go-update-tools-manual - Update wire (not in Nixpkgs) with go install"
    @echo "  go-setup              - Show Go tool management information"
    @echo "  go-tools-version      - Show versions of all Go tools"
    @echo ""
    @echo "Maintenance:"
    @echo "  check          - Check system status and outdated packages"
    @echo "  backup         - Create configuration backup"
    @echo "  list-backups   - List available backups"
    @echo "  restore        - Restore from backup (usage: just restore BACKUP_NAME)"
    @echo "  clean-backups  - Clean old backups (keep last 10)"
    @echo "  rebuild-completions - Rebuild zsh completion cache"
    @echo ""
    @echo "Dependency Graphs:"
    @echo "  dep-graph [nixos|darwin|svg|png|dot|all|verbose|view|clean|update|stats]"
    @echo "                 - Generate/view Nix dependency graphs (default: darwin)"
    @echo ""
    @echo "Environment:"
    @echo "  env-private    - Create private environment file for secrets"
    @echo ""
    @echo "Claude AI Configuration:"
    @echo "  claude-config         - Configure Claude AI with specified profile"
    @echo "  claude-config-safe    - Configure Claude AI with backup (recommended)"
    @echo "  claude-backup         - Create backup of current Claude configuration"
    @echo "  claude-restore        - Restore Claude configuration from backup"
    @echo "  claude-test           - Test Claude configuration (dry-run mode)"
    @echo ""
    @echo "Git & Pre-commit:"
    @echo "  pre-commit-install - Install pre-commit hooks"
    @echo "  pre-commit-run     - Run pre-commit on all files"
    @echo "  status             - Show git status and recent commits"
    @echo ""
    @echo "Utilities:"
    @echo "  info           - Show system information"
    @echo "  ssh-setup      - Create SSH directories"
    @echo "  rollback       - Emergency rollback to previous generation"
    @echo ""
    @echo "Run 'just <command>' to execute any task."

# Documentation Management Commands
# ================================

# Update README.md with Nix-managed tools section
doc-update-readme:
    @echo "📝 Updating README.md with Nix-managed tools section..."
    @printf '%s\n\n### Nix-Managed Development Tools\n\nAll development tools are managed through Nix packages, providing:\n- **Reproducible Builds**: Same tool versions across all machines\n- **Atomic Updates**: Managed via `just update && just switch`\n- **Declarative Configuration**: Tools defined in Nix, not installed imperatively\n- **Easy Rollback**: Revert to previous tool versions instantly\n\n**Go Development Stack:**\nAll Go tools (gopls, golangci-lint, gofumpt, gotests, mockgen, protoc-gen-go, buf, delve, gup) are installed via Nix packages defined in `platforms/common/packages/base.nix`.\n\nTo view available Go tools:\n```bash\njust go-tools-version    # Show all Go tool versions\njust go-dev             # Full Go development workflow\n```\n\n**ActivityWatch (macOS):**\nActivityWatch auto-start is managed declaratively via Nix LaunchAgent configuration in `platforms/darwin/services/launchagents.nix`. No manual setup scripts required.\n' "$(head -n 289 README.md)" > README.md.new
    @tail -n +290 README.md >> README.md.new
    @mv README.md.new README.md
    @echo "✅ README.md updated successfully"

# Update Go section in "What You Get" to mention Nix packages
doc-update-go-what-you-get:
    @echo "📝 Updating 'What You Get' Go section..."
    @perl -i -pe 's/Go \(with templ, sqlc, go-tools\)/Go (Nix-managed: gopls, golangci-lint, gofumpt, gotests, mockgen, protoc-gen-go, buf, delve, gup + templ, sqlc, go-tools)/ if $. == 270' README.md
    @echo "✅ 'What You Get' Go section updated"

# Wrapper Management Commands
# =========================

# Comprehensive system health dashboard
health-dashboard:
    @echo "🏥 Launching comprehensive health dashboard..."
    @./scripts/health-dashboard.sh

# Tmux configuration and session management
tmux-setup:
    @echo "🔧 Setting up tmux configuration..."
    sudo nixos-rebuild switch --flake .#evo-x2 || darwin-rebuild switch --flake .#Lars-MacBook-Air
    @echo "✅ Tmux configuration applied"

tmux-dev:
    @echo "🚀 Starting SystemNix development session..."
    tmux has-session -t SystemNix && tmux attach-session -t SystemNix || \
    tmux new-session -d -s SystemNix -n just "cd ~/projects/SystemNix && just" \; \
                   new-window -d -n nvim "cd ~/projects/SystemNix && nvim" \; \
                   new-window -d -n shell "cd ~/projects/SystemNix" \; \
                   select-window -t 0
    tmux attach-session -t SystemNix

tmux-attach:
    @echo "📋 Attaching to SystemNix session..."
    tmux attach-session -t SystemNix || tmux new-session -s SystemNix

tmux-sessions:
    @echo "📋 Active tmux sessions:"
    @tmux list-sessions || echo "No active sessions"

tmux-kill:
    @echo "💀 Killing all tmux sessions..."
    tmux kill-server
    @echo "✅ All tmux sessions killed"

tmux-save:
    @echo "💾 Saving tmux sessions..."
    tmux run-shell "tmux save-session"
    @echo "✅ Tmux sessions saved"

tmux-restore:
    @echo "🔄 Restoring tmux sessions..."
    tmux run-shell "tmux restore-session"
    @echo "✅ Tmux sessions restored"

tmux-status:
    @echo "📊 Tmux status:"
    @echo "  Server: $(tmux server-info 2>/dev/null | head -1 || echo 'Not running')"
    @echo "  Sessions: $(tmux list-sessions 2>/dev/null | wc -l || echo '0')"
    @echo "  Config: $HOME/.config/tmux/tmux.conf"

# Show dependency graph statistics
# 2. Manual documentation (docs/nix-call-graph.md)
# 3. Alternative tools (e.g., nix-tree for store queries)

# Dependency graph commands - unified interface
# Usage: just dep-graph [nixos|darwin|svg|png|dot|all|verbose|view|clean|update|stats]
dep-graph ACTION="darwin":
    @mkdir -p docs/architecture
    @case "{{ ACTION }}" in \
        nixos) \
            echo "📊 Generating Nix dependency graph for NixOS..."; \
            echo "  This may take a moment to analyze system dependencies..."; \
            nix eval .#nixosConfigurations.evo-x2.config.system.build.toplevel --raw 2>&1 | \
                xargs nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/Setup-Mac-NixOS.svg \
                --no-verbose; \
            echo "✅ Dependency graph generated: docs/architecture/Setup-Mac-NixOS.svg"; \
            ls -lh docs/architecture/Setup-Mac-NixOS.svg | awk '{print "   Size: " $5}'; \
            ;; \
        darwin) \
            echo "📊 Generating Nix dependency graph for Darwin..."; \
            echo "  This may take a moment to analyze system dependencies..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/Setup-Mac-Darwin.svg \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/Setup-Mac-Darwin.svg"; \
            ls -lh docs/architecture/Setup-Mac-Darwin.svg | awk '{print "   Size: " $5}'; \
            ;; \
        svg) \
            echo "📊 Generating Nix dependency graph (SVG)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/Setup-Mac-Darwin.svg \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/Setup-Mac-Darwin.svg"; \
            ls -lh docs/architecture/Setup-Mac-Darwin.svg | awk '{print "   Size: " $5}'; \
            ;; \
        png) \
            echo "📊 Generating Nix dependency graph (PNG)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/Setup-Mac-Darwin.png \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/Setup-Mac-Darwin.png"; \
            ls -lh docs/architecture/Setup-Mac-Darwin.png | awk '{print "   Size: " $5}'; \
            ;; \
        dot) \
            echo "📊 Generating Nix dependency graph (DOT)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/Setup-Mac-Darwin.dot \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/Setup-Mac-Darwin.dot"; \
            ls -lh docs/architecture/Setup-Mac-Darwin.dot | awk '{print "   Size: " $5}'; \
            ;; \
        all) \
            echo "📊 Generating all Nix dependency graphs..."; \
            echo ""; \
            echo "=== Darwin Graphs ==="; \
            just dep-graph darwin; \
            just dep-graph png; \
            echo ""; \
            echo "✅ All dependency graphs generated in docs/architecture/"; \
            ls -lh docs/architecture/Setup-Mac-Darwin*.{svg,png,dot} 2>/dev/null | awk '{print "   " $9 ": " $5}'; \
            ;; \
        verbose) \
            echo "📊 Generating Nix dependency graph (verbose mode)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/Setup-Mac-Darwin-verbose.svg \
                --verbose \
                /run/current-system; \
            echo "✅ Verbose dependency graph generated"; \
            ls -lh docs/architecture/Setup-Mac-Darwin-verbose.svg | awk '{print "   Size: " $5}'; \
            ;; \
        view) \
            echo "👀 Opening dependency graph..."; \
            if [ -f docs/architecture/Setup-Mac-Darwin.svg ]; then \
                open docs/architecture/Setup-Mac-Darwin.svg; \
            elif [ -f docs/architecture/Setup-Mac-Darwin.png ]; then \
                open docs/architecture/Setup-Mac-Darwin.png; \
            elif [ -f docs/architecture/Setup-Mac-NixOS.svg ]; then \
                open docs/architecture/Setup-Mac-NixOS.svg; \
            else \
                echo "❌ No dependency graph found. Run 'just dep-graph darwin' first."; \
            fi; \
            ;; \
        clean) \
            echo "🧹 Cleaning dependency graphs..."; \
            rm -f docs/architecture/Setup-Mac-*.{svg,png,dot}; \
            rm -f docs/architecture/*.svg; \
            rm -f docs/architecture/*.png; \
            rm -f docs/architecture/*.dot; \
            echo "✅ Dependency graphs cleaned"; \
            ;; \
        update) \
            echo "🔄 Updating dependency graphs..."; \
            just dep-graph darwin; \
            echo ""; \
            echo "👀 Opening in browser..."; \
            sleep 1; \
            just dep-graph view; \
            ;; \
        stats) \
            echo "📊 Dependency graph statistics:"; \
            echo ""; \
            if [ -f docs/architecture/Setup-Mac-NixOS.svg ]; then \
                echo "NixOS SVG: $$(ls -lh docs/architecture/Setup-Mac-NixOS.svg | awk '{print $$5}')"; \
            fi; \
            if [ -f docs/architecture/Setup-Mac-Darwin.svg ]; then \
                echo "Darwin SVG: $$(ls -lh docs/architecture/Setup-Mac-Darwin.svg | awk '{print $$5}')"; \
            fi; \
            if [ -f docs/architecture/Setup-Mac-Darwin.png ]; then \
                echo "Darwin PNG: $$(ls -lh docs/architecture/Setup-Mac-Darwin.png | awk '{print $$5}')"; \
            fi; \
            echo ""; \
            echo "Files in docs/architecture/:"; \
            ls -1 docs/architecture/ 2>/dev/null | wc -l | awk '{print "   Total: " $1 " files"}'; \
            ;; \
        *) \
            echo "❌ Unknown dep-graph action: {{ ACTION }}"; \
            echo "Usage: just dep-graph [nixos|darwin|svg|png|dot|all|verbose|view|clean|update|stats]"; \
            exit 1; \
            ;; \
    esac

# ========================================
# DNS Management Commands (dns-blocker)
# ========================================

# Check DNS blocker service status
dns-status:
    @echo "🔍 Checking DNS blocker status..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  DNS blocker is only configured on NixOS (evo-x2)"; \
    else \
        echo ""; \
        echo "Unbound (DNS resolver):"; \
        systemctl is-active unbound && echo "  ✅ Running" || echo "  ❌ Not running"; \
        echo ""; \
        echo "dnsblockd (block page server):"; \
        systemctl is-active dnsblockd && echo "  ✅ Running" || echo "  ❌ Not running"; \
    fi

# View DNS logs
dns-logs:
    @echo "📋 Viewing DNS logs..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  DNS blocker is not configured on Darwin"; \
    else \
        echo "=== Unbound logs ===" && journalctl -u unbound -f --no-pager -n 50; \
    fi

# View dnsblockd logs
dns-logs-blocker:
    @echo "📋 Viewing dnsblockd logs..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  DNS blocker is not configured on Darwin"; \
    else \
        journalctl -u dnsblockd -f --no-pager -n 50; \
    fi

# Restart DNS services
dns-restart:
    @echo "🔄 Restarting DNS services..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "⚠️  DNS blocker is not configured on Darwin"; \
    else \
        sudo systemctl restart unbound dnsblockd && echo "✅ DNS services restarted" || echo "❌ Failed to restart"; \
    fi

# Test DNS resolution and blocking
dns-test:
    @echo "🧪 Testing DNS resolution..."
    @echo ""
    @echo "Testing basic resolution..."
    @if command -v dig >/dev/null 2>&1; then \
        echo "  google.com:"; \
        dig google.com +short | head -1 || echo "    ❌ Resolution failed"; \
        echo ""; \
        echo "Testing ad blocking (should return 192.168.1.163 for blocked domains)..."; \
        echo "  doubleclick.net:"; \
        RESULT=$$(dig doubleclick.net +short); \
        if [ "$$RESULT" = "192.168.1.163" ]; then \
            echo "    ✅ Blocked (192.168.1.163)"; \
        elif [ -z "$$RESULT" ]; then \
            echo "    ✅ Blocked (NXDOMAIN)"; \
        else \
            echo "    ⚠️  Not blocked: $$RESULT"; \
        fi; \
        echo ""; \
        echo "Testing DNSSEC validation..."; \
        echo "  example.net:"; \
        dig +dnssec example.net +short | head -1 || echo "    ❌ Resolution failed"; \
    else \
        echo "❌ 'dig' not found. Install with: 'just switch'"; \
    fi

# Test DNS with specific server
dns-test-server server:
    @echo "🧪 Testing DNS with server: {{server}}..."
    @if command -v dig >/dev/null 2>&1; then \
        echo "  google.com:"; \
        dig @{{server}} google.com +short | head -1 || echo "    ❌ Failed"; \
        echo "  doubleclick.net (blocked test):"; \
        dig @{{server}} doubleclick.net +short || echo "    ✅ Blocked"; \
    else \
        echo "❌ 'dig' not found"; \
    fi

# DNS performance test
dns-perf:
    @echo "⚡ Testing DNS performance..."
    @if command -v dig >/dev/null 2>&1; then \
        echo "Uncached resolution:"; \
        time dig github.com +short > /dev/null; \
        echo ""; \
        echo "Cached resolution (should be faster):"; \
        time dig github.com +short > /dev/null; \
    else \
        echo "❌ 'dig' not found"; \
    fi

# Show DNS configuration
dns-config:
    @echo "📋 DNS Configuration..."
    @echo ""
    @echo "System DNS servers:"
    @cat /etc/resolv.conf 2>/dev/null || echo "  (no resolv.conf)"
    @echo ""
    @if [ "$(uname)" != "Darwin" ]; then \
        echo "Unbound config:"; \
        echo "  Blocklist: /etc/unbound/blocklist.conf"; \
        echo "  Stats: http://127.0.0.1:9090/health"; \
    fi

# DNS blocker stats
dns-stats:
    @echo "📊 DNS Blocker Stats..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  DNS blocker is not configured on Darwin"; \
    else \
        curl -s http://127.0.0.1:9090/health 2>/dev/null || echo "❌ Stats API not responding"; \
        echo ""; \
        curl -s http://127.0.0.1:9090/stats 2>/dev/null || echo "❌ Stats endpoint not available"; \
    fi

# DNS diagnostics
dns-diagnostics:
    @echo "🔬 Running DNS diagnostics..."
    @echo ""
    @just dns-status
    @echo ""
    @just dns-config
    @echo ""
    @just dns-test
    @echo ""
    @just dns-stats
    @echo ""
    @echo "✅ DNS diagnostics complete"

# ========================================
# Immich Photo/Video Management Commands
# ========================================

# Check Immich service status
immich-status:
    @echo "📸 Checking Immich status..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        echo ""; \
        echo "Immich Server:"; \
        systemctl is-active immich-server && echo "  ✅ Running (http://localhost:2283)" || echo "  ❌ Not running"; \
        echo ""; \
        echo "Immich Machine Learning:"; \
        systemctl is-active immich-machine-learning && echo "  ✅ Running" || echo "  ❌ Not running"; \
        echo ""; \
        echo "PostgreSQL:"; \
        systemctl is-active postgresql && echo "  ✅ Running" || echo "  ❌ Not running"; \
        echo ""; \
        echo "Redis (immich):"; \
        systemctl is-active redis-immich && echo "  ✅ Running" || echo "  ❌ Not running"; \
        echo ""; \
        echo "Backup Timer:"; \
        systemctl list-timers immich-db-backup.timer --no-pager 2>/dev/null | grep -q "immich" && echo "  ✅ Scheduled" || echo "  ❌ Not scheduled"; \
    fi

# View Immich server logs
immich-logs:
    @echo "📋 Viewing Immich server logs..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        journalctl -u immich-server -f --no-pager -n 50; \
    fi

# View Immich ML logs (check for GPU/CPU provider)
immich-logs-ml:
    @echo "📋 Viewing Immich machine learning logs..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        journalctl -u immich-machine-learning -f --no-pager -n 50; \
    fi

# Run Immich database backup manually
immich-backup:
    @echo "💾 Running Immich database backup..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        sudo systemctl start immich-db-backup && echo "✅ Backup complete" || echo "❌ Backup failed"; \
        echo "Location: /var/lib/immich/database-backup/"; \
    fi

# List Immich database backups
immich-backups:
    @echo "📋 Immich database backups..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        ls -lh /var/lib/immich/database-backup/ 2>/dev/null || echo "  No backups found"; \
    fi

# Restart all Immich services
immich-restart:
    @echo "🔄 Restarting Immich services..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        sudo systemctl restart immich-server immich-machine-learning && echo "✅ Immich services restarted" || echo "❌ Restart failed"; \
    fi
