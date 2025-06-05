# Setup-Mac

A comprehensive macOS setup and configuration management repository using Nix, nix-darwin, and dotfiles.

## Overview

This repository contains:

- **Dotfiles**: Configuration files for various tools and applications
- **Nix Configuration**: Declarative system configuration using nix-darwin
- **Homebrew Integration**: Managed through nix-homebrew
- **Pre-commit Hooks**: Ensuring code quality and security

## Getting Started

### Prerequisites

1. Install Nix:
   ```sh
   curl -L https://nixos.org/nix/install | sh
   ```

2. Install nix-darwin:
   ```sh
   nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
   ./result/bin/darwin-installer
   ```
#### !!! MANUAL work (currently) !!!
```bash
mkdir -p ~/.ssh/sockets
```

### Setup

1. Clone this repository:
   ```sh
   git clone https://github.com/LarsArtmann/Setup-Mac.git ~/Desktop/Setup-Mac
   cd ~/Desktop/Setup-Mac
   ```

2. Link configuration files:
   ```sh
   ./manual-linking.sh
   ```

3. Apply Nix configuration:
   See [Applying Changes](#applying-changes) section below.

## Managing Your Configuration

### Adding New Shell Aliases

Edit `dotfiles/nix/environment.nix` and add your aliases to the `shellAliases` section.

### Installing New Packages

- **Nix Packages**: Add to the `systemPackages` list in `dotfiles/nix/environment.nix`
- **Homebrew Packages**: Add to the appropriate section in `dotfiles/nix/homebrew.nix`
- **JetBrains IDEs with Plugins**: Configure in `dotfiles/nix/jetbrains.nix`

Note: Always prefer nix packages over Homebrew packages when possible.

### Applying Changes

After making changes to your configuration files, run:

First time:

```sh
nix shell github:viperML/nh/master
nh darwin switch ./dotfiles/nix/
```

Afterwards:

```sh
nixup
```

## Pre-commit Hooks

This repository uses pre-commit hooks to ensure code quality and prevent secrets from being committed.

### Setup

1. Install the hooks in your local repository:
   ```sh
   pre-commit install
   ```

### Included Hooks

- **Git Secret Leak Detection**: Using Gitleaks to prevent accidental commit of secrets
- **Code Quality Checks**: Trailing whitespace, file endings, YAML validation, etc.
- **Security Checks**: Detection of private keys and large files

## Repository Structure

- **dotfiles/**: Configuration files that get symlinked to your home directory
  - **.zshrc, .bashrc, etc.**: Shell configuration files
  - **nix/**: Nix configuration files
    - **flake.nix**: Main Nix configuration entry point
    - **environment.nix**: Environment variables and packages
    - **homebrew.nix**: Homebrew packages and configuration
    - **jetbrains.nix**: JetBrains IDEs with declarative plugin management
    - **core.nix, system.nix, etc.**: Other system configuration files
- **manual-linking.sh**: Script to create symbolic links for dotfiles

## JetBrains IDE Configuration

This setup includes declarative configuration for JetBrains IDEs with plugin management through [nix-jetbrains-plugins](https://github.com/theCapypara/nix-jetbrains-plugins).

### Included IDEs and Plugins

The configuration in `dotfiles/nix/jetbrains.nix` includes:

- **IntelliJ IDEA Ultimate** with common development plugins
- **WebStorm** with common web development plugins  

Additional IDEs (GoLand, Rider) are available but commented out to reduce initial download size.

### Common Plugins Included

- File Watcher - Monitor file changes and run tasks automatically
- .ignore - Enhanced support for .gitignore and other ignore files
- GitHub integration - Enhanced Git/GitHub support (if not built-in)

### Customizing JetBrains Setup

To add or remove IDEs or plugins, edit `dotfiles/nix/jetbrains.nix`. 

**Finding Plugin IDs**: Plugin IDs can be found at the bottom of JetBrains Marketplace pages.
Example: Visit https://plugins.jetbrains.com/plugin/7374-gitignore and scroll to bottom to find ID: `mobi.hsz.idea.gitignore`

**Adding More IDEs**: Uncomment the additional IDE configurations in `jetbrains.nix` as needed.

## TODOs

- [x] Create a backup/restore mechanism (implemented in update-system.sh)
- [x] Add a unified update command (implemented as update-system.sh)
- [x] Add a script to check for outdated packages (implemented as check-outdated.sh)
- [ ] Check out all configs in ~/.config folder
- [ ] Implement Home Manager for better dotfile management
- [ ] Implement a modular configuration structure
- [ ] Add a testing mechanism for configuration changes
- [ ] Create a documentation system for tools and configurations
