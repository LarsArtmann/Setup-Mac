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
        nh os switch . -- --print-build-logs; \
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

# ActivityWatch manual control commands (macOS only)
activitywatch-start:
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" != "darwin" ]; then \
        echo "❌ This command only works on macOS (uses osascript)"; \
        exit 1; \
    fi; \
    echo "🚀 Starting ActivityWatch..."; \
    osascript -e 'tell application "ActivityWatch" to launch'; \
    sleep 3; \
    pgrep -f ActivityWatch > /dev/null && echo "✅ ActivityWatch started" || echo "❌ Failed to start"

activitywatch-stop:
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" != "darwin" ]; then \
        echo "❌ This command only works on macOS"; \
        exit 1; \
    fi; \
    echo "🛑 Stopping ActivityWatch..."; \
    pkill -f ActivityWatch || echo "  (ActivityWatch not running)"; \
    sleep 2; \
    pgrep -f ActivityWatch > /dev/null && echo "❌ ActivityWatch still running" || echo "✅ ActivityWatch stopped"

# Gitea repository management (NixOS only)
gitea-update-token:
    @PLATFORM=$(just _detect_platform); \
    if [ "$PLATFORM" != "linux" ]; then \
        echo "❌ This command only works on NixOS (evo-x2)"; \
        echo "   SSH to evo-x2 and run: just gitea-update-token"; \
        exit 1; \
    fi; \
    echo "🔑 Updating GitHub token from gh CLI..."; \
    gitea-update-github-token

gitea-sync-repos:
    @PLATFORM=$(just _detect_platform); \
    if [ "$PLATFORM" != "linux" ]; then \
        echo "❌ This command only works on NixOS (evo-x2)"; \
        echo "   SSH to evo-x2 and run: just gitea-sync-repos"; \
        exit 1; \
    fi; \
    echo "🔄 Syncing GitHub repos to Gitea..."; \
    gitea-ensure-repos

gitea-setup:
    @PLATFORM=$(just _detect_platform); \
    if [ "$PLATFORM" != "linux" ]; then \
        echo "❌ This command only works on NixOS (evo-x2)"; \
        echo "   SSH to evo-x2 and run: just gitea-setup"; \
        exit 1; \
    fi; \
    echo "🚀 Gitea setup helper..."; \
    gitea-setup

# Clean up caches and old packages (comprehensive cleanup)
clean:
    @PLATFORM=$(just _detect_platform); \
    echo "🧹 Starting comprehensive system cleanup..."; \
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
    trash ~/.bun/install/cache 2>/dev/null || echo "  ⚠️  Bun cache not found"; \
    trash ~/.gradle/caches/* 2>/dev/null || echo "  ⚠️  Gradle cache not found"; \
    trash ~/.cache/puppeteer 2>/dev/null || echo "  ⚠️  Puppeteer cache not found"; \
    trash ~/.nuget/packages 2>/dev/null || echo "  ⚠️  NuGet cache not found"; \
    echo ""; \
    echo "=== System Cache Cleanup ==="; \
    if [ "$PLATFORM" = "darwin" ]; then \
        echo "🔦 Cleaning Spotlight metadata..."; \
        [ -d ~/Library/Metadata/CoreSpotlight/SpotlightKnowledgeEvents ] && trash ~/Library/Metadata/CoreSpotlight/SpotlightKnowledgeEvents || echo "  ⚠️  Spotlight metadata not found"; \
    fi; \
    echo "🗂️  Cleaning system temp files..."; \
    find /tmp -maxdepth 1 -name 'nix-build-*' -print0 2>/dev/null | xargs -0 trash 2>/dev/null || echo "  ⚠️  No nix-build temp files found"; \
    find /tmp -maxdepth 1 -name 'nix-shell-*' -print0 2>/dev/null | xargs -0 trash 2>/dev/null || echo "  ⚠️  No nix-shell temp files found"; \
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
    find /tmp -maxdepth 1 \( -name 'nix-build-*' -o -name 'nix-shell-*' \) -print0 2>/dev/null | xargs -0 trash 2>/dev/null || echo "  ⚠️  No temp files found"; \
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
    trash ~/.nvm/versions/node/* || true; \
    echo "🐍 Cleaning Python versions..."; \
    trash ~/.pyenv/versions/* || true; \
    echo "💎 Cleaning Ruby versions..."; \
    trash ~/.rbenv/versions/* || true; \
    echo ""; \
    echo "=== Development Caches ==="; \
    echo "🏗️  Cleaning all build caches..."; \
    trash ~/.cache 2>/dev/null || true && mkdir -p ~/.cache; \
    if [ "$PLATFORM" = "darwin" ]; then \
        trash ~/Library/Caches/CocoaPods 2>/dev/null || true; \
        trash ~/Library/Caches/Homebrew 2>/dev/null || true; \
        trash ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true; \
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

# Alias for test-fast
validate:
    @just test-fast

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
    ls -1t | tail -n +11 | xargs trash 2>/dev/null || { echo "  trash failed, skipping old backup cleanup"; exit 0; }
    echo "✅ Old backups cleaned"

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
        nh os test .; \
    fi
    @echo "✅ Configuration test passed"

# Fast test - syntax validation only (skips heavy packages)
test-fast:
    @echo "🚀 Fast testing Nix configuration (syntax only)..."
    nix --extra-experimental-features "nix-command flakes" flake check --no-build
    @echo "✅ Fast configuration test passed"

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
        nh os switch . -- --rollback; \
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
    @./scripts/health-check.sh

# Verify d2 installation and file association (macOS only — uses duti)
d2-verify:
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" != "darwin" ]; then \
        echo "❌ This command only works on macOS (uses duti for file associations)"; \
        exit 1; \
    fi; \
    echo "🔍 Verifying d2 installation..."; \
    echo ""; \
    echo "=== D2 Binary ==="; \
    if command -v d2 >/dev/null 2>&1; then \
        echo "✅ Binary found: $$(which d2)"; \
        echo "✅ Version: $$(d2 --version | head -1)"; \
    else \
        echo "❌ d2 binary not found in PATH"; \
    fi; \
    echo ""; \
    echo "=== D2 File Association ==="; \
    verify_d2=$$(duti -x .d2 2>/dev/null | head -1); \
    if [[ "$$verify_d2" == *"Sublime"* ]]; then \
        echo "✅ .d2 → Sublime Text"; \
    else \
        echo "⚠️ .d2 association: $$verify_d2"; \
    fi; \
    echo ""; \
    echo "=== D2 Syntax Check ==="; \
    echo 'x -> y' | d2 - >/dev/null 2>&1 && echo "✅ D2 syntax works" || echo "❌ D2 syntax check failed"; \
    echo ""; \
    echo "✅ D2 verification complete"

# Go Development Tools
# ===================

# Run Go linter with golangci-lint on current directory
go-lint *ARGS="./...":
    @echo "🔍 Running Go linters..."
    golangci-lint run {{ ARGS }}
    @echo "✅ Go linting complete"

# Run architecture lint with go-arch-lint
go-arch-lint *ARGS="":
    @echo "🏗️  Running architecture linter..."
    go-arch-lint check {{ ARGS }}
    @echo "✅ Architecture lint complete"

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
    @echo -n "go-arch-lint: "; go-arch-lint version 2>/dev/null || echo "installed"

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


help:
    @echo "SystemNix Task Runner"
    @echo "====================="
    @echo ""
    @echo "Main Commands:"
    @echo "  setup          - Complete initial setup (run after cloning)"
    @echo "  switch         - Apply Nix configuration changes"
    @echo "  update         - Update Nix flake and packages"
    @echo "  clean          - Clean up caches and old packages (comprehensive, needs sudo)"
    @echo "  clean-quick    - Quick daily cleanup (safe, no store optimization)"
    @echo ""
    @echo "Development:"
    @echo "  format         - Format code with treefmt"
    @echo "  test           - Test configuration without applying"
    @echo "  test-fast      - Syntax-only validation (fast)"
    @echo "  dev            - Run development workflow (format, check, test)"
    @echo "  debug          - Debug shell startup with verbose logging"
    @echo "  health         - Health check for shell and dev environment"
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
    @echo "Node.js/TypeScript Tools (Nix-managed):"
    @echo "  node-lint             - Run oxlint on TypeScript/JavaScript code"
    @echo "  node-format          - Format with oxfmt"
    @echo "  node-check           - Check types with tsgolint"
    @echo "  node-test            - Run tests (auto-detects pkg manager)"
    @echo "  node-build           - Build project (auto-detects pkg manager)"
    @echo "  node-dev             - Full Node.js/TypeScript workflow"
    @echo "  node-tools-version   - Show versions of all Node.js tools"
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
    @echo "Disk Monitoring:"
    @echo "  disk-monitor-status   - Show disk monitor status and current usage"
    @echo "  disk-monitor-check    - Trigger manual disk check"
    @echo "  disk-monitor-reset    - Reset notification state (allow re-notifying)"
    @echo "  disk-monitor-schedule - Show timer schedule"
    @echo ""
    @echo "Run 'just <command>' to execute any task."

# Wrapper Management Commands
# =========================

# Tmux configuration and session management
tmux-setup:
    @echo "🔧 Setting up tmux configuration..."
    nh os switch . || darwin-rebuild switch --flake .#Lars-MacBook-Air
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
                --output docs/architecture/SystemNix-NixOS.svg \
                --no-verbose; \
            echo "✅ Dependency graph generated: docs/architecture/SystemNix-NixOS.svg"; \
            ls -lh docs/architecture/SystemNix-NixOS.svg | awk '{print "   Size: " $5}'; \
            ;; \
        darwin) \
            echo "📊 Generating Nix dependency graph for Darwin..."; \
            echo "  This may take a moment to analyze system dependencies..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/SystemNix-Darwin.svg \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/SystemNix-Darwin.svg"; \
            ls -lh docs/architecture/SystemNix-Darwin.svg | awk '{print "   Size: " $5}'; \
            ;; \
        svg) \
            echo "📊 Generating Nix dependency graph (SVG)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/SystemNix-Darwin.svg \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/SystemNix-Darwin.svg"; \
            ls -lh docs/architecture/SystemNix-Darwin.svg | awk '{print "   Size: " $5}'; \
            ;; \
        png) \
            echo "📊 Generating Nix dependency graph (PNG)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/SystemNix-Darwin.png \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/SystemNix-Darwin.png"; \
            ls -lh docs/architecture/SystemNix-Darwin.png | awk '{print "   Size: " $5}'; \
            ;; \
        dot) \
            echo "📊 Generating Nix dependency graph (DOT)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/SystemNix-Darwin.dot \
                --no-verbose \
                /run/current-system; \
            echo "✅ Dependency graph generated: docs/architecture/SystemNix-Darwin.dot"; \
            ls -lh docs/architecture/SystemNix-Darwin.dot | awk '{print "   Size: " $5}'; \
            ;; \
        all) \
            echo "📊 Generating all Nix dependency graphs..."; \
            echo ""; \
            echo "=== Darwin Graphs ==="; \
            just dep-graph darwin; \
            just dep-graph png; \
            echo ""; \
            echo "✅ All dependency graphs generated in docs/architecture/"; \
            ls -lh docs/architecture/SystemNix-Darwin*.{svg,png,dot} 2>/dev/null | awk '{print "   " $9 ": " $5}'; \
            ;; \
        verbose) \
            echo "📊 Generating Nix dependency graph (verbose mode)..."; \
            nix run github:craigmbooth/nix-visualize -- \
                --output docs/architecture/SystemNix-Darwin-verbose.svg \
                --verbose \
                /run/current-system; \
            echo "✅ Verbose dependency graph generated"; \
            ls -lh docs/architecture/SystemNix-Darwin-verbose.svg | awk '{print "   Size: " $5}'; \
            ;; \
        view) \
            echo "👀 Opening dependency graph..."; \
            if [ -f docs/architecture/SystemNix-Darwin.svg ]; then \
                open docs/architecture/SystemNix-Darwin.svg; \
            elif [ -f docs/architecture/SystemNix-Darwin.png ]; then \
                open docs/architecture/SystemNix-Darwin.png; \
            elif [ -f docs/architecture/SystemNix-NixOS.svg ]; then \
                open docs/architecture/SystemNix-NixOS.svg; \
            else \
                echo "❌ No dependency graph found. Run 'just dep-graph darwin' first."; \
            fi; \
            ;; \
        clean) \
            echo "🧹 Cleaning dependency graphs..."; \
            rm -f docs/architecture/SystemNix-*.{svg,png,dot}; \
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
            if [ -f docs/architecture/SystemNix-NixOS.svg ]; then \
                echo "NixOS SVG: $$(ls -lh docs/architecture/SystemNix-NixOS.svg | awk '{print $$5}')"; \
            fi; \
            if [ -f docs/architecture/SystemNix-Darwin.svg ]; then \
                echo "Darwin SVG: $$(ls -lh docs/architecture/SystemNix-Darwin.svg | awk '{print $$5}')"; \
            fi; \
            if [ -f docs/architecture/SystemNix-Darwin.png ]; then \
                echo "Darwin PNG: $$(ls -lh docs/architecture/SystemNix-Darwin.png | awk '{print $$5}')"; \
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
        echo "=== Unbound logs ===" && journalctl -u unbound --no-pager -n 100; \
    fi

# View dnsblockd logs
dns-logs-blocker:
    @echo "📋 Viewing dnsblockd logs..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  DNS blocker is not configured on Darwin"; \
    else \
        journalctl -u dnsblockd --no-pager -n 100; \
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
        echo "Testing ad blocking (should return 192.168.1.150 for blocked domains)..."; \
        echo "  doubleclick.net:"; \
        RESULT=$$(dig doubleclick.net +short); \
        if [ "$$RESULT" = "192.168.1.150" ]; then \
            echo "    ✅ Blocked (192.168.1.150)"; \
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
        journalctl -u immich-server --no-pager -n 100; \
    fi

# View Immich ML logs (check for GPU/CPU provider)
immich-logs-ml:
    @echo "📋 Viewing Immich machine learning logs..."
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "ℹ️  Immich is only configured on NixOS (evo-x2)"; \
    else \
        journalctl -u immich-machine-learning --no-pager -n 100; \
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

# ========================================
# Taskwarrior / TaskChampion Commands
# ========================================

# List pending tasks (default view)
task-list:
    @task next

# Add a new task
task-add *ARGS:
    @task add {{ ARGS }}

# Add a task tagged +agent with source metadata
task-agent *ARGS:
    @task add {{ ARGS }} +agent source:crush

# Sync tasks with TaskChampion server
task-sync:
    @task sync

# Show agent-tracked tasks
task-agent-list:
    @task report.agent

# Show task status (sync server + pending count)
task-status:
    @echo "📋 Taskwarrior Status"
    @echo "===================="
    @echo -n "Pending tasks: "; task count status:pending 2>/dev/null || echo "unavailable"
    @echo -n "Overdue tasks:  "; task count status:pending +OVERDUE 2>/dev/null || echo "unavailable"
    @echo -n "Due today:      "; task count status:pending due:today 2>/dev/null || echo "unavailable"
    @echo ""
    @echo "Sync configuration:"
    @task config sync.server.url 2>/dev/null || echo "  Not configured"
    @task config sync.server.client_id 2>/dev/null || echo "  Client ID: not set"
    @echo ""

# Show taskwarrior auto-configured per-device credentials
task-setup:
    @echo "📋 Taskwarrior is auto-configured per device"
    @echo "   Client ID and encryption secret derived deterministically from hostname"
    @echo ""
    @echo "Current config:"
    @echo -n "  Client ID: "; task config sync.server.client_id 2>/dev/null || echo "not set"
    @echo -n "  Sync URL:   "; task config sync.server.url 2>/dev/null || echo "not set"
    @echo -n "  Encrypted:  "; task config sync.encryption_secret 2>/dev/null && echo "yes" || echo "not set"
    @echo ""
    @echo "No manual steps required — just switch and task sync"

# Export all tasks as JSON (for backup)
task-backup:
    @echo "💾 Exporting all tasks..."
    @mkdir -p ~/backups/taskwarrior
    @task export > ~/backups/taskwarrior/tasks-$$(date '+%Y-%m-%d_%H-%M-%S').json
    @echo "✅ Tasks exported to ~/backups/taskwarrior/"

# Reload Niri compositor config without full rebuild
reload:
    niri msg action reload-config

# Deploy NixOS config to evo-x2 via nh
deploy-evo:
    @nix run .#deploy

# Run NixOS diagnostic
diagnose:
    @echo "🔍 Running NixOS diagnostics..."
    @bash scripts/nixos-diagnostic.sh

# Test shell aliases (cross-shell validation per ADR-002)
test-aliases *ARGS:
    @echo "🧪 Testing shell aliases..."
    @bash scripts/test-shell-aliases.sh {{ ARGS }}

# ========================================
# EMEET PIXY Camera Commands
# ========================================

# Show camera status (tracking, audio, position)
cam-status:
    @emeet-pixyd status 2>/dev/null || echo "EMEET PIXY daemon not running"

# Toggle camera privacy mode (click waybar icon alternative)
cam-privacy:
    @emeet-pixyd toggle-privacy 2>/dev/null || echo "EMEET PIXY daemon not running"

# Enable face tracking
cam-track:
    @emeet-pixyd track 2>/dev/null || echo "EMEET PIXY daemon not running"

# Disable face tracking
cam-idle:
    @emeet-pixyd idle 2>/dev/null || echo "EMEET PIXY daemon not running"

# Center camera (reset pan/tilt/zoom)
cam-reset:
    @emeet-pixyd center 2>/dev/null || echo "EMEET PIXY daemon not running"

# Cycle or set audio mode (no arg cycles: nc→live→org→nc)
cam-audio MODE="":
    @emeet-pixyd audio {{ MODE }} 2>/dev/null || echo "EMEET PIXY daemon not running"

# Enable gesture control
cam-gesture-on:
    @emeet-pixyd gesture-on 2>/dev/null || echo "EMEET PIXY daemon not running"

# Disable gesture control
cam-gesture-off:
    @emeet-pixyd gesture-off 2>/dev/null || echo "EMEET PIXY daemon not running"

# Sync daemon state with camera's actual HID state
cam-sync:
    @emeet-pixyd sync 2>/dev/null || echo "EMEET PIXY daemon not running"

# Restart the EMEET PIXY daemon
cam-restart:
    @systemctl --user restart emeet-pixyd && echo "EMEET PIXY daemon restarted" || echo "Failed to restart"

# Show EMEET PIXY daemon logs
cam-logs:
    @journalctl --user -u emeet-pixyd --no-pager -n 100

# Niri Session Commands

# Show niri session save status (last save time, window count, session age)
session-status:
    @STATE_DIR="$${XDG_STATE_HOME:-$$HOME/.local/state}/niri-session"; \
    if [ ! -f "$$STATE_DIR/windows.json" ]; then \
        echo "No session data found"; \
    else \
        echo "Niri Session Status"; \
        echo "==================="; \
        if [ -f "$$STATE_DIR/timestamp" ]; then \
            saved=$$(cat "$$STATE_DIR/timestamp"); \
            now=$$(date +%s); \
            age_sec=$$(( now - saved )); \
            age_min=$$(( age_sec / 60 )); \
            echo "Last save: $$(date -d @$$saved '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r $$saved '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown') ($${age_min}m ago)"; \
        fi; \
        win_count=$$(jq 'length' "$$STATE_DIR/windows.json" 2>/dev/null || echo "?"); \
        echo "Windows saved: $$win_count"; \
        kitty_count=$$(jq '[.[] | select(.app_id == "kitty")] | length' "$$STATE_DIR/windows.json" 2>/dev/null || echo "?"); \
        echo "Kitty windows: $$kitty_count"; \
        floating_count=$$(jq '[.[] | select(.is_floating == true)] | length' "$$STATE_DIR/windows.json" 2>/dev/null || echo "?"); \
        echo "Floating: $$floating_count"; \
        echo ""; \
        echo "Timer:"; \
        systemctl --user list-timers niri-session-save 2>/dev/null || echo "  Timer not active"; \
    fi

# Manually trigger niri session restore
session-restore:
    @echo "Triggering session restore..."
    @niri-session-restore

# Hermes Agent Gateway Commands

# Show hermes gateway status (connected platforms, active agents, uptime)
hermes-status:
    @echo "Hermes Gateway Status"; echo "===================="; systemctl status hermes --no-pager 2>/dev/null | head -15; echo ""; echo "State:"; cat /home/hermes/gateway_state.json 2>/dev/null | jq '{pid, gateway_state, active_agents, platforms: .platforms | to_entries | map({(.key): .value.state})}' 2>/dev/null || echo "  No state file"

# Restart hermes gateway service
hermes-restart:
    @sudo systemctl restart hermes

# Show hermes gateway logs (last 200 lines)
hermes-logs:
    @journalctl -u hermes --no-pager -n 200

# Follow hermes gateway logs (live tail)
hermes-logs-follow:
    @journalctl -u hermes -f --no-pager -n 50

# AI Models — migrate from legacy /data/{models,cache,unsloth} to /data/ai/
ai-migrate:
    @echo "=== Migrating AI data to /data/ai/ ==="
    @echo ""
    @if [ ! -d /data/ai ]; then echo "Creating /data/ai..."; sudo mkdir -p /data/ai; sudo chown lars:users /data/ai; fi
    @# Models
    @if [ -d /data/models ] && [ ! -d /data/ai/models ]; then echo "Moving /data/models → /data/ai/models..."; mv /data/models /data/ai/models; fi
    @# Cache
    @if [ -d /data/cache ] && [ ! -d /data/ai/cache ]; then echo "Moving /data/cache → /data/ai/cache..."; mv /data/cache /data/ai/cache; fi
    @# Unsloth workspace
    @if [ -d /data/unsloth ] && [ ! -d /data/ai/workspaces/unsloth ]; then echo "Moving /data/unsloth → /data/ai/workspaces/unsloth..."; mkdir -p /data/ai/workspaces; mv /data/unsloth /data/ai/workspaces/unsloth; fi
    @# Reorganize ollama if it has flat structure from old layout
    @if [ -d /data/ai/models/ollama ] && [ ! -d /data/ai/models/ollama/models ]; then echo "Creating ollama models subdirectory..."; mkdir -p /data/ai/models/ollama/models; fi
    @# Create remaining directories
    @sudo systemd-tmpfiles --create
    @echo ""
    @echo "=== Migration complete ==="
    @echo "Directory structure:"
    @ls -la /data/ai/
    @echo ""
    @echo "Models:"
    @ls /data/ai/models/ 2>/dev/null || echo "  (empty)"
    @echo ""
    @echo "Cache:"
    @ls /data/ai/cache/ 2>/dev/null || echo "  (empty)"
    @echo ""
    @echo "Workspaces:"
    @ls /data/ai/workspaces/ 2>/dev/null || echo "  (empty)"
    @echo ""
    @echo "Run 'just switch' to apply new configuration."

# AI Models — show current storage status
ai-status:
    @echo "=== AI Model Storage ==="
    @echo ""
    @BASE="/data/ai"
    @if [ ! -d "$$BASE" ]; then echo "⚠️  /data/ai does not exist yet. Run 'just ai-migrate' first."; exit 0; fi
    @echo "Directory tree:"
    @find $$BASE -maxdepth 3 -type d | head -40 | sort
    @echo ""
    @echo "Disk usage:"
    @du -sh $$BASE 2>/dev/null || echo "  (empty)"
    @for dir in $$BASE/models/*/; do \
        if [ -d "$$dir" ]; then \
            size=$$(du -sh "$$dir" 2>/dev/null | cut -f1); \
            name=$$(basename "$$dir"); \
            echo "  $$name: $$size"; \
        fi; \
    done
    @echo ""
    @echo "Environment:"
    @echo "  OLLAMA_MODELS  = $${OLLAMA_MODELS:-not set}"
    @echo "  HF_HOME        = $${HF_HOME:-not set}"
    @echo "  LLAMA_MODEL_PATH = $${LLAMA_MODEL_PATH:-not set}"

# ========================================
# Disk Monitor Commands
# ========================================

# Show disk monitor status and current usage
disk-monitor-status:
    @echo "=== Disk Monitor Status ==="
    @echo ""
    @echo "Service:"
    @systemctl is-active disk-monitor.timer 2>/dev/null || echo "  timer not found"
    @systemctl is-active disk-monitor.service 2>/dev/null || true
    @echo ""
    @echo "Monitored filesystems:"
    @for mp in / /data; do \
        if mountpoint -q "$$mp" 2>/dev/null; then \
            df -h "$$mp" | tail -1 | awk '{printf "  %-6s %s used, %s free of %s (%s)\n", ENVIRON["MOUNT"], $$5, $$4, $$2, $$6}' MOUNT="$$mp"; \
        else \
            echo "  $$mp — not mounted"; \
        fi; \
    done
    @echo ""
    @echo "Notification state:"
    @ls -la ~/.local/state/disk-monitor/ 2>/dev/null || echo "  (no active alerts)"

# Trigger a manual disk check now
disk-monitor-check:
    @systemctl start disk-monitor.service && echo "Check completed" || echo "Check failed"

# Reset disk monitor notification state (allows re-notifying)
disk-monitor-reset:
    @trash ~/.local/state/disk-monitor/* 2>/dev/null || true
    @rm -f ~/.local/state/disk-monitor/* 2>/dev/null || true
    @echo "Notification state cleared"

# Show disk monitor timer schedule
disk-monitor-schedule:
    @systemctl list-timers disk-monitor.timer --no-pager 2>/dev/null || echo "Timer not active"

# ========================================
# Rust Target Cleanup Commands
# ========================================

# Run Rust target/ cleanup manually (removes artifacts >7 days old from dirs >2GB)
rust-clean:
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" = "darwin" ]; then \
        echo "Rust target/ cleanup timer is only on NixOS"; \
    else \
        sudo systemctl start rust-target-cleanup && \
        journalctl -u rust-target-cleanup --no-pager -n 20; \
    fi

# Show Rust target/ cleanup timer status
rust-clean-status:
    @PLATFORM=$(just _detect_platform); \
    if [ "$$PLATFORM" = "darwin" ]; then \
        echo "Rust target/ cleanup timer is only on NixOS"; \
    else \
        systemctl list-timers rust-target-cleanup.timer --no-pager; \
        echo ""; \
        echo "Last run:"; \
        journalctl -u rust-target-cleanup --no-pager -n 5; \
    fi

# ========================================
# todo-list-ai Commands
# ========================================

# Extract TODOs from a directory using AI (default: mock provider)
todo-scan *ARGS="":
    @todo-list-ai {{ ARGS }}

# Extract TODOs from a directory with OpenAI
todo-scan-openai DIR="./":
    @todo-list-ai --dir {{ DIR }} --provider openai

# Extract TODOs from a directory with mock provider (no API key needed)
todo-scan-mock DIR="./":
    @todo-list-ai --dir {{ DIR }} --provider mock

# Show todo-list-ai version
todo-version:
    @todo-list-ai --version 2>/dev/null || echo "todo-list-ai not found in PATH"

# Auto-configure golangci-lint for the current project
lint-configure *ARGS="":
    @golangci-lint-auto-configure configure {{ ARGS }}

# Show golangci-lint-auto-configure version
lint-configure-version:
    @golangci-lint-auto-configure --version 2>/dev/null || echo "golangci-lint-auto-configure not found in PATH"
