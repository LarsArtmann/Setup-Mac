# SystemNix

**Declarative cross-platform system configuration using Nix.**

SystemNix manages both macOS (nix-darwin) and NixOS systems through a single, reproducible Nix flake. All system settings, packages, and user configurations are defined in code and applied consistently across machines.

## What You Get

| Category | Tools |
|----------|-------|
| **Languages** | Go 1.26, Node.js, Bun, Python, Rust, Java, .NET |
| **Cloud** | AWS CLI, GCP SDK, kubectl, Helm, Terraform |
| **Development** | Git, GitHub CLI, JetBrains Toolbox, VS Code, tmux, Fish shell |
| **Security** | Gitleaks, age encryption, Touch ID for sudo |
| **Monitoring** | ActivityWatch, Netdata, ntopng |
| **AI/ML** | ROCm support, AMD NPU driver, Python AI stack |

## Quick Start

### Prerequisites

- macOS (Apple Silicon/Intel) or Linux with Nix installed
- Xcode Command Line Tools (macOS)
- Administrative access

### Installation

```bash
# Install Nix (Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone and apply configuration
git clone https://github.com/LarsArtmann/SystemNix.git ~/projects/SystemNix
cd ~/projects/SystemNix
just setup              # Complete setup
just switch             # Apply configuration
```

### Target Systems

| System | Configuration | Command |
|--------|--------------|---------|
| macOS (Lars-MacBook-Air) | `flake.nix#Lars-MacBook-Air` | `sudo darwin-rebuild switch --flake .#Lars-MacBook-Air` |
| NixOS (evo-x2) | `flake.nix#evo-x2` | `sudo nixos-rebuild switch --flake .#evo-x2` |

## Architecture

```
platforms/
├── common/              # Shared across platforms (~80% of config)
│   ├── home-base.nix    # Home Manager base
│   ├── programs/        # Fish, tmux, Starship, SSH, Git
│   ├── packages/        # Cross-platform packages
│   └── core/            # Type safety & validation
├── darwin/              # macOS-specific (nix-darwin)
│   ├── default.nix      # System config
│   └── home.nix         # User config overrides
└── nixos/               # NixOS-specific
    ├── system/          # System configuration
    └── users/           # User configurations
```

### Key Components

- **flake.nix**: Main entry point defining all outputs
- **justfile**: Task runner for all operations (use instead of raw Nix commands)
- **Home Manager**: Unified user configuration for both platforms
- **Ghost Systems**: Type safety framework for compile-time validation

## Essential Commands

```bash
# Core workflow
just setup              # Initial setup (run once after clone)
just switch             # Apply configuration changes
just update             # Update packages
just test               # Validate without applying

# Development
just dev                # Format, lint, test
just format             # Format code with treefmt
just health             # System health check

# Maintenance
just clean              # Clean caches and old packages
just backup             # Backup configuration
just rollback           # Revert to previous generation
```

## Type Safety

SystemNix uses Ghost Systems for compile-time validation:

```nix
# Types.nix defines all configuration types
# State.nix provides centralized state management
# Validation.nix enforces constraints at evaluation time
```

Configuration errors are caught during build, not at runtime.

## Nix-Managed Development Tools

All tools are declared in Nix, providing:

- **Reproducible**: Same versions everywhere
- **Atomic updates**: `just update && just switch`
- **Easy rollback**: Revert to previous tool versions

Go tools (gopls, golangci-lint, buf, delve, etc.) are defined in `platforms/common/packages/base.nix`.

## Features

- Declarative system configuration
- Cross-platform (macOS + NixOS)
- Type-safe configuration validation
- Home Manager for user settings
- 100+ pre-configured development tools
- Comprehensive monitoring stack
- Security hardening (Gitleaks, Touch ID)
- GPU/NPU support (ROCm, AMD XDNA)

## Documentation

| Guide | Description |
|-------|-------------|
| [Setup Guide](./docs/development/setup.md) | Detailed installation instructions |
| [Troubleshooting](./docs/troubleshooting/README.md) | Common issues and solutions |
| [AGENTS.md](./AGENTS.md) | AI assistant guide |
| [Project Status](./docs/project-status-summary.md) | Development milestones |

## Troubleshooting

### Build Errors

```bash
# Validate configuration
just test-fast

# Clean and rebuild
just clean && just switch
```

### GPG Not Working

```bash
# Install GPG via Nix
nix profile add nixpkgs#gnupg

# Path should be: ~/.nix-profile/bin/gpg
```

### Package Not Found

```bash
nix search nixpkgs <package-name>
```

## Repository Structure

```
SystemNix/
├── flake.nix              # Main flake entry point
├── justfile               # Task runner commands
├── platforms/
│   ├── common/           # Shared configuration
│   ├── darwin/           # macOS configuration
│   └── nixos/            # NixOS configuration
├── docs/                  # Documentation
│   ├── development/
│   ├── troubleshooting/
│   └── status/
└── AGENTS.md              # AI assistant guide
```

## Contributing

1. Make changes in `platforms/common/` for cross-platform config
2. Use platform-specific directories for platform differences
3. Run `just test` before committing
4. Follow existing code style (2-space indentation for Nix)

## License

Personal configuration. Adapt for your own use.
