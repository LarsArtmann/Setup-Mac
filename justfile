# Setup-Mac Justfile
# Task runner for macOS configuration management

# Default recipe to display help
default:
    @just --list

# Initial system setup - run this after cloning the repository
setup:
    @echo "🚀 Setting up macOS configuration..."
    @just ssh-setup
    @just link
    @just switch
    @just pre-commit-install
    @echo "✅ Setup complete! Your macOS configuration is ready."

# Create SSH directories (manual work mentioned in README)
ssh-setup:
    @echo "📁 Creating SSH directories..."
    mkdir -p ~/.ssh/sockets
    @echo "✅ SSH directories created"

# Link configuration files using the manual linking script
link:
    @echo "🔗 Linking dotfiles..."
    ./manual-linking.sh
    @echo "✅ Dotfiles linked"

# Apply Nix configuration changes (equivalent to nixup alias)
switch:
    @echo "🔄 Applying Nix configuration..."
    sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ./
    @echo "✅ Nix configuration applied"

# Update system and packages
update:
    @echo "📦 Updating system packages..."
    @echo "Updating Nix flake..."
    nix flake update
    @echo "✅ System updated"

# ActivityWatch Nix-managed auto-start configuration
activitywatch-setup:
    @echo "⚙️  Setting up ActivityWatch auto-start via Nix..."
    ./scripts/nix-activitywatch-setup.sh
    @echo "✅ ActivityWatch auto-start configured via Nix"

# Verify ActivityWatch auto-start is working
activitywatch-check:
    @echo "🔍 Checking ActivityWatch auto-start status..."
    @./scripts/nix-activitywatch-setup.sh --check

# Remove manual ActivityWatch configuration (migrate to Nix)
activitywatch-migrate:
    @echo "🔄 Migrating ActivityWatch to Nix management..."
    @./scripts/nix-activitywatch-setup.sh --cleanup
    @echo "Applying Nix-managed configuration..."
    @just activitywatch-setup
    @echo "✅ Migration complete"

# ActivityWatch commands
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

# Clean up caches and old packages (comprehensive cleanup)
clean:
    @echo "🧹 Starting comprehensive system cleanup..."
    @echo ""
    @echo "=== Nix Store Cleanup ==="
    @echo "📊 Current store size:"
    @du -sh /nix/store || echo "Could not measure store size"
    @echo "🗑️  Cleaning Nix generations older than 1 day..."
    @echo "  Note: Use 'sudo -S' if password prompt appears"
    nix-collect-garbage -d --delete-older-than 1d || sudo -S nix-collect-garbage -d --delete-older-than 1d
    @echo "⚡ Optimizing Nix store (deduplicating files)..."
    @echo "  This may take several minutes for large stores..."
    nix-store --optimize || sudo -S nix-store --optimize
    @echo "🧹 Cleaning user Nix profiles..."
    nix profile wipe-history --profile /Users/$(whoami)/.local/state/nix/profiles/profile || true
    @echo ""
    @echo "=== Package Manager Cleanup ==="
    @echo "🍺 Cleaning Homebrew..."
    brew autoremove || echo "  ⚠️  Homebrew autoremove failed or not needed"
    brew cleanup --prune=all -s || echo "  ⚠️  Homebrew cleanup failed"
    @echo "📦 Cleaning npm/pnpm caches..."
    npm cache clean --force || echo "  ⚠️  npm cache clean failed (npm not installed?)"
    pnpm store prune || echo "  ⚠️  pnpm store prune failed (pnpm not installed?)"
    @echo "🐹 Cleaning Go caches..."
    go clean -cache -testcache -modcache || echo "  ⚠️  Go cache clean failed (Go not installed?)"
    @echo "🗑️  Cleaning Go build cache folders..."
    find /private/var/folders/07/y9f_lh8s1zq2kr67_k94w22h0000gn/T -name "go-build*" -type d -print0 | xargs -0 trash 2>/dev/null || echo "  ⚠️  Go build cache folders not found or couldn't be removed"
    @echo "🦀 Cleaning Rust/Cargo cache..."
    cargo cache --autoclean || echo "  ⚠️  Cargo cache clean failed (cargo-cache not installed?)"
    @echo "🔧 Cleaning build caches..."
    rm -rf ~/.bun/install/cache || echo "  ⚠️  Bun cache not found"
    rm -rf ~/.gradle/caches/* || echo "  ⚠️  Gradle cache not found"
    rm -rf ~/.cache/puppeteer || echo "  ⚠️  Puppeteer cache not found"
    rm -rf ~/.nuget/packages || echo "  ⚠️  NuGet cache not found"
    @echo ""
    @echo "=== System Cache Cleanup ==="
    @echo "🔦 Cleaning Spotlight metadata..."
    [ -d ~/Library/Metadata/CoreSpotlight/SpotlightKnowledgeEvents ] && rm -r ~/Library/Metadata/CoreSpotlight/SpotlightKnowledgeEvents || echo "  ⚠️  Spotlight metadata not found"
    @echo "🗂️  Cleaning system temp files..."
    rm -rf /tmp/nix-build-* || echo "  ⚠️  No nix-build temp files found"
    rm -rf /tmp/nix-shell-* || echo "  ⚠️  No nix-shell temp files found"
    @echo "📱 Cleaning iOS simulators (if Xcode installed)..."
    xcrun simctl delete unavailable 2>/dev/null || echo "  ⚠️  Xcode/simulators not found or no unavailable simulators"
    @echo "🐳 Cleaning Docker (if installed)..."
    docker system prune -af 2>/dev/null || echo "  ⚠️  Docker not installed or no containers to clean"
    @echo ""
    @echo "=== Final Results ==="
    @echo "📊 New store size:"
    @du -sh /nix/store || echo "Could not measure store size"
    @echo "💽 Free disk space:"
    @df -h / | tail -1 | awk '{print "  Available: " $4 " of " $2 " (" $5 " used)"}'
    @echo ""
    @echo "✅ Comprehensive cleanup complete!"
    @echo "💡 Tip: Run 'just clean-aggressive' for nuclear cleanup options"

# Quick daily cleanup (fast, safe, no store optimization)
clean-quick:
    @echo "🚀 Quick daily cleanup..."
    @echo "🍺 Cleaning Homebrew..."
    brew autoremove && brew cleanup || echo "  ⚠️  Homebrew cleanup failed"
    @echo "📦 Cleaning package managers..."
    npm cache clean --force || echo "  ⚠️  npm not available"
    pnpm store prune || echo "  ⚠️  pnpm not available"
    go clean -cache || echo "  ⚠️  Go not available"
    @echo "🗂️  Cleaning temp files..."
    rm -rf /tmp/nix-build-* /tmp/nix-shell-* || echo "  ⚠️  No temp files found"
    @echo "🐳 Cleaning Docker (light)..."
    docker system prune -f 2>/dev/null || echo "  ⚠️  Docker not available"
    @echo "✅ Quick cleanup done! (No Nix store changes)"

# Aggressive cleanup - removes more data but might need reinstalls
clean-aggressive:
    @echo "⚠️  AGGRESSIVE CLEANUP MODE - This will remove more data!"
    @echo "📋 This will clean:"
    @echo "  - All Nix generations (not just 1+ days old)"
    @echo "  - All user Nix profiles"
    @echo "  - All language version managers"
    @echo "  - All development caches"
    @echo "  - Docker images and containers"
    @echo "  - iOS simulators and Xcode derived data"
    @echo ""
    @echo "🚨 Some tools may need reinstalling after this!"
    @echo "Continue? (Ctrl+C to abort, Enter to proceed)"
    @read
    @echo ""
    @echo "🧹 Starting aggressive cleanup..."
    @echo ""
    @echo "=== Nix Nuclear Option ==="
    nix-collect-garbage -d || sudo -S nix-collect-garbage -d
    nix profile wipe-history || true
    nix-store --optimize || sudo -S nix-store --optimize
    @echo ""
    @echo "=== Language Managers ==="
    @echo "🟢 Cleaning Node.js versions..."
    rm -rf ~/.nvm/versions/node/* || true
    @echo "🐍 Cleaning Python versions..."
    rm -rf ~/.pyenv/versions/* || true
    @echo "💎 Cleaning Ruby versions..."
    rm -rf ~/.rbenv/versions/* || true
    @echo ""
    @echo "=== Development Caches ==="
    @echo "🏗️  Cleaning all build caches..."
    rm -rf ~/.cache || true && mkdir -p ~/.cache
    rm -rf ~/Library/Caches/CocoaPods || true
    rm -rf ~/Library/Caches/Homebrew || true
    rm -rf ~/Library/Developer/Xcode/DerivedData || true
    @echo "🐳 Removing all Docker data..."
    docker system prune -af --volumes 2>/dev/null || true
    @echo "📱 Removing all iOS simulators..."
    xcrun simctl delete all 2>/dev/null || true
    @echo ""
    @echo "=== Final Optimization ==="
    @echo "📊 Final store size:"
    @du -sh /nix/store || echo "Could not measure"
    @echo "💾 Disk space recovered:"
    @df -h / | tail -1 | awk '{print "  " $4 " available of " $2}'
    @echo ""
    @echo "✅ Aggressive cleanup complete!"
    @echo "⚡ You may need to reinstall some development tools"

# Deep clean using the paths from your cleanup file
deep-clean:
    @echo "🧹 Performing deep cleanup..."
    @echo "Cleaning build caches..."
    rm -rf ~/.bun/install/cache || true
    rm -rf ~/.gradle/caches/* || true
    rm -rf ~/.cache/puppeteer || true
    rm -rf ~/.nuget/packages || true
    rm -rf ~/Library/Caches/lima || true
    @echo "Running standard cleanup..."
    @just clean
    @echo "✅ Deep cleanup complete"

# Check system status and outdated packages
check:
    @echo "🔍 Checking system status..."
    @echo "=== Nix System Info ==="
    darwin-version
    @echo "\n=== Homebrew Status ==="
    brew doctor || true
    @echo "\n=== Outdated Homebrew Packages ==="
    brew outdated || echo "All Homebrew packages are up to date"
    @echo "\n=== Git Status ==="
    git status --porcelain || true
    @echo "✅ System check complete"

# Fast Nix syntax validation
check-nix-syntax:
    @echo "🔍 Checking Nix syntax..."
    nix-instantiate --eval --show-trace platforms/darwin/default.nix
    nix-instantiate --eval --show-trace platforms/darwin/home.nix
    nix-instantiate --eval --show-trace platforms/nixos/users/home.nix
    nix-instantiate --eval --show-trace platforms/common/home-base.nix
    @echo "✅ Nix syntax validation complete"

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

    # Backup justfile and manual-linking script
    cp justfile "$BACKUP_DIR/" || true
    cp manual-linking.sh "$BACKUP_DIR/" || true

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

    if [ -f "$BACKUP_PATH/manual-linking.sh" ]; then
    echo "Restoring manual-linking.sh..."
    cp "$BACKUP_PATH/manual-linking.sh" .
    fi

    echo "✅ Restore complete. Run 'just link' and 'just switch' to apply changes."
    echo "💡 Original state backed up automatically before restore."

# Clean old backups (keep last 10)
clean-backups:
    @echo "🧹 Cleaning old backups (keeping last 10)..."
    #!/usr/bin/env bash
    cd backups 2>/dev/null || exit 0
    ls -1t | tail -n +11 | xargs rm -rf
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
    @echo "macOS Version: $(sw_vers -productVersion)"
    @echo "Nix Version: $(nix --version)"
    @echo "Darwin Rebuild: $(darwin-version)"
    @echo "Homebrew Version: $(brew --version | head -1)"
    @echo "Git Version: $(git --version)"
    @echo "Shell: $SHELL"
    @echo "Current Directory: $(pwd)"

# Test configuration without applying changes
test:
    @echo "🧪 Testing Nix configuration..."
    sudo /run/current-system/sw/bin/darwin-rebuild check --flake ./
    @echo "✅ Configuration test passed"

# Fast test - syntax validation only (skips heavy packages)
test-fast:
    @echo "🚀 Fast testing Nix configuration (syntax only)..."
    nix --extra-experimental-features "nix-command flakes" flake check --no-build
    @echo "✅ Fast configuration test passed"

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

# Emergency rollback to previous generation
rollback:
    @echo "⚠️  Rolling back to previous generation..."
    darwin-rebuild rollback
    @echo "✅ Rollback complete"

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

# Benchmark shell startup performance (legacy)
benchmark:
    @echo "🏃 Benchmarking shell startup performance..."
    @echo "Testing zsh startup time (10 runs):"
    hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
    @echo ""
    @echo "Testing bash startup time for comparison:"
    hyperfine --warmup 3 --runs 10 'bash -i -c exit'
    @echo "✅ Benchmark complete"

# Comprehensive system performance benchmarks
benchmark-all:
    @echo "🚀 Running comprehensive system benchmarks..."
    ./scripts/benchmark-system.sh
    @echo "✅ All benchmarks complete"

# Benchmark shell startup only
benchmark-shells:
    @echo "🐚 Benchmarking shell startup performance..."
    ./scripts/benchmark-system.sh --shells
    @echo "✅ Shell benchmarks complete"

# Benchmark build tools performance
benchmark-build:
    @echo "🔨 Benchmarking build tools performance..."
    ./scripts/benchmark-system.sh --build-tools
    @echo "✅ Build tool benchmarks complete"

# Benchmark system commands
benchmark-system:
    @echo "⚙️  Benchmarking system commands..."
    ./scripts/benchmark-system.sh --system
    @echo "✅ System command benchmarks complete"

# Benchmark file operations
benchmark-files:
    @echo "📁 Benchmarking file operations..."
    ./scripts/benchmark-system.sh --file-ops
    @echo "✅ File operation benchmarks complete"

# Show benchmark performance report
benchmark-report:
    @echo "📊 Generating performance report..."
    ./scripts/benchmark-system.sh --report
    @echo "✅ Report generated"

# Clean old benchmark results
benchmark-clean:
    @echo "🧹 Cleaning old benchmark results..."
    ./scripts/benchmark-system.sh --cleanup
    @echo "✅ Benchmark cleanup complete"

# Performance Monitoring
# ======================

# Setup performance monitoring system
perf-setup:
    @echo "🔧 Setting up performance monitoring..."
    ./scripts/performance-monitor.sh setup-monitoring
    @echo "✅ Performance monitoring setup complete"

# Run performance monitoring benchmark
perf-benchmark:
    @echo "📊 Running performance monitoring benchmark..."
    ./scripts/performance-monitor.sh benchmark-all
    @echo "✅ Performance benchmark complete"

# Generate performance report
perf-report DAYS="7":
    @echo "📈 Generating performance report ({{ DAYS }} days)..."
    ./scripts/performance-monitor.sh report {{ DAYS }}
    @echo "✅ Performance report generated"

# Show performance alerts
perf-alerts:
    @echo "🚨 Showing performance alerts..."
    ./scripts/performance-monitor.sh alerts
    @echo "✅ Alerts displayed"

# Clear performance cache
perf-cache-clear PATTERN="*":
    @echo "🧹 Clearing performance cache..."
    ./scripts/performance-monitor.sh cache-clear {{ PATTERN }}
    @echo "✅ Performance cache cleared"

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

# Detect current shell context
context-detect:
    @echo "🔍 Detecting current shell context..."
    ./scripts/shell-context-detector.sh detect
    @echo "✅ Context detection complete"

# Log current shell session for analysis
context-log:
    @echo "📝 Logging current shell session..."
    ./scripts/shell-context-detector.sh log
    @echo "✅ Session logged"

# Analyze shell usage patterns
context-analyze:
    @echo "📊 Analyzing shell usage patterns..."
    ./scripts/shell-context-detector.sh analyze
    @echo "✅ Analysis complete"

# Get loading optimization recommendations
context-recommend:
    @echo "💡 Generating loading recommendations..."
    ./scripts/shell-context-detector.sh recommend
    @echo "✅ Recommendations generated"

# Create context-aware loading hook
context-setup:
    @echo "🔧 Creating context-aware loading hook..."
    ./scripts/shell-context-detector.sh create-hook
    @echo "✅ Context-aware loading hook created"

# Comprehensive Performance Analysis
# ==================================

# Run full performance analysis
perf-full-analysis:
    @echo "🚀 Running comprehensive performance analysis..."
    @just benchmark-all
    @just perf-benchmark
    @just context-analyze
    @just context-recommend
    @just perf-report
    @echo "✅ Full performance analysis complete"

# Setup all automation systems
automation-setup:
    @echo "🤖 Setting up all automation systems..."
    @just perf-setup
    @just context-setup
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
    @echo -n "Zsh completions: "
    @if zsh -c 'autoload -Uz compinit && echo "✅ Working"' 2>/dev/null; then echo "✅ Working"; else echo "❌ Broken"; fi
    @echo -n "Git completions: "
    @if zsh -c 'autoload -Uz _git && echo "✅ Working"' 2>/dev/null; then echo "✅ Working"; else echo "❌ Missing"; fi
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
    @echo ""
    @echo "=== Dotfile Links ==="
    @echo -n ".zshrc link: "
    @if [ -L ~/.zshrc ]; then echo "✅ Linked to $(readlink ~/.zshrc)"; else echo "❌ Not linked"; fi
    @echo -n "Starship config: "
    @if [ -f ~/.config/starship.toml ]; then echo "✅ Present"; else echo "❌ Missing"; fi
    @echo -n "Git config: "
    @if [ -L ~/.gitconfig ]; then echo "✅ Linked"; else echo "❌ Not linked"; fi
    @echo ""
    @echo "=== Shell Startup Test ==="
    @echo -n "Zsh startup errors: "
    @if zsh -i -c 'exit' 2>&1 | grep -q "error\|Error\|ERROR\|WARN"; then echo "❌ Has errors/warnings"; else echo "✅ Clean startup"; fi
    @echo ""
    @echo "✅ Health check complete"

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
    @echo "🔄 Manually updating Go development tools..."
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    go install mvdan.cc/gofumpt@latest
    go install golang.org/x/tools/gopls@latest
    go install github.com/cweill/gotests/gotests@latest
    go install github.com/google/wire/cmd/wire@latest
    go install go.uber.org/mock/mockgen@latest
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go install github.com/bufbuild/buf/cmd/buf@latest
    go install github.com/go-delve/delve/cmd/dlv@latest
    go install github.com/nao1215/gup@latest
    @echo "✅ Go tools updated manually"

# Complete Go setup - install core tools and export config
go-setup:
    @echo "🛠️  Setting up complete Go development environment..."
    @just go-update-tools-manual
    @just go-export-config
    @echo "✅ Go development environment setup complete"

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
    @echo "Setup-Mac Task Runner"
    @echo "===================="
    @echo ""
    @echo "Main Commands:"
    @echo "  setup          - Complete initial setup (run after cloning)"
    @echo "  switch         - Apply Nix configuration changes"
    @echo "  update         - Update all packages and system"
    @echo "  clean          - Clean up caches and old packages"
    @echo ""
    @echo "Development:"
    @echo "  format         - Format code with treefmt"
    @echo "  test           - Test configuration without applying"
    @echo "  dev            - Run development workflow (format, check, test)"
    @echo "  benchmark      - Benchmark shell startup performance"
    @echo "  debug          - Debug shell startup with verbose logging"
    @echo "  health         - Health check for shell and dev environment"
    @echo "  health-dashboard - Comprehensive system health dashboard"
    @echo ""
    @echo "Go Development Tools:"
    @echo "  go-lint               - Run golangci-lint on Go code"
    @echo "  go-format             - Format Go code with gofumpt"
    @echo "  go-gen-tests          - Generate Go tests with gotests"
    @echo "  go-gen-mocks          - Generate Go mocks with mockgen"
    @echo "  go-wire               - Generate wire dependency injection"
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
    @echo "  go-update-tools-manual - Update tools manually with go install"
    @echo "  go-setup              - Complete Go development environment setup"
    @echo "  go-tools-version      - Show versions of all Go tools"
    @echo ""
    @echo "Maintenance:"
    @echo "  check          - Check system status and outdated packages"
    @echo "  backup         - Create configuration backup"
    @echo "  list-backups   - List available backups"
    @echo "  restore        - Restore from backup (usage: just restore BACKUP_NAME)"
    @echo "  clean-backups  - Clean old backups (keep last 10)"
    @echo "  rebuild-completions - Rebuild zsh completion cache"
    @echo "  deep-clean     - Perform thorough cleanup"
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
    @echo "  link           - Link dotfiles manually"
    @echo "  ssh-setup      - Create SSH directories"
    @echo "  rollback       - Emergency rollback to previous generation"
    @echo ""
    @echo "Run 'just <command>' to execute any task."

# Wrapper Management Commands
# =========================

# Validate wrapper syntax and structure
validate-wrappers:
    @echo "🔍 Validating wrapper syntax..."
    @./scripts/validate-wrappers.sh

# Test wrapper functionality and integration
test-wrappers:
    @echo "🧪 Testing wrapper functionality..."
    @./scripts/test-wrappers.sh

# List all available wrappers
list-wrappers:
    @echo "📋 Listing available wrappers..."
    @./scripts/list-wrappers.sh

# Migrate traditional dotfiles to wrapper system
migrate-to-wrappers:
    @echo "🔄 Migrating to wrapper system..."
    @./scripts/migrate-to-wrappers.sh

# Deployment verification for wrapper system
deployment-verify:
    @echo "✅ Verifying wrapper deployment..."
    @./scripts/deployment-verify.sh

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
    @echo "🚀 Starting Setup-Mac development session..."
    tmux has-session -t Setup-Mac && tmux attach-session -t Setup-Mac || \
    tmux new-session -d -s Setup-Mac -n just "cd ~/Desktop/Setup-Mac && just" \; \
                   new-window -d -n nvim "cd ~/Desktop/Setup-Mac && nvim" \; \
                   new-window -d -n shell "cd ~/Desktop/Setup-Mac" \; \
                   select-window -t 0
    tmux attach-session -t Setup-Mac

tmux-attach:
    @echo "📋 Attaching to Setup-Mac session..."
    tmux attach-session -t Setup-Mac || tmux new-session -s Setup-Mac

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
