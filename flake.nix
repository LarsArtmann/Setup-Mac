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
    nur.url = "github:nix-community/NUR";

    # Add llm-agents.nix for CRUSH and other AI tools
    llm-agents.url = "github:numtide/llm-agents.nix";

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
        };

        packages = {};

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
            inherit (inputs) llm-agents;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
          };
          modules = [
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
              };
            }

            # Import the existing NixOS configuration
            ./platforms/nixos/system/configuration.nix
          ];
        };
      };
    };
}
