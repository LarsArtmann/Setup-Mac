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
      imports = [
        # Import custom modules for program management (will be added back when working)
        # ./flakes/modules.nix
      ];

      systems = [ "aarch64-darwin" "x86_64-linux" ];

      # Per-system configuration (packages, devShells, etc.)
      perSystem = { config, pkgs, system, ... }: {
        # Allow unfree and broken packages for all systems
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowBroken = true;
        };
        
        # Legacy packages for backward compatibility
        packages.hello = pkgs.hello;
        
        # New program modules will be auto-generated here
        # packages = import ./programs { inherit pkgs lib; };

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

        # NixOS configuration temporarily disabled for testing
        # nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   specialArgs = {
        #     inherit (inputs.self) inputs;
        #     nix-ai-tools = {};
        #   };
        #   modules = [
        #     # Core system configuration
        #     {
        #       system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        #     }

        #     # Import the existing NixOS configuration
        #     ./platforms/nixos/system/configuration.nix

        #     # Home Manager integration
        #     home-manager.nixosModules.home-manager
        #     {
        #       home-manager = {
        #         useGlobalPkgs = true;
        #         useUserPackages = true;
        #         users.lars = {
        #           home = {
        #             username = "lars";
        #             homeDirectory = "/home/lars";
        #             stateVersion = "25.11";
        #           };
        #           imports = [
        #             ./platforms/nixos/users/home.nix
        #           ];
        #         };
        #       }
        #     }
        #   ];
        # };
      };
    };
}