{
  description = "Lars nix-darwin + NixOS system flake - Modular Architecture with flake-parts";

  inputs = {
    # Use nixpkgs-unstable to match nix-darwin master
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add flake-parts for modular architecture
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Add NUR (Nix User Repository) for other packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add llm-agents.nix for CRUSH and other AI tools
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helium Browser
    helium = {
      url = "github:vikingnope/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix-visualize for Nix configuration visualization
    nix-visualize = {
      url = "github:craigmbooth/nix-visualize";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix-colors for declarative color schemes
    nix-colors.url = "github:misterio77/nix-colors";

    # Add nix-homebrew for declarative Homebrew management
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Homebrew bundle for cask management
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    # Homebrew cask for headlamp and other GUI apps
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    nix-darwin,
    nixpkgs,
    home-manager,
    helium,
    nur,
    llm-agents,
    nix-visualize,
    nix-colors,
    nix-homebrew,
    homebrew-bundle,
    homebrew-cask,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

      # Per-system configuration (packages, devShells, etc.)
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        # Allow unfree and broken packages for all systems
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowBroken = false; ## <-- THIS MUST ALWAYS BE FALSE!
          overlays = [
            # Pin Go to version 1.26rc2 for all systems
            (final: prev: {
              go = prev.go_1_26;
              # Override buildGoModule to use Go 1.26 instead of default
              buildGoModule = prev.buildGo126Module;
            })
          ];
        };

        packages = {
          crush-patched = import ./pkgs/crush-patched.nix {
            inherit pkgs;
          };
          modernize = import ./pkgs/modernize.nix {
            inherit pkgs;
          };
        };

        # Development shells for different program categories
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              deadnix
              shellcheck
              just # Task runner
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
            inherit (inputs) llm-agents nixpkgs;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
          };
          modules = [
            # Pin Go to version 1.26rc2 for all packages in system
            {
              nixpkgs.overlays = [
                (final: prev: {
                  go = prev.go_1_26;
                  buildGoModule = prev.buildGo126Module;
                })
              ];
            }

            # Import nix-homebrew for declarative Homebrew management
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = "larsartmann";
                autoMigrate = true;
                # Pin Homebrew taps to flake inputs for reproducibility
                taps = {
                  "homebrew/bundle" = homebrew-bundle;
                  "homebrew/cask" = homebrew-cask;
                };
              };
            }

            # Import Home Manager module for Darwin
            inputs.home-manager.darwinModules.home-manager

            ## TODO: Why can't this be in it's how file?
            {
              # Home Manager configuration
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                users.larsartmann = import ./platforms/darwin/home.nix;
                extraSpecialArgs = {inherit nix-colors;};
              };
            }

            # Core Darwin configuration with Ghost Systems integration
            ./platforms/darwin/default.nix
          ];
        };

        # NixOS configuration
        nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit (inputs) llm-agents;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
          };
          modules = [
            # Core system configuration
            {
              system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
              # Allow unfree packages in NixOS
              nixpkgs.config.allowUnfree = true;

              # Add NUR overlay to make nur.repos available
              nixpkgs.overlays = [nur.overlays.default];
            }

            # Import Home Manager module for NixOS
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                users.lars = import ./platforms/nixos/users/home.nix;
                extraSpecialArgs = {inherit nix-colors;};
              };
            }

            # Import the existing NixOS configuration
            ./platforms/nixos/system/configuration.nix
          ];
        };

        # Standalone Home Manager configurations for CLI use
        homeConfigurations = let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in {
          "evo-x2" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {inherit nix-colors;};
            modules = [
              ./platforms/nixos/users/home.nix
              {
                home.username = "lars";
                home.homeDirectory = "/home/lars";
              }
            ];
          };
        };
      };
    };
}
