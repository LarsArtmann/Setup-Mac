# 🌳 Universal Nix Configuration Architecture Proposal

### Platform-Agnostic: macOS (nix-darwin) + NixOS Ready

---

**⚠️ DOCUMENT STATUS: PROPOSAL - NOT IMPLEMENTED ⚠️**

**Proposal Date:** 2025-11-11
**Current State:** Architectural planning only (detailed blueprints)
**Implementation Status:** 0% (not started - current system uses flat structure)
**Implementation Decision:** Pending (see docs/learnings/2025-11-15_13-44-planning-vs-reality-gap-analysis.md)
**Next Review:** After Option A/B/C decision made

**IMPORTANT:** This document describes a PROPOSED architecture, not the CURRENT implementation.

**Current Reality:**

- Flat structure: `dotfiles/nix/*.nix` (1336 lines)
- Darwin-only flake
- No platform abstraction layer
- No NixOS support yet

**This Proposal Would Provide:**

- Tree structure: `platforms/`, `lib/`, `profiles/`, `modules/`
- Multi-platform flake (Darwin + NixOS)
- Platform abstraction with 80%+ code reuse
- 6-week implementation timeline (3 phases)

## **See Also:** docs/learnings/2025-11-15_13-44-planning-vs-reality-gap-analysis.md for gap analysis and options

**Date:** 2025-11-11
**Version:** 1.0
**Author:** Lars Artmann
**Status:** Proposal (Not Implemented)

---

## 🎯 EXECUTIVE SUMMARY

This document proposes a comprehensive restructuring of the current Nix configuration into a unified, platform-agnostic architecture that supports both macOS (nix-darwin) and future NixOS deployment. The new tree-like structure provides clear separation of concerns, maximum code reuse, and seamless migration capabilities.

### Current State Analysis

The existing configuration has grown organically with mixed organizational patterns:

- **Flat structure**: Many `.nix` files in root `dotfiles/nix/` directory
- **Partial categorization**: Some subdirectories exist but lack consistent hierarchy
- **Scattered concerns**: Related functionality spread across multiple files
- **Platform coupling**: macOS-specific configurations mixed with universal settings
- **Limited reusability**: Hard to extract components for NixOS migration

### Vision Statement

Create a universal Nix configuration that:

- **Works seamlessly** on both macOS and NixOS
- **Maximizes code reuse** (80%+ shared configuration)
- **Provides clear separation** between platform-specific and universal concerns
- **Enables gradual migration** from macOS to NixOS
- **Maintains full backward compatibility** during transition

---

## 🌳 PROPOSED ARCHITECTURE

### Directory Structure Overview

```
nix-config/                              # 🌳 ROOT (rename from dotfiles/nix/)
├── flake.nix                            # 🔥 UNIVERSAL FLAKE (multi-platform)
├── treefmt.nix                          # 🌳 Universal formatting
│
├── platforms/                          # 🏗️ PLATFORM-SPECIFIC LAYERS
│   ├── common/                         # 📋 CROSS-PLATFORM CONFIGURATION
│   │   ├── core/                       # Universal core settings
│   │   │   ├── nix-settings.nix        # Nix settings (shared)
│   │   │   ├── security.nix            # Cross-platform security
│   │   │   └── performance.nix         # Performance optimization
│   │   │
│   │   ├── environment/                # Universal environment
│   │   │   ├── variables.nix           # Environment variables
│   │   │   ├── shells.nix              # Shell configuration
│   │   │   └── paths.nix               # PATH configuration
│   │   │
│   │   ├── packages/                   # Package management
│   │   │   ├── base.nix                # Base packages (all platforms)
│   │   │   ├── development.nix        # Development tools
│   │   │   ├── cli.nix                 # CLI tools
│   │   │   └── overlays.nix            # Custom overlays
│   │   │
│   │   └── programs/                    # Program configurations
│   │       ├── git.nix                 # Git configuration
│   │       ├── editors.nix             # Editor settings
│   │       ├── fish.nix                # Fish shell
│   │       └── security-tools.nix      # Security utilities
│   │
│   ├── darwin/                         # 🍎 MACOS-SPECIFIC
│   │   ├── system/                     # macOS system configuration
│   │   │   ├── defaults.nix            # macOS defaults
│   │   │   ├── file-associations.nix   # File type handlers
│   │   │   ├── finder.nix              # Finder settings
│   │   │   └── spotlight.nix           # Spotlight integration
│   │   │
│   │   ├── services/                   # macOS-specific services
│   │   │   ├── touch-id.nix           # Touch ID sudo
│   │   │   ├── launchd.nix            # Launch agents/services
│   │   │   └── homebrew.nix            # Homebrew integration
│   │   │
│   │   └── networking/                 # macOS networking
│   │       ├── dns.nix                 # DNS configuration
│   │       ├── network-services.nix   # Known networks
│   │       └── tailscale.nix           # Tailscale integration
│   │
│   └── nixos/                         # 🐧 NIXOS-SPECIFIC (future-ready)
│       ├── system/                     # NixOS system configuration
│       │   ├── boot.nix                # Boot configuration
│       │   ├── filesystems.nix        # File system setup
│       │   ├── hardware.nix            # Hardware configuration
│       │   └── kernel.nix              # Kernel modules
│       │
│       ├── services/                   # NixOS services
│       │   ├── networking.nix          # NetworkManager/systemd-networkd
│       │   ├── security.nix            # Security services
│       │   └── system-services.nix     # System services
│       │
│       └── desktop/                    # NixOS desktop environment
│           ├── xorg.nix                # X11 configuration
│           ├── wayland.nix             # Wayland support
│           └── display-managers.nix    # Display manager setup
│
├── modules/                            # 🧩 UNIVERSAL MODULES
│   ├── programs/                       # Program modules
│   │   ├── development/                # Development environment
│   │   │   ├── go.nix                  # Go development
│   │   │   ├── javascript.nix          # Node.js/TypeScript
│   │   │   ├── python.nix              # Python development
│   │   │   └── containers.nix          # Docker/Podman
│   │   │
│   │   ├── gui/                        # GUI applications
│   │   │   ├── browsers.nix            # Web browsers
│   │   │   ├── editors.nix             # Text editors/IDEs
│   │   │   ├── terminals.nix           # Terminal emulators
│   │   │   └── productivity.nix        # Productivity apps
│   │   │
│   │   └── system/                     # System utilities
│   │       ├── monitoring.nix          # System monitoring
│   │       ├── security.nix            # Security tools
│   │       └── networking.nix          # Network tools
│   │
│   ├── services/                      # Service modules
│   │   ├── databases/                  # Database configurations
│   │   │   ├── sqlite.nix
│   │   │   ├── postgresql.nix
│   │   │   └── redis.nix
│   │   │
│   │   ├── web/                        # Web services
│   │   │   ├── nginx.nix
│   │   │   └── development-servers.nix
│   │   │
│   │   └── monitoring/                 # Monitoring services
│   │       ├── netdata.nix
│   │       ├── prometheus.nix
│   │       └── grafana.nix
│   │
│   └── development/                   # Development modules
│       ├── languages/                  # Language-specific setups
│       ├── tools/                      # Development tools
│       └── environments/               # Dev environments
│
├── lib/                               # 🔧 UNIVERSAL LIBRARY
│   ├── platform/                      # Platform detection utilities
│   │   ├── detection.nix              # Platform identification
│   │   ├── defaults.nix               # Platform-specific defaults
│   │   └── compatibility.nix          # Compatibility layers
│   │
│   ├── types/                         # Type definitions
│   │   ├── system.nix                  # System configuration types
│   │   ├── user.nix                    # User configuration types
│   │   ├── package.nix                # Package management types
│   │   └── service.nix                 # Service configuration types
│   │
│   ├── assertions/                    # Validation utilities
│   │   ├── cross-platform.nix         # Cross-platform validation
│   │   ├── platform-specific.nix      # Platform-specific validation
│   │   └── dependencies.nix           # Dependency validation
│   │
│   └── helpers/                       # Helper functions
│       ├── conditional.nix             # Platform conditional logic
│       ├── path-management.nix         # Path utilities
│       └── user-management.nix        # User configuration helpers
│
├── profiles/                          # 👤 CONFIGURATION PROFILES
│   ├── base/                          # Base configurations
│   │   ├── common.nix                 # Common base for all platforms
│   │   ├── darwin.nix                 # macOS base configuration
│   │   └── nixos.nix                  # NixOS base configuration
│   │
│   ├── user/                          # User profiles
│   │   ├── minimal.nix                # Minimal user setup
│   │   ├── development.nix            # Development user setup
│   │   ├── security.nix               # Security-focused setup
│   │   └── productivity.nix           # Productivity setup
│   │
│   └── role/                          # Role-based profiles
│       ├── workstation.nix            # Workstation setup
│       ├── server.nix                 # Server setup
│       ├── development-server.nix     # Development server
│       └── laptop.nix                 # Laptop-optimized setup
│
├── packages/                          # 📦 CUSTOM PACKAGES
│   ├── helium/
│   │   └── default.nix
│   ├── tuios/
│   │   └── default.nix
│   └── overlays/                      # Package overlays
│       ├── cross-platform.nix
│       └── platform-specific/
│           ├── darwin.nix
│           └── nixos.nix
│
└── hosts/                             # 🏠 HOST-SPECIFIC CONFIGURATIONS
    ├── macbook-air/                   # Current MacBook Air
    │   ├── hardware-configuration.nix # Hardware-specific settings
    │   └── settings.nix               # Host-specific preferences
    │
    ├── future-nixos-pc/               # Future NixOS machine
    │   ├── hardware-configuration.nix
    │   └── settings.nix
    │
    └── common/                        # Common host configurations
        ├── development-machine.nix
        └── security-hardened.nix
```

---

## 🔥 UNIVERSAL FLAKE DESIGN

### Multi-Platform Flake Structure

```nix
{
  description = "Lars' Universal Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional inputs for enhanced functionality
    nix-homebrew.url = "github:zhaofengli-wix/homebrew";
    nur.url = "github:nix-community/NUR";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    wrappers.url = "github:lassulus/wrappers";
    mac-app-util.url = "github:hraban/mac-app-util";

    # NixOS-specific inputs (prepared for future use)
    disko.url = "github:nix-community/disko";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs: {
    # NixOS Configurations (future-ready)
    nixosConfigurations = {
      future-nixos-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./platforms/nixos/
          ./profiles/base/nixos.nix
          ./profiles/user/development.nix
          ./hosts/future-nixos-pc/settings.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.lars = ./profiles/user/development.nix;
          }
        ];
      };
    };

    # nix-darwin Configurations (current)
    darwinConfigurations = {
      "Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./platforms/darwin/
          ./profiles/base/darwin.nix
          ./profiles/user/development.nix
          ./hosts/macbook-air/settings.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.larsartmann = ./profiles/user/development.nix;
          }
        ];
      };
    };

    # Home Manager Configurations (portable)
    homeConfigurations = {
      lars = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./platforms/common/
          ./profiles/user/development.nix
        ];
      };
    };

    # Development shells for different platforms
    devShells = {
      aarch64-darwin = import ./shells/darwin.nix { inherit inputs; };
      x86_64-linux = import ./shells/nixos.nix { inherit inputs; };
    };
  };
}
```

---

## 🧩 PLATFORM DETECTION LIBRARY

### Cross-Platform Utilities

```nix
# lib/platform/detection.nix
{ lib, ... }: {
  # Platform detection utilities
  isDarwin = system: lib.hasSuffix "darwin" system;
  isNixOS = system: lib.hasSuffix "linux" system;
  isAarch64 = system: lib.hasPrefix "aarch64" system;
  isX86_64 = system: lib.hasPrefix "x86_64" system;

  getPlatformModules = system:
    if lib.hasSuffix "darwin" system then [
      ./platforms/darwin
    ] else if lib.hasSuffix "linux" system then [
      ./platforms/nixos
    ] else [];

  conditionalModule = system: darwinModule: nixosModule: commonModule:
    if lib.hasSuffix "darwin" system then darwinModule
    else if lib.hasSuffix "linux" system then nixosModule
    else commonModule;

  # Platform-specific package selection
  selectPackages = system: darwinPkgs: nixosPkgs: commonPkgs:
    let
      platformPkgs = if lib.hasSuffix "darwin" system then darwinPkgs else nixosPkgs;
    in
    commonPkgs ++ platformPkgs;

  # Service configuration adaptation
  adaptServiceConfig = system: darwinConfig: nixosConfig:
    if lib.hasSuffix "darwin" system then darwinConfig else nixosConfig;
}
```

### Platform Abstraction Layer

```nix
# lib/platform/defaults.nix
{ lib, ... }: {
  # Default configurations per platform
  defaultShells = system:
    if lib.hasSuffix "darwin" system then ["fish" "zsh" "bash"]
    else ["fish" "bash"];

  defaultPackages = system:
    if lib.hasSuffix "darwin" system then {
      # macOS-specific defaults
      system = ["coreutils" "findutils"];
      development = ["git" "vim"];
      gui = ["iterm2"];
    } else {
      # NixOS-specific defaults
      system = ["coreutils-full" "findutils"];
      development = ["git" "vim"];
      gui = ["alacritty"];
    };

  # Network configuration defaults
  defaultNetworkConfig = system:
    if lib.hasSuffix "darwin" system then {
      # macOS networking defaults
      knownNetworkServices = ["Wi-Fi" "Ethernet"];
      dns = ["9.9.9.9" "1.1.1.1"];
    } else {
      # NixOS networking defaults
      useDHCP = true;
      dns = ["9.9.9.9" "1.1.1.1"];
    };
}
```

---

## 🎯 CONFIGURATION MIGRATION MAP

### Current File → New Location Mapping

| Current File      | New Location                             | Notes                             |
| ----------------- | ---------------------------------------- | --------------------------------- |
| `core.nix`        | `platforms/common/core/nix-settings.nix` | Extract platform-specific parts   |
| `system.nix`      | `platforms/darwin/system/`               | Split into multiple modules       |
| `environment.nix` | `platforms/common/environment/`          | Separate variables, shells, paths |
| `programs.nix`    | `platforms/common/programs/`             | Split by category                 |
| `homebrew.nix`    | `platforms/darwin/services/homebrew.nix` | macOS-specific                    |
| `networking.nix`  | `platforms/darwin/networking/`           | Platform adaptation needed        |
| `users.nix`       | `platforms/common/` + platform-specific  | Split user config                 |
| `core/`           | `lib/`                                   | Reorganize as library             |
| `wrappers/`       | `lib/wrappers/`                          | Move to library layer             |
| `packages/`       | `packages/`                              | Keep same location                |
| `testing/`        | `lib/assertions/` + `testing/`           | Split validation and tests        |

### Platform Separation Strategy

#### Universal Components (80%+ reuse)

- **Development Tools**: Git, editors, language runtimes
- **Shell Configuration**: Fish, Zsh, Bash settings
- **Security Tools**: SSH configuration, certificates
- **User Preferences**: Aliases, environment variables
- **Package Overlays**: Custom packages, version fixes

#### Platform-Specific Components

- **macOS**: Homebrew, Touch ID, Finder defaults, Spotlight
- **NixOS**: Systemd services, filesystem configuration, boot settings

---

## 🚀 IMPLEMENTATION PHASES

### Phase 1: Foundation (Week 1-2)

**Objective**: Create new structure and migrate core components

#### Tasks

1. **Create directory structure**

   ```bash
   mkdir -p nix-config/{platforms/{common,darwin,nixos}/{core,environment,packages,programs,services,networking,system},modules/{programs,services,development},lib/{platform,types,assertions,helpers},profiles/{base,user,role},packages/overlays,hosts/{macbook-air,future-nixos-pc,common}}
   ```

2. **Migrate universal configurations**
   - Move shared settings to `platforms/common/`
   - Extract platform-specific parts to respective directories
   - Create module interfaces and type definitions

3. **Update flake.nix**
   - Implement multi-platform support
   - Add conditional module loading
   - Configure home-manager integration

#### Deliverables

- New directory structure created
- Core configurations migrated
- Flake updated with multi-platform support
- Backward compatibility maintained

### Phase 2: Platform Abstraction (Week 3-4)

**Objective**: Implement platform detection and conditional loading

#### Tasks

1. **Create platform detection library**
   - Implement platform detection utilities
   - Create abstraction layer for platform differences
   - Add platform-specific defaults

2. **Refactor configuration modules**
   - Make modules platform-agnostic where possible
   - Add platform-specific conditional logic
   - Implement proper module interfaces

3. **Create profile compositions**
   - Design base profiles for each platform
   - Implement role-based user profiles
   - Create configuration composition system

#### Deliverables

- Platform detection library
- Refactored configuration modules
- Profile composition system
- Cross-platform validation

### Phase 3: NixOS Preparation (Week 5-6)

**Objective**: Add NixOS support and ensure full compatibility

#### Tasks

1. **Add NixOS-specific modules**
   - Create NixOS system configuration
   - Implement NixOS service configurations
   - Add desktop environment setup

2. **Create migration tools**
   - Build configuration validation tools
   - Create migration testing framework
   - Document migration process

3. **Testing and validation**
   - Test configuration on current macOS setup
   - Validate NixOS compatibility (dry-run)
   - Performance optimization

#### Deliverables

- Complete NixOS module support
- Migration testing framework
- Comprehensive documentation
- Performance benchmarks

---

## 📊 BENEFITS ANALYSIS

### Immediate Benefits (Post-Phase 1)

- **✅ Improved Organization**: Clear separation of concerns
- **✅ Better Maintainability**: Easier to locate and modify configurations
- **✅ Enhanced Reusability**: Modules can be reused across systems
- **✅ Cleaner Flake**: Multi-platform support with clear structure

### Medium-term Benefits (Post-Phase 2)

- **🔄 Seamless Migration**: Gradual transition from macOS to NixOS
- **📦 Configuration Reuse**: 80%+ of config works on both platforms
- **🎯 Platform Optimization**: Platform-specific optimizations where needed
- **🧩 Modular Design**: Mix and match components as needed

### Long-term Benefits (Post-Phase 3)

- **🔧 Future-Proof**: Ready for NixOS without rewriting everything
- **🌐 Multi-Machine Support**: Easy deployment to multiple machines
- **📈 Scalability**: Architecture supports complex configurations
- **🛡️ Type Safety**: Enhanced validation prevents misconfiguration

---

## 🎛️ RISK ASSESSMENT & MITIGATION

### Technical Risks

| Risk                               | Probability | Impact | Mitigation                                      |
| ---------------------------------- | ----------- | ------ | ----------------------------------------------- |
| Migration breaks current setup     | Medium      | High   | Incremental migration with testing at each step |
| Platform differences cause issues  | Low         | Medium | Comprehensive platform abstraction layer        |
| Configuration complexity increases | Medium      | Low    | Clear documentation and module interfaces       |
| Performance regression             | Low         | Medium | Performance monitoring and optimization         |

### Project Risks

| Risk                             | Probability | Impact | Mitigation                               |
| -------------------------------- | ----------- | ------ | ---------------------------------------- |
| Time estimation too optimistic   | Medium      | Medium | Flexible timeline with buffer periods    |
| Learning curve for new structure | Low         | Low    | Comprehensive documentation and examples |
| Tool compatibility issues        | Low         | Medium | Thorough testing of all tools            |

---

## 📋 SUCCESS METRICS

### Technical Metrics

- **Configuration Reuse**: >80% of modules shared between platforms
- **Migration Success**: Zero downtime during migration phases
- **Performance**: <5% performance impact on current setup
- **Validation**: 100% of configurations pass type checking

### Usability Metrics

- **Module Discovery**: <30 seconds to find any configuration
- **New Setup Time**: <50% time to configure new machine
- **Documentation Coverage**: 100% of modules documented
- **Error Messages**: Clear, actionable error messages

### Project Metrics

- **Timeline**: Complete migration within 6 weeks
- **Backward Compatibility**: 100% during transition period
- **Testing Coverage**: >90% of configurations tested
- **Documentation**: Complete migration guide and reference

---

## 🚀 NEXT STEPS

### Immediate Actions

1. **Review and approve** this architecture proposal
2. **Schedule migration timeline** with specific dates
3. **Backup current configuration** for rollback capability
4. **Begin Phase 1 implementation**

### Preparation Tasks

- Review current configuration dependencies
- Identify platform-specific components
- Plan testing strategy for each migration phase
- Prepare documentation templates

### Long-term Vision

- **Multi-machine deployment**: Support for servers, laptops, desktops
- **Team collaboration**: Share configuration across team members
- **Continuous integration**: Automated testing of configuration changes
- **Configuration marketplace**: Share reusable modules with community

---

## 📚 REFERENCE MATERIALS

### Documentation

- [NixOS Modules Documentation](https://nixos.org/manual/nixos/stable/)
- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Documentation](https://nix-community.github.io/home-manager/)
- [Flake Best Practices](https://github.com/jtojnar/nix flakes-templates)

### Related Projects

- [nix-darwin-dotfiles](https://github.com/malob/nix-darwin-dotfiles)
- [nixos-config](https://github.com/MatthiasBenaets/nixos-config)
- [nix-homebrew](https://github.com/zhaofengli-wip/nix-homebrew)

### Tools and Utilities

- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [nix-ai-tools](https://github.com/numtide/nix-ai-tools)
- [wrappers](https://github.com/lassulus/wrappers)

---

**Status:** ✅ Proposal Complete - Awaiting Review & Approval

**Next Review Date:** TBD
**Implementation Start Date:** TBD
**Target Completion Date:** TBD

---

_This proposal represents a significant investment in configuration infrastructure that will pay dividends in maintainability, scalability, and cross-platform compatibility for years to come._
