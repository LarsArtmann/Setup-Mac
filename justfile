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
    
    # Backup Nix configuration
    cp -r dotfiles/nix "$BACKUP_DIR/"
    
    # Backup key dotfiles
    cp dotfiles/.gitconfig "$BACKUP_DIR/" || true
    cp dotfiles/.zshrc "$BACKUP_DIR/" || true
    cp dotfiles/.bashrc "$BACKUP_DIR/" || true
    
    # Create backup info
    echo "Backup created: $(date)" > "$BACKUP_DIR/backup_info.txt"
    echo "Git commit: $(git rev-parse HEAD)" >> "$BACKUP_DIR/backup_info.txt"
    echo "System: $(uname -a)" >> "$BACKUP_DIR/backup_info.txt"
    
    echo "✅ Backup created in $BACKUP_DIR"

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
    @echo ""
    @echo "Maintenance:"
    @echo "  check          - Check system status and outdated packages"
    @echo "  backup         - Create configuration backup"
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
