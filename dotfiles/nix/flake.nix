{
  description = "Lars nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-nh-dev = {
      url = "github:viperML/nh/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew, nixpkgs-nh-dev, home-manager, ... }@inputs:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit nixpkgs-nh-dev; };
        modules = [
          # Core system configuration
          base
          ./core.nix
          ./system.nix

          # Environment and packages
          ./environment.nix
          #./packages.nix

          # Programs
          ./programs.nix

          # Homebrew integration
          ./homebrew.nix
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "larsartmann";

              # Enable fully-declarative tap management
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              #mutableTaps = false;
            };
          }

          ./networking.nix

          # User-specific configurations
          ./users.nix

          # Home Manager integration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.larsartmann = import ./home.nix;
          }
        ];
      };
    };
}
