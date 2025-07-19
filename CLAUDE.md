# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Management Philosophy

**CRITICAL: This project uses Nix as the primary package manager. Always prefer Nix over other package managers.**

- **Nix packages** (CLI tools, development tools): Add to `dotfiles/nix/environment.nix`
- **Homebrew casks** (GUI applications only): Add to `dotfiles/nix/homebrew.nix`
- **Never use**: `brew install`, `npm install -g`, `pip install`, manual downloads
- **Exception**: Homebrew is managed declaratively through `nix-homebrew` integration

## Development Commands

### Primary Workflow (Just Task Runner)
```bash
just --list                    # Show all available commands
just setup                     # Initial system setup after cloning
just switch                    # Apply Nix configuration changes (equivalent to nixup)
just update                    # Update Nix flake inputs
just clean                     # Clean up caches and old packages
just check                     # Check system status and outdated packages
```

### Nix Operations
```bash
# Preferred deployment method (via just)
just switch

# Direct Nix commands (if just unavailable)
cd dotfiles/nix
nh darwin switch .                    # Modern Nix deployment tool
darwin-rebuild switch --flake .      # Traditional method

# Package management
nix search nixpkgs <package>         # Search for packages
nix flake update                     # Update package sources
```

### Performance & Monitoring
```bash
./shell-performance-benchmark.sh     # Comprehensive shell performance analysis
just benchmark-shells                # Shell startup benchmarking
just perf-benchmark                   # System performance monitoring
```

### Development Tools
```bash
just go-dev                          # Complete Go development workflow
just format                         # Format code with treefmt
just pre-commit-run                  # Run all pre-commit hooks
just test                           # Test Nix configuration
```

## Architecture Overview

### Core Structure
- **Nix Flake System**: `dotfiles/nix/flake.nix` orchestrates all components
- **Modular Configuration**: Each `.nix` file handles specific system aspects
- **Fish Shell**: Primary shell optimized for 66x performance improvement over ZSH
- **Homebrew Integration**: Managed declaratively through nix-homebrew

### Key Configuration Files
- `dotfiles/nix/environment.nix` - System packages, environment variables, shell aliases
- `dotfiles/nix/homebrew.nix` - GUI applications via Homebrew casks
- `dotfiles/nix/programs.nix` - Program-specific configurations (Fish shell setup)
- `dotfiles/nix/core.nix` - Core Nix settings, garbage collection, optimization
- `dotfiles/nix/system.nix` - macOS system preferences and defaults
- `justfile` - Task runner with 80+ predefined commands

### Performance Architecture
- **Fish Shell**: Default shell with Carapace completions and Starship prompt
- **Optimized PATH**: High-frequency tools first, system paths last
- **Performance Monitoring**: JSON-based tracking with git correlation
- **Regression Detection**: Automated alerts for >20% performance degradation

### Security Layer
- **Objective-See Tools**: BlockBlock, Oversight, KnockKnock, DnD (via Homebrew)
- **Pre-commit Hooks**: Gitleaks, code quality, security scanning
- **Network Security**: Little Snitch, LuLu firewall
- **Encryption**: Age, Secretive SSH key management

## Development Workflow

### Adding New Tools
1. **CLI Tools**: Add to `environment.nix` systemPackages
2. **GUI Apps**: Add to `homebrew.nix` casks array
3. **Deploy**: Run `just switch`
4. **Verify**: Check installation with `which <tool>`

### Configuration Changes
1. **Edit appropriate .nix file**
2. **Test**: `just test` (validates without applying)
3. **Apply**: `just switch`
4. **Verify**: Check functionality
5. **Commit**: Git commit with descriptive message

### Performance Optimization
- **Monitor**: Use `./shell-performance-benchmark.sh` for baseline
- **Fish Shell**: Primary performance gain (10ms vs 708ms startup)
- **Regression Detection**: Automated tracking in `performance-data/`
- **Trends**: Historical analysis with git commit correlation

### Emergency Procedures
```bash
just rollback                        # Rollback to previous generation
darwin-rebuild --list-generations    # List available generations
just backup                          # Create configuration backup
just restore <backup-name>           # Restore from backup
```

## Go Development Stack

### Comprehensive Toolchain
- **Core**: Go with templ, sqlc, go-tools
- **Testing**: gotests for test generation
- **Mocking**: mockgen for interface mocks
- **Debugging**: delve (dlv) debugger
- **Linting**: golangci-lint with gofumpt formatter
- **Protobuf**: buf for protocol buffer management

### Go Commands (via Just)
```bash
just go-dev <package>           # Complete workflow: format, lint, test, build
just go-auto-update            # Update all Go binaries with gup
just go-setup                  # Install complete Go development environment
```

## System Maintenance

### Automated Processes
- **Nix Garbage Collection**: Every day at midnight (3-day retention)
- **Nix Store Optimization**: Weekly on Sunday midnight
- **Homebrew Management**: Auto-update and cleanup via nix-homebrew

### Manual Maintenance
```bash
just clean                    # Standard cleanup
just deep-clean               # Comprehensive cleanup including build caches
just health                   # Development environment health check
```

## Configuration Validation

### Pre-commit Framework
- **Gitleaks**: Prevents secret leakage
- **Code Quality**: Trailing whitespace, file endings
- **Security**: Private key detection, large file prevention
- **Nix**: Configuration syntax validation

### Testing
- Configuration changes are validated before application
- Rollback capability ensures system stability
- Performance regression detection prevents degradation

## Fish Shell Integration

### Performance Optimizations
- **Startup Time**: 10.73ms (vs 708ms ZSH)
- **Completions**: Carapace provides 1000+ command completions
- **Configuration**: `~/.config/fish/config.fish` via Nix programs.fish
- **Aliases**: Managed in `environment.nix` shellAliases

### Key Features
- **No Greeting**: Disabled for faster startup
- **History**: Optimized with 5000 entry limits
- **Prompt**: Starship with 400ms timeout protection
- **Compatibility**: Babel fish for POSIX/Bash compatibility

## Security Tools Configuration

### Objective-See Suite (Homebrew Casks)
- **BlockBlock**: Persistence location monitoring
- **Oversight**: Microphone/webcam access monitoring
- **KnockKnock**: Persistent component scanning
- **DnD**: Critical location file monitoring

### Network Security
- **Little Snitch**: Network connection monitoring
- **LuLu**: Outgoing connection firewall
- **Tailscale**: VPN with SSH and route acceptance

## Troubleshooting

### Common Issues
- **Nix deployment timeout**: Normal for large deployments, check completion with `ps aux | grep darwin-rebuild`
- **Permission errors**: Use `sudo` for system-level darwin-rebuild operations
- **Homebrew cask failures**: Check individual cask availability with `brew info --cask <name>`
- **Fish shell not default**: Run `chsh -s /run/current-system/sw/bin/fish` manually

### Debug Commands
```bash
just debug                    # Shell startup debugging with verbose logging
just health                   # Comprehensive environment health check
nix doctor                    # Nix system health check
```

## Performance Monitoring System

### Comprehensive Benchmarking
- **Shell Performance**: Multi-shell startup time comparison
- **JSON Storage**: Historical data with git commit correlation
- **Trend Analysis**: Automatic regression detection
- **Alert System**: >20% degradation warnings

### Data Storage
- **Location**: `performance-data/shell-performance.json`
- **Format**: Timestamped entries with git metadata
- **Retention**: Unlimited history for trend analysis
- **Access**: Query via jq or performance analysis scripts