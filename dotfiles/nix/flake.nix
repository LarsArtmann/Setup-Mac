{
  description = "Lars nix-darwin system flake";

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

    nixpkgs-nh-dev = {
      url = "git+ssh://git@github.com/viperML/nh?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "git+ssh://git@github.com/zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "git+ssh://git@github.com/homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "git+ssh://git@github.com/homebrew/homebrew-cask";
      flake = false;
    };
    colmena.url = "git+ssh://git@github.com/zhaofengli/colmena";
    mac-app-util.url = "git+ssh://git@github.com/hraban/mac-app-util";

    # Nix User Repository for community packages
    nur = {
      url = "git+ssh://git@github.com/nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt-nix for unified code formatting
    treefmt-nix = {
      url = "git+ssh://git@github.com/numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # comprehensive formatter collection (SSH) - temporarily disabled due to connectivity issues
    # treefmt-full-flake = {
    #   url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # nix-ai-tools for AI development tools like crush - ENABLED for latest crush
    nix-ai-tools = {
      url = "git+ssh://git@github.com/numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # lassulus/wrappers for advanced software wrapping system
    wrappers = {
      url = "git+ssh://git@github.com/lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew, nixpkgs-nh-dev, home-manager, mac-app-util, nur, treefmt-nix, nix-ai-tools, wrappers, ... }@inputs:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };

      # System package set
      localSystem = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${localSystem};

      # Custom packages overlay (2025 best practice: modular)
      heliumOverlay = final: prev: {
        helium = final.callPackage ./packages/helium.nix { };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs nixpkgs-nh-dev nur nix-ai-tools wrappers; };
        modules = [
          # Apply custom packages overlay
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ heliumOverlay ]; })
          # Core system configuration
          base


          ./core.nix
          ./system.nix

          # Environment and packages
          ./environment.nix
          #./packages.nix

          # Programs
          ./programs.nix

          # ActivityWatch auto-start configuration
          ./activitywatch.nix

          # NUR community packages - enabled with enhanced configuration
          ./nur.nix

          # Code formatting with treefmt - temporarily disabled due to compatibility issues
          # ./treefmt.nix

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

          # Home Manager integration - enabled for ghost-btop-wallpaper
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.larsartmann = ./home.nix;
            };
          }
        ];
      };

      # Expose crush from nix-ai-tools as flake output
      packages.${pkgs.system}.crush = inputs.nix-ai-tools.packages.${pkgs.system}.crush or null;
    };
}
