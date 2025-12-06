# Setup-Mac: AGENT GUIDE

**Last Updated:** 2025-12-06
**Project Type:** Cross-Platform Nix Configuration (macOS + NixOS)
**Architecture:** Declarative System Configuration with Type Safety

---

## 🎯 PROJECT OVERVIEW

Setup-Mac is a comprehensive, production-ready Nix-based configuration system for managing both macOS (nix-darwin) and NixOS systems with:

- **Declarative Configuration**: All system settings managed through Nix expressions
- **Cross-Platform Support**: Unified configurations for macOS (nix-darwin) and NixOS
- **Type Safety System**: Comprehensive validation and assertion framework
- **Ghost Systems Integration**: Advanced type-safe architecture patterns
- **Development Environment**: Complete toolchain for Go, TypeScript, AI/ML development
- **Security-First**: Built-in security tools and configurations

## 🏗️ ARCHITECTURE

### Configuration Hierarchy
```
Setup-Mac/
├── flake.nix                    # Main entry point, defines outputs
├── justfile                     # Primary task runner (USE THIS)
├── dotfiles/nix/               # macOS-specific configurations
├── dotfiles/nixos/              # NixOS-specific configurations
├── platforms/                  # Cross-platform abstractions
│   ├── common/                 # Shared across platforms
│   ├── darwin/                 # macOS-only settings
│   └── nixos/                  # NixOS-only settings
└── dotfiles/nix/core/           # Type safety & validation system
```

### Key Components

#### Core Type Safety System
- **`core/TypeSafetySystem.nix`**: Main validation framework
- **`core/State.nix`**: Centralized state management
- **`core/Validation.nix`**: Configuration validation logic
- **`core/Types.nix`**: Type definitions for all configurations

#### Platform Modules
- **`environment.nix`**: Packages, environment variables, shell aliases
- **`system.nix`**: System settings (macOS defaults, NixOS config)
- **`programs.nix`**: User program configurations
- **`core.nix`**: Core packages, security, system services

---

## 🚀 ESSENTIAL COMMANDS

**ALWAYS use Just commands when available - never run raw Nix commands unless absolutely necessary!**

### Primary Workflow Commands
```bash
# Core operations (use these)
just setup              # Complete initial setup (run after cloning)
just switch             # Apply Nix configuration changes
just test               # Test configuration without applying
just build              # Build without applying
just update             # Update all packages and flake
just clean              # Clean up caches and old packages
just check              # Check system status and outdated packages

# Development workflow
just dev                # Format, check, test (full dev cycle)
just format             # Format code with treefmt
just pre-commit-run     # Run pre-commit hooks on all files
just health             # Comprehensive health check
just debug              # Debug shell startup with verbose logging
```

### Backup & Recovery
```bash
just backup             # Create configuration backup
just restore NAME       # Restore from backup (just restore backup_name)
just list-backups       # Show available backups
just rollback           # Emergency rollback to previous generation
```

### Go Development (Primary Language)
```bash
# Core Go workflow
just go-dev             # Format, lint, test, build (complete)
just go-lint            # Run golangci-lint on Go code
just go-format          # Format Go code with gofumpt
just go-check-updates  # Check which Go binaries need updates
just go-auto-update     # Auto-update all Go binaries with gup
just go-tools-version   # Show versions of all Go tools

# Go code generation
just go-gen-tests PKG  # Generate Go tests for package
just go-gen-mocks SRC DST # Generate Go mocks with mockgen
just go-wire            # Generate wire dependency injection
```

### Monitoring & Performance
```bash
just benchmark          # Benchmark shell startup performance
just benchmark-all      # Comprehensive system benchmarks
just perf-report DAYS   # Generate performance report (default 7 days)
just monitor-all        # Start comprehensive monitoring
```

---

## 🧪 TESTING & VALIDATION

### Configuration Testing
- **ALWAYS test before applying**: `just test` before `just switch`
- **Type safety validation**: Automatic via Ghost Systems framework
- **Pre-commit hooks**: Gitleaks, trailing whitespace, Nix syntax
- **Comprehensive health check**: `just health` for full system validation

### Validation Commands
```bash
# Configuration validation
just type-check         # Validate Nix types (if implemented)
nix flake check        # Check flake syntax and outputs
darwin-rebuild check   # Test macOS configuration
nixos-rebuild check    # Test NixOS configuration

# Development validation
just pre-commit-run     # Run all pre-commit hooks
just go-lint           # Validate Go code quality
just go-check          # Run gopls language server check
```

---

## 📁 FILE ORGANIZATION & PATTERNS

### Configuration File Patterns
- **Modular Architecture**: Each concern in separate .nix file
- **Cross-Platform**: Shared configs in `platforms/common/`
- **Type Safety**: All configs validate through `core/Validation.nix`
- **Import Hierarchy**: `flake.nix` → platform modules → core modules

### Adding New Configurations
1. **Determine scope**: Platform-specific vs cross-platform
2. **Choose location**:
   - Cross-platform: `platforms/common/`
   - macOS only: `dotfiles/nix/` or `platforms/darwin/`
   - NixOS only: `dotfiles/nixos/` or `platforms/nixos/`
3. **Import appropriately**: Add to relevant module list
4. **Test**: `just test` before `just switch`
5. **Validate**: Run `just health` to ensure integrity

### Package Management Patterns
- **Nix packages**: Preferred for CLI tools (declarative, reproducible)
- **Homebrew**: GUI applications only (managed via nix-homebrew)
- **Cross-platform packages**: Defined in `platforms/common/packages/base.nix`

---

## 🔧 DEVELOPMENT WORKFLOW

### Standard Development Process
1. **Edit configuration files** in appropriate directory
2. **Format changes**: `just format`
3. **Validate syntax**: `just test` (builds without applying)
4. **Run pre-commit**: `just pre-commit-run`
5. **Apply changes**: `just switch`
6. **Verify health**: `just health`

### Type Safety Development
- **All configurations** must pass type validation
- **State management** centralized in `core/State.nix`
- **Compile-time validation** prevents runtime errors
- **Strong typing** eliminates configuration inconsistencies

### Git Workflow
- **Use git-town** for all Git operations
- **Small, atomic commits** with comprehensive messages
- **Feature branches** for all work
- **ALWAYS** use `git mv` instead of `mv` for file moves

---

## 🚨 CRITICAL RULES & GOTCHAS

### MUST FOLLOW
- **NEVER run raw Nix commands** - Always use Just commands
- **ALWAYS test before applying** - `just test` before `just switch`
- **NEVER use `rm`** - Always use `trash` for file deletion
- **NEVER edit package.json manually** - Always use `bun add`
- **ALWAYS use `git mv`** - Never plain `mv` in git repos
- **TYPE SAFETY FIRST** - All configs must validate through core system

### Common Pitfalls
1. **Path Resolution**: Use `just debug-paths` to verify configuration paths
2. **Package Not Found**: Search with `nix search nixpkgs package-name`
3. **Build Errors**: Run `just clean && just switch` for full rebuild
4. **GPG Issues**: Ensure GPG is in nix profile: `/nix/var/nix/profiles/per-user/$USER/profile/bin/gpg`

### Platform-Specific Gotchas
- **macOS**: Use `darwin-rebuild` commands via Just
- **NixOS**: Use `nixos-rebuild` commands via Just
- **Cross-platform**: Shared packages in `platforms/common/` prevent drift

---

## 🛠️ BUILD & DEPLOYMENT

### macOS Deployment
```bash
# Fresh installation
cd ~/Desktop/Setup-Mac
just setup              # Complete initial setup
just switch             # Apply configuration

# Update existing
just update             # Update flake inputs
just switch             # Apply updates
```

### NixOS Deployment
```bash
# Target: evo-x2 (GMKtec AMD Ryzen AI Max+ 395)
sudo nixos-rebuild switch --flake .#evo-x2

# Test without applying
sudo nixos-rebuild test --flake .#evo-x2

# Build only
sudo nixos-rebuild build --flake .#evo-x2
```

### Build Targets
- **`Lars-MacBook-Air`**: macOS (nix-darwin) configuration
- **`evo-x2`**: NixOS configuration for AMD Ryzen AI Max+ 395

---

## 📊 MONITORING & MAINTENANCE

### Performance Monitoring
- **ActivityWatch**: Automatic time tracking via Nix
- **Netdata**: System monitoring at http://localhost:19999
- **ntopng**: Network monitoring at http://localhost:3000
- **Built-in benchmarks**: `just benchmark-all`

### Maintenance Commands
```bash
# Regular maintenance (weekly)
just update             # Update packages
just clean              # Clean caches
just health             # System health check

# Deep cleanup (monthly)
just clean-aggressive   # Remove more data, may need reinstalls
just deep-clean         # Thorough cleanup using custom paths

# Backup management
just backup             # Create backup
just clean-backups      # Clean old backups (keep last 10)
```

---

## 🔒 SECURITY CONFIGURATION

### Built-in Security
- **Gitleaks**: Automatic secret detection in pre-commit
- **Touch ID**: Enabled for sudo operations
- **PKI**: Enhanced certificate management
- **Firewall**: Little Snitch and Lulu integration
- **Encryption**: Age for modern file encryption

### Security Practices
- **No hardcoded secrets** - Use environment variables or private files
- **Pre-commit hooks** prevent accidental secret commits
- **Regular updates** via `just update`
- **Audit tools**: Gitleaks, security scanning

---

## 🤖 AI & DEVELOPMENT TOOLS

### AI Development Stack
- **Crush**: Available via nix-ai-tools input
- **TypeSpec**: For API specification and code generation
- **Python AI/ML**: Complete stack in configuration
- **GPU Acceleration**: ROCm support for AMD hardware

### Development Languages
- **Go**: Primary development language with complete toolchain
- **TypeScript/Bun**: Modern JavaScript development
- **Python**: AI/ML and scripting with uv package manager
- **Nix**: System configuration and package management

### Essential Tools
- **Git + Git Town**: Advanced version control
- **JetBrains Toolbox**: Professional IDE management
- **Docker**: Container development
- **Cloud Tools**: AWS CLI, Google Cloud SDK, kubectl

---

## 🧰 SPECIALIZED SYSTEMS

### Wrapper System
- **Dynamic library management**: Advanced wrapping for complex applications
- **Template-based**: Consistent wrapper generation
- **Validation**: Automatic wrapper syntax checking

### Ghost Systems Integration
- **Type-safe architecture**: Compile-time validation
- **Assertion frameworks**: Comprehensive error prevention
- **State management**: Centralized configuration state
- **Cross-platform consistency**: Unified patterns

---

## 📝 DOCUMENTATION

### Documentation Structure
- **`docs/`**: Comprehensive guides and status reports
- **`docs/troubleshooting/`**: Common issues and solutions
- **`docs/status/`**: Development chronology and progress reports
- **Inline comments**: All configuration files documented

### Status Tracking
- **Regular status reports** in `docs/status/`
- **Project summary** in `docs/project-status-summary.md`
- **Development milestones** documented with dates

---

## 🚨 EMERGENCY PROCEDURES

### Configuration Recovery
```bash
# Emergency rollback
just rollback           # Rollback to previous generation

# Restore from backup
just restore backup_name  # Restore specific backup

# Complete reset (last resort)
just clean-aggressive   # Remove most data
just setup             # Fresh installation
```

### Debugging
```bash
just debug             # Shell startup debug mode
just health            # Comprehensive health check
just context-detect     # Detect current shell context
just benchmark-all     # Performance analysis
```

### When Things Go Wrong
1. **Stop making changes** - Assess the situation
2. **Create backup** - `just auto-backup`
3. **Check health** - `just health` for diagnostics
4. **Rollback if needed** - `just rollback`
5. **Restore from backup** - `just restore` if necessary

---

## 🎯 SUCCESS CRITERIA

### Working Configuration
- **All tests pass**: `just test` succeeds
- **Health check clean**: `just health` shows no issues
- **Pre-commit hooks pass**: `just pre-commit-run` clean
- **Type safety validation**: No assertion failures

### Development Environment
- **Go toolchain complete**: `just go-tools-version` shows all tools
- **Performance acceptable**: Shell startup under 2 seconds
- **Security active**: Gitleaks, Touch ID, firewall enabled
- **Monitoring functional**: ActivityWatch, Netdata operational

---

*This AGENTS.md file is maintained as part of the Setup-Mac project. Last updated: 2025-12-06*