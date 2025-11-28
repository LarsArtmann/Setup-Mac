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

      # Custom packages overlay (2025 best practice: modular)
      heliumOverlay = final: prev: {
        helium = final.callPackage ./dotfiles/nix/packages/helium.nix { };
      };

      # Import lib for ghost system dependencies
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { system = "aarch64-darwin"; };

      # GHOST SYSTEMS INTEGRATION - Phase 1: Type Safety & Validation
      # Pure libraries (no dependencies) - imported first
      TypeAssertions = import ./dotfiles/nix/core/TypeAssertions.nix { inherit lib; };
      ConfigAssertions = import ./dotfiles/nix/core/ConfigAssertions.nix { inherit lib; };
      ModuleAssertions = import ./dotfiles/nix/core/ModuleAssertions.nix { inherit lib pkgs; };
      Types = import ./dotfiles/nix/core/Types.nix { inherit lib pkgs; };

      # Configuration dependencies for State.nix
      UserConfig = import ./dotfiles/nix/core/UserConfig.nix { inherit lib; };
      PathConfig = import ./dotfiles/nix/core/PathConfig.nix { inherit lib; };

      # State management with injected dependencies (eliminates circular imports)
      State = import ./dotfiles/nix/core/State.nix {
        inherit lib pkgs UserConfig PathConfig;
      };

      # Validation system with full dependency chain
      Validation = import ./dotfiles/nix/core/Validation.nix {
        inherit lib pkgs State Types;
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs nixpkgs-nh-dev nur nix-ai-tools wrappers;
          # Ghost Systems - Type Safety & Validation (Phase 1 Integration)
          inherit TypeAssertions ConfigAssertions ModuleAssertions Types;
          inherit UserConfig PathConfig State Validation;
        };
        modules = [
          # Apply custom packages overlay
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ heliumOverlay ]; })
          # Core system configuration
          base


          ./dotfiles/nix/core.nix

          # Ghost Systems - Type Safety & Assertion Frameworks (Phase 1 Integration)
          ./dotfiles/nix/core/TypeSafetySystem.nix
          ./dotfiles/nix/core/SystemAssertions.nix

          ./dotfiles/nix/system.nix

          # Environment and packages
          ./dotfiles/nix/environment.nix
          #./packages.nix

          # Programs
          ./dotfiles/nix/programs.nix

          # Enhanced wrapper system for dynamic library management
          ./dotfiles/nix/wrappers/default.nix

          # ActivityWatch auto-start configuration
          ./dotfiles/nix/activitywatch.nix

          # NUR community packages - enabled with enhanced configuration
          ./dotfiles/nix/nur.nix

          # Code formatting with treefmt - temporarily disabled due to compatibility issues
          # ./treefmt.nix

          # Homebrew integration
          ./dotfiles/nix/homebrew.nix
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

          ./dotfiles/nix/networking.nix

          # User-specific configurations
          ./dotfiles/nix/users.nix

          # mac-app-util for Spotlight integration
          mac-app-util.darwinModules.default

          # Home Manager integration - re-enabled for user configuration
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.larsartmann = ./dotfiles/nix/home.nix;
            };
          }
        ];
      };

      # Expose crush from nix-ai-tools as flake output
      packages.${pkgs.system}.crush = inputs.nix-ai-tools.packages.${pkgs.system}.crush or null;
    };
}
