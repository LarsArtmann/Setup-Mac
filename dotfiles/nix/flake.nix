{
  description = "Lars nix-darwin system flake";

  inputs = {
    # GPGME 1.24.2 is currently broken in nixpkgs-unstable (marked as broken)
    # GPGME 1.24.3 was released on May 19, 2025 to fix these issues
    # Last nixpkgs update: Feb 20, 2025 (commit 5032ae4) - updated to 1.24.2
    # No PR for 1.24.3 found yet - waiting for community update
    # See: https://github.com/NixOS/nixpkgs/commits/master/pkgs/development/libraries/gpgme
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
    mac-app-util.url = "github:hraban/mac-app-util";
    
    # Nix User Repository for community packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # treefmt-nix for unified code formatting
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew, nixpkgs-nh-dev, home-manager, mac-app-util, nur, treefmt-nix, ... }@inputs:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit nixpkgs-nh-dev nur; };
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

          # NUR community packages - enabled with enhanced configuration
          ./nur.nix

          # Code formatting with treefmt - enabled with comprehensive formatters
          ./treefmt.nix

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

          # mac-app-util for Spotlight integration
          mac-app-util.darwinModules.default

          # Home Manager integration - temporarily disabled to migrate configs
          # home-manager.darwinModules.home-manager
          # {
          #   home-manager = {
          #     useGlobalPkgs = true;
          #     useUserPackages = true;
          #     extraSpecialArgs = { inherit inputs; };
          #     users.larsartmann = ./home.nix;
          #   };
          # }
        ];
      };
    };
}
