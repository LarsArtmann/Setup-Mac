# Feature Request: Isolated Program Modules with flake-parts

## 🎯 Goal

Leverage flake-parts to create isolated `.nix` files for each program that include everything from ZFS datasets, permissions, to the application and its configuration in a self-contained, modular way.

## 🏗️ Proposed Architecture

### Current State Analysis
- Current flake.nix uses traditional monolithic structure
- Wrapper system exists but is limited (basic config linking + env vars)
- No integration with ZFS, file permissions, or comprehensive service management
- Platform-specific configs are separated but not truly modular

### Target Architecture

```
Setup-Mac/
├── flake.nix (migrated to flake-parts)
├── programs/
│   ├── core/                    # Essential system programs
│   │   ├── shell/
│   │   │   ├── fish.nix        # Fish shell + ZFS dataset + perms
│   │   │   └── starship.nix    # Starship prompt + config
│   │   ├── security/
│   │   │   └── gpg.nix         # GPG + keyring dataset + perms
│   │   └── networking/
│   │       └── wireguard.nix   # VPN + config dataset + perms
│   ├── development/
│   │   ├── editors/
│   │   │   ├── vscode.nix      # VS Code + extensions + dataset
│   │   │   └── sublime.nix     # Sublime + settings + dataset
│   │   ├── languages/
│   │   │   ├── go.nix          # Go toolchain + GOPATH dataset
│   │   │   └── nodejs.nix      # Node.js + npm dataset
│   │   └── tools/
│   │       ├── docker.nix      # Docker + volumes dataset
│   │       └── k9s.nix         # Kubernetes + config dataset
│   ├── media/
│   │   ├── graphics/
│   │   │   └── blender.nix     # Blender + project datasets
│   │   └── audio/
│   │       └── reaper.nix      # DAW + audio project datasets
│   └── monitoring/
│       ├── activitywatch.nix   # Activity monitoring + log dataset
│       └── netdata.nix        # System monitoring + data dataset
├── lib/
│   ├── program-module.nix      # Module template/helpers
│   ├── zfs-helpers.nix         # ZFS dataset management
│   └── permission-helpers.nix  # File system permissions
└── flakes/
    ├── modules.nix             # flake-parts module definitions
    └── outputs.nix             # Custom flake outputs
```

### Program Module Template

Each `program.nix` file would be a complete, isolated module containing:

```nix
# programs/development/editors/vscode.nix
{ lib, config, pkgs, ... }:

with lib; {
  options.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code";
    
    zfs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Create dedicated ZFS dataset";
      };
      
      dataset = mkOption {
        type = types.str;
        default = "tank/data/vscode";
        description = "ZFS dataset path";
      };
      
      properties = mkOption {
        type = types.attrsOf types.str;
        default = {
          compression = "lz4";
          atime = "off";
          recordsize = "1M";
        };
      };
    };
    
    permissions = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Set file system permissions";
      };
      
      directories = mkOption {
        type = types.attrsOf types.str;
        default = {
          "~/.vscode" = "0755";
          "~/.vscode/extensions" = "0755";
          "~/projects" = "0755";
        };
      };
    };
    
    configuration = {
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "VS Code settings";
      };
      
      extensions = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "VS Code extensions";
      };
    };
    
    services = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable background services";
      };
    };
  };

  config = mkIf config.programs.vscode.enable {
    # ZFS Dataset Configuration
    systemd.services.vscode-zfs-dataset = mkIf config.programs.vscode.zfs.enable {
      description = "Create VS Code ZFS dataset";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # Create dataset if it doesn't exist
        if ! zfs list -o name ${config.programs.vscode.zfs.dataset} >/dev/null 2>&1; then
          zfs create -p ${concatStringsSep " " (mapAttrsToList (k: v: "-o ${k}=${v}") config.programs.vscode.zfs.properties)} ${config.programs.vscode.zfs.dataset}
          zfs mount ${config.programs.vscode.zfs.dataset}
        fi
      '';
    };

    # File System Permissions
    systemd.services.vscode-permissions = mkIf config.programs.vscode.permissions.enable {
      description = "Set VS Code file permissions";
      wantedBy = [ "multi-user.target" ];
      after = [ "vscode-zfs-dataset.service" ];
      serviceConfig.Type = "oneshot";
      script = concatStringsSep "\n" (mapAttrsToList (dir: perms: ''
        mkdir -p ${dir}
        chmod ${perms} ${dir}
        chown $USER:$USER ${dir}
      '') config.programs.vscode.permissions.directories);
    };

    # Package Installation
    environment.systemPackages = with pkgs; [
      vscode
    ] ++ config.programs.vscode.configuration.extensions;

    # Configuration Management
    home-manager.users.lars = {
      home.file.".vscode/settings.json".text = builtins.toJSON config.programs.vscode.configuration.settings;
      
      home.file.".vscode/extensions.json".text = builtins.toJSON {
        recommendations = map (ext: ext.publisher + "." + ext.name) config.programs.vscode.configuration.extensions;
      };
    };

    # Service Configuration
    systemd.services.vscode-background = mkIf config.programs.vscode.services.enable {
      description = "VS Code Background Services";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.vscode}/bin/code --server-data-dir ~/.vscode-server";
        Restart = "always";
        User = config.users.users.lars.name;
      };
    };

    # Shell Integration
    programs.zsh.shellAliases = {
      code = "code --user-data-dir ~/.vscode";
    };
  };
}
```

### flake-parts Integration

```nix
# flake.nix
{
  description = "Lars' Modular Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flakes/modules.nix
      ];

      systems = [ "aarch64-darwin" "x86_64-linux" ];

      # Per-system package definitions (auto-generated from program modules)
      perSystem = { config, pkgs, system, ... }: {
        packages = import ./programs { inherit pkgs lib; };
        
        # Development environments for each program category
        devShells = {
          development = pkgs.mkShell {
            packages = with pkgs; [ git vscode nodejs go ];
          };
          
          media = pkgs.mkShell {
            packages = with pkgs; [ blender audacity kdenlive ];
          };
        };
      };

      # System configurations
      flake = {
        darwinConfigurations."Lars-MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { 
              programs = {
                vscode.enable = true;
                vscode.zfs.enable = false; # Disable ZFS on macOS
                vscode.configuration.extensions = with pkgs.vscode-extensions; [
                  ms-vscode.cpptools
                  rust-lang.rust-analyzer
                ];
              };
            }
          ];
        };

        nixosConfigurations."evo-x2" = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              programs = {
                vscode.enable = true;
                vscode.zfs.dataset = "tank/data/vscode";
                vscode.permissions.directories = {
                  "/vscode" = "0755";
                  "/vscode/projects" = "0755";
                };
              };
            }
          ];
        };
      };
    };
}
```

## ✅ Benefits

1. **Complete Isolation**: Each program is self-contained with all its requirements
2. **ZFS Integration**: Native ZFS dataset management for data isolation and performance
3. **Permission Management**: Automated file system permissions for security
4. **Platform Awareness**: Same module works across Darwin and NixOS with platform-specific adaptations
5. **Dependency Management**: Clear dependency relationships between programs
6. **Service Integration**: Background services as part of program definition
7. **Configuration Management**: Embedded configuration with validation
8. **Development Environments**: Category-specific dev environments
9. **Type Safety**: Compile-time validation of program configurations
10. **Incremental Adoption**: Can migrate programs one at a time

## 🚀 Implementation Plan

### Phase 1: Foundation
1. Migrate existing flake.nix to flake-parts structure
2. Create program module template and helpers
3. Implement ZFS dataset management helpers
4. Create permission management utilities

### Phase 2: Core Programs
1. Migrate shell programs (fish, starship)
2. Migrate development tools (git, editors)
3. Migrate security tools (gpg, ssh)

### Phase 3: Advanced Features
1. Add service management integration
2. Implement cross-program dependencies
3. Add configuration validation
4. Create development environments

### Phase 4: Migration
1. Migrate all existing programs to new structure
2. Remove old wrapper system
3. Update documentation
4. Add tests for each module

## 🔍 Technical Considerations

### ZFS Integration
- Dataset creation only on ZFS-enabled systems
- Automatic property management (compression, recordsize, etc.)
- Snapshot management for program data
- Replication support for critical program data

### Cross-Platform Compatibility
- Conditional ZFS features (disable on non-ZFS systems)
- Platform-specific paths and permissions
- Service management differences (launchd vs systemd)

### Performance Optimization
- Lazy evaluation for expensive operations
- Caching of dataset checks
- Incremental permission application

### Security Considerations
- Principle of least privilege for permissions
- Secure default ZFS properties
- Validation of user-provided configurations

## 📋 Tasks

1. [ ] Design and implement program module template
2. [ ] Create helper libraries (ZFS, permissions, validation)
3. [ ] Migrate flake.nix to flake-parts
4. [ ] Implement core program modules
5. [ ] Add comprehensive testing
6. [ ] Create migration tooling for existing configs
7. [ ] Update documentation and examples

## 🤔 Questions for Discussion

1. Should we maintain backward compatibility with existing configurations?
2. How should we handle program dependencies and ordering?
3. Should we include version management within program modules?
4. How should we handle user customizations vs. module defaults?
5. Should we implement program lifecycle management (start/stop/restart)?

---

*This feature request represents a significant architectural improvement that would make the Setup-Mac configuration more modular, maintainable, and powerful while preserving the current functionality.*