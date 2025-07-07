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
    nh darwin switch ./dotfiles/nix/
    @echo "✅ Nix configuration applied"

# Update system and packages
update:
    @echo "📦 Updating system packages..."
    @echo "Updating Nix flake..."
    cd dotfiles/nix && nix flake update
    @echo "✅ System updated"

# Clean up caches and old packages
clean:
    @echo "🧹 Cleaning up system..."
    @echo "Cleaning Nix generations that are older than 1 days..."
    sudo nix-collect-garbage --delete-older-than 1d
    @echo "Cleaning Nix store..."
    nix-store --gc
    @echo "Cleaning Homebrew..."
    brew autoremove
    brew cleanup --prune=all -s
    @echo "Cleaning npm cache..."
    npm cache clean --force || true
    @echo "Cleaning pnpm store..."
    pnpm store prune || true
    @echo "Cleaning go caches..."
    go clean -cache -testcache -modcache
    @echo "✅ Cleanup complete"

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
    
    # Backup entire dotfiles directory
    cp -r dotfiles "$BACKUP_DIR/"
    
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
    @echo "🔄 Restoring from backup: {{BACKUP_NAME}}"
    #!/usr/bin/env bash
    BACKUP_PATH="backups/{{BACKUP_NAME}}"
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
    darwin-rebuild check --flake ./dotfiles/nix/
    @echo "✅ Configuration test passed"

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

# Benchmark shell startup performance
benchmark:
    @echo "🏃 Benchmarking shell startup performance..."
    @echo "Testing zsh startup time (10 runs):"
    hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
    @echo ""
    @echo "Testing bash startup time for comparison:"
    hyperfine --warmup 3 --runs 10 'bash -i -c exit'
    @echo "✅ Benchmark complete"

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
    @echo "  health         - Health check for shell and dev environment"
    @echo ""
    @echo "Maintenance:"
    @echo "  check          - Check system status and outdated packages"
    @echo "  backup         - Create configuration backup"
    @echo "  list-backups   - List available backups"
    @echo "  restore        - Restore from backup (usage: just restore BACKUP_NAME)"
    @echo "  clean-backups  - Clean old backups (keep last 10)"
    @echo "  deep-clean     - Perform thorough cleanup"
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
    @echo "  link           - Link dotfiles manually"
    @echo "  ssh-setup      - Create SSH directories"
    @echo "  rollback       - Emergency rollback to previous generation"
    @echo ""
    @echo "Run 'just <command>' to execute any task."
