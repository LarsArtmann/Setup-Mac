{
  description = "Lars nix-darwin + NixOS system flake";

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
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager }:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };

      # Import lib for ghost system dependencies
      lib = nixpkgs.lib;

      # System-specific package sets
      darwin-pkgs = import nixpkgs {
        localSystem.system = "aarch64-darwin";
        stdenv.hostPlatform.system = "aarch64-darwin";
      };

      linux-pkgs = import nixpkgs {
        localSystem.system = "x86_64-linux";
        stdenv.hostPlatform.system = "x86_64-linux";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit (self) inputs;
          nix-ai-tools = {};  # Placeholder for now - can be added later
        };
        modules = [
          # Test minimal configuration first
          ./platforms/darwin/test-darwin.nix
        ];
      };

      # Build NixOS flake using:
      # $ sudo nixos-rebuild build --flake .#evo-x2
      nixosConfigurations."evo-x2" = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (self) inputs;
          nix-ai-tools = {};  # Placeholder for now - can be added later
        };
        modules = [
          # Core system configuration
          base

          # Import the existing NixOS configuration
          ./platforms/nixos/system/configuration.nix

          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.lars = {
                home = {
                  username = "lars";
                  homeDirectory = "/home/lars";
                  stateVersion = "25.11";
                };
                imports = [
                  ./platforms/nixos/users/home.nix
                ];
              };
            };
          }
        ];
      };

      # Expose minimal packages for both systems
      packages.${darwin-pkgs.stdenv.hostPlatform.system}.hello = darwin-pkgs.hello;
      packages.${linux-pkgs.stdenv.hostPlatform.system}.hello = linux-pkgs.hello;
    };
}
