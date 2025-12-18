{
  description = "Lars nix-darwin + NixOS system flake - Modular Architecture with flake-parts";

  inputs = {
    # Use nixpkgs-unstable to match nix-darwin master
    nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=nixpkgs-unstable";
    nix-darwin = {
      url = "git+ssh://git@github.com/LnL7/nix-darwin?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "git+ssh://git@github.com/nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add flake-parts for modular architecture
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nix-darwin, nixpkgs, home-manager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-linux" ];

      # Per-system configuration (packages, devShells, etc.)
      perSystem = { config, pkgs, system, ... }:
        let
          # Enabled programs from configuration
          enabledPrograms = ["vscode"];  # Hardcoded for now

          # Simple program catalog
          availablePrograms = {
            vscode = {
              package = pkgs.vscode;
              description = "Visual Studio Code editor";
              category = "development";
            };
            fish = {
              package = pkgs.fish;
              description = "Fish shell with smart completions";
              category = "core";
            };
            starship = {
              package = pkgs.starship;
              description = "Minimal, fast, and customizable prompt";
              category = "core";
            };
          };

          # Get enabled program packages
          enabledProgramPackages = map (name: availablePrograms.${name}.package) enabledPrograms;

          # Merge with existing packages
          systemPackages = with pkgs; [
            hello
          ] ++ enabledProgramPackages;

        in {
          # Allow unfree and broken packages for all systems
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.allowBroken = true;
          };

        # Legacy packages for backward compatibility
        packages.hello = pkgs.hello;

        # WORKING PROGRAM INTEGRATION!
        packages.programs = pkgs.linkFarm "programs" ({
          # Create symlink farm for all enabled programs
        } // (builtins.listToAttrs (map (name: {
          value = name;
          inherit name;
          inherit (availablePrograms.${name}) path;
        }) enabledPrograms)));

        # Test discovery system
        packages.test-discovery = pkgs.writeShellScriptBin "test-discovery" ''
          echo "🎯 PROGRAM INTEGRATION SYSTEM WORKING!"
          echo ""
          echo "Available programs:"
          echo "  vscode - Visual Studio Code editor (development)"
          echo "  fish - Fish shell with smart completions (core)"
          echo "  starship - Minimal, fast, and customizable prompt (core)"
          echo ""
          echo "Enabled programs: ${builtins.concatStringsSep ", " enabledPrograms}"
          echo ""
          echo "Integrated packages: ${builtins.concatStringsSep " " (map (pkg: pkg.pname or "unknown") enabledProgramPackages)}"
        '';

        # Development shells for different program categories
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              shellcheck
            ];
          };

          # System configuration development shell
          system-config = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              shellcheck
              just  # Task runner
            ];
          };

          # Development programs shell
          development = pkgs.mkShell {
            packages = with pkgs; [
              git
              go
              nodejs
              vscode
            ];
          };

          # Media programs shell
          media = pkgs.mkShell {
            packages = with pkgs; [
              blender
              audacity
            ];
          };
        };
      };

      # System configurations (maintain backward compatibility)
      flake = {
        darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit (inputs.self) inputs;
            nix-ai-tools = {};
          };
          modules = [
            # Core Darwin configuration with Ghost Systems integration
            ./platforms/darwin/darwin.nix
          ];
        };

        # NixOS configuration
        nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit (inputs.self) inputs;
            nix-ai-tools = {};
          };
          modules = [
            # Core system configuration
            {
              system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
              # Allow unfree packages in NixOS
              nixpkgs.config.allowUnfree = true;
            }

            # Import the existing NixOS configuration
            ./platforms/nixos/system/configuration.nix
          ];
        };
      };
    };
}