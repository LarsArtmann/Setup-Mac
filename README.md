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
