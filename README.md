# Setup-Mac

A comprehensive macOS development environment using Nix Darwin, Home Manager, and declarative configuration management.

## Overview

This repository provides a complete, reproducible development environment for macOS with:

- **Nix Darwin**: Declarative system configuration and package management
- **Home Manager**: User-specific configurations and dotfiles
- **Go Development Stack**: Complete Go toolchain with templ, sqlc, and modern tools
- **Cloud & Kubernetes Tools**: AWS, GCP, kubectl, Helm, Terraform, and more
- **Homebrew Integration**: Managed through nix-homebrew for GUI applications
- **Security Tools**: Gitleaks, Little Snitch, Lulu, age encryption
- **Performance Tools**: Hyperfine, htop, ncdu, and system monitoring

## Quick Start

### Prerequisites

- macOS (Apple Silicon or Intel)
- Xcode Command Line Tools: `xcode-select --install`
- Administrative access

### Installation

1. **Install Nix (Determinate Systems installer recommended):**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone and apply configuration:**
   ```bash
   git clone https://github.com/LarsArtmann/Setup-Mac.git ~/Desktop/Setup-Mac
   cd ~/Desktop/Setup-Mac/dotfiles/nix
   darwin-rebuild switch --flake .#Lars-MacBook-Air
   ```

3. **Restart your terminal** to load new environment.

### What You Get

After installation, you'll have access to 100+ development tools including:

**Languages & Runtimes:**
- Go (with templ, sqlc, go-tools)
- Node.js, Bun, pnpm
- Java (JDK 21), Kotlin
- .NET Core SDK, Ruby, Rust
- Python utilities (uv)

**Cloud & DevOps:**
- AWS CLI, Google Cloud SDK
- Kubernetes (kubectl, k9s, Helm)
- Terraform, Docker Buildx
- Infrastructure tools

**Development:**
- Git + GitHub CLI + Git Town
- JetBrains Toolbox
- VS Code, Sublime Text
- Database tools (Redis, Turso)

See the [complete setup guide](./docs/development/setup.md) for details.

## Managing Your Configuration

### Adding New Tools

**Nix packages** (preferred for CLI tools):
```bash
# Edit dotfiles/nix/environment.nix
systemPackages = with pkgs; [
  your-new-package
];
```

**Homebrew packages** (for GUI apps):
```bash
# Edit dotfiles/nix/homebrew.nix
casks = [
  "your-gui-app"
];
```

### Shell Aliases and Environment

Shell aliases are defined in `dotfiles/nix/environment.nix`:
```nix
shellAliases = {
  your-alias = "your-command";
};
```

### Updating the System

```bash
cd ~/Desktop/Setup-Mac/dotfiles/nix

# Update package sources
nix flake update

# Apply updates
darwin-rebuild switch --flake .#Lars-MacBook-Air

# Or use the alias
nixup
```

### Rollback Changes

```bash
# Rollback to previous generation
sudo darwin-rebuild rollback

# List available generations
darwin-rebuild --list-generations
```

## Security & Quality

### Pre-commit Hooks

Installed automatically with the configuration:
- **Gitleaks**: Prevents committing secrets and API keys
- **Code quality**: Trailing whitespace, file endings, YAML validation
- **Security**: Detection of private keys and large files

### Security Tools

- **Little Snitch**: Network connection monitoring
- **Lulu**: Outgoing connection firewall
- **Secretive**: SSH key management in Secure Enclave
- **Age**: Modern file encryption
- **MacPass**: Password management

## Repository Structure

```
Setup-Mac/
├── docs/
│   ├── development/
│   │   └── setup.md              # Complete setup guide
│   └── troubleshooting/
│       ├── README.md             # Quick troubleshooting reference
│       └── common-issues.md      # Detailed issue solutions
├── dotfiles/
│   ├── .bashrc, .zshrc           # Shell configurations
│   └── nix/                      # Nix configuration files
│       ├── flake.nix             # Main flake entry point
│       ├── environment.nix       # Packages and environment
│       ├── homebrew.nix          # GUI apps via Homebrew
│       ├── home.nix              # Home Manager config
│       ├── core.nix, system.nix  # System settings
│       └── *.nix                 # Other configurations
├── better-claude-go/             # Claude configuration tool
└── justfile                      # Task runner commands
```

## Documentation

- **[Setup Guide](./docs/development/setup.md)** - Complete installation and configuration guide
- **[Troubleshooting](./docs/troubleshooting/README.md)** - Common issues and solutions
- **[Better Claude Tool](./better-claude-go/README.md)** - Claude configuration management

## Features

- ✅ **Declarative Configuration**: Everything managed through Nix
- ✅ **Home Manager Integration**: User-specific configurations
- ✅ **Go Development Stack**: Complete toolchain with modern tools
- ✅ **Cloud & Kubernetes Ready**: AWS, GCP, kubectl, Helm, Terraform
- ✅ **Security Focused**: Gitleaks, encryption, network monitoring
- ✅ **Performance Monitoring**: Built-in system analysis tools
- ✅ **Homebrew Integration**: GUI apps managed declaratively
- ✅ **Comprehensive Documentation**: Setup and troubleshooting guides

## Maintenance

The configuration is designed to be:
- **Self-documenting**: Clear structure and comments
- **Version controlled**: All changes tracked in Git
- **Rollback capable**: Easy to revert problematic changes
- **Update friendly**: Simple commands to keep everything current

Regular maintenance:
```bash
# Weekly: Update and cleanup
nix flake update && nixup
nix-collect-garbage -d

# Check system health
nix doctor
```

## 🏗️ Architecture Overview

This configuration uses a **type-safe, modular architecture** with the following components:

### Core Type Safety System
- **`core/Types.nix`**: Strong type definitions for all configurations
- **`core/State.nix`**: Centralized single source of truth for paths and state
- **`core/Validation.nix`**: Configuration validation and error prevention
- **`core/TypeSafetySystem.nix`**: Unified type safety enforcement

### Configuration Modules
- **`environment.nix`**: Environment variables, shell aliases, and PATH configuration
- **`programs.nix`**: User program configurations (shells, editors, tools)
- **`system.nix`**: macOS defaults and system settings
- **`core.nix`**: Core packages, security configurations, and system services

### Build System
- **`flake.nix`**: Nix flake for reproducible builds
- **`justfile`**: Task runner with comprehensive commands
- **`home.nix`**: Home Manager configuration entry point

### Type Safety Features
- **Compile-time validation**: All types checked at evaluation time
- **Zero runtime errors**: Type system prevents configuration errors
- **Centralized state**: Single source of truth eliminates inconsistencies
- **Comprehensive testing**: Built-in validation and assertion framework


## 🚀 Development Workflow

### Using Just Commands
The project uses **Just** as a task runner for all operations:

```bash
# Core commands
just setup          # Complete fresh installation
just switch         # Apply Nix configuration
just build          # Build without applying
just test           # Run all tests
just clean          # Clean build artifacts

# Development commands
just dev-setup      # Development environment setup
just docs           # Generate documentation
just update         # Update all packages

# Maintenance commands
just backup         # Backup configurations
just restore        # Restore from backup
just health         # System health check
```

### Configuration Changes Workflow
1. **Edit configuration files** in `dotfiles/nix/`
2. **Validate with type safety**: `just type-check`
3. **Apply changes**: `just switch`
4. **Test functionality**: `just test`

### Type Safety Development
- **All configurations use strong types** from `core/Types.nix`
- **Automatic validation** prevents runtime errors
- **Compile-time type checking** ensures correctness
- **Centralized state** eliminates inconsistencies


## 🛠️ Troubleshooting

### Common Issues & Solutions

#### GPG Signing Not Working
**Problem**: `gpg: command not found` or signing fails
**Solution**:
```bash
# Install GPG via nix
nix profile add nixpkgs#gnupg

# Update gitconfig GPG path
# Path should be: /Users/$USER/.nix-profile/bin/gpg
```

#### Build Errors
**Problem**: `evaluation warning` or build failures
**Solution**:
```bash
# Check configuration type safety
just type-check

# Clean and rebuild
just clean && just switch

# Check for deprecation warnings
just build | grep -i warning
```

#### Package Not Found
**Problem**: `error: package 'xyz' not found`
**Solution**:
```bash
# Search nixpkgs
nix search nixpkgs xyz

# Check available packages
nix-env -qaP | grep xyz
```

#### Path Issues
**Problem**: Configuration file not found errors
**Solution**:
```bash
# Verify path resolution
just debug-paths

# Check centralized state
cat dotfiles/nix/core/State.nix
```

### Getting Help
- **Check issues**: [GitHub Issues](https://github.com/LarsArtmann/Setup-Mac/issues)
- **Review documentation**: [Development Guide](./docs/development/setup.md)
- **Run diagnostics**: `just health`

