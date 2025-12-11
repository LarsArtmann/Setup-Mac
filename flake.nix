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

    # Hyprland for cutting edge window management
    hyprland = {
      url = "git+ssh://git@github.com/hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland Plugins
    hyprland-plugins = {
      url = "git+ssh://git@github.com/hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew, nixpkgs-nh-dev, home-manager, mac-app-util, nur, treefmt-nix, nix-ai-tools, wrappers, hyprland, hyprland-plugins, ... }@inputs:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };

      # Custom packages overlay (2025 best practice: modular)
      heliumOverlay = final: prev: {
        helium = final.callPackage ./dotfiles/nix/packages/helium.nix { };
      };

      # Hyprland overlay to ensure lock-step versions
      hyprlandOverlay = final: prev: {
        hyprland = hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
        hyprlandPlugins = hyprland-plugins.packages.${prev.stdenv.hostPlatform.system};
      };

      # Import lib for ghost system dependencies
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        localSystem.system = "aarch64-darwin";
        stdenv.hostPlatform.system = "aarch64-darwin";
      };

      # Cross-compilation packages for x86_64-linux - FIXED PROPERLY
      pkgsCross = import nixpkgs {
        localSystem.system = "x86_64-linux";
        config.allowUnsupportedSystem = true;
        config.allowUnfree = true;
      };

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
          # Temporarily disabled due to parameter passing issues
          # inherit TypeAssertions ConfigAssertions ModuleAssertions Types;
          # inherit UserConfig PathConfig State Validation;
        };
        modules = [
          # Apply custom packages overlay
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ heliumOverlay ]; })
          # Core system configuration
          base


          ./dotfiles/nix/core.nix

          # Ghost Systems - Type Safety & Assertion Frameworks (Phase 1 Integration)
          # Temporarily disabled due to parameter passing issues
          # ./dotfiles/nix/core/ConfigurationAssertions.nix
          # ./dotfiles/nix/core/SystemAssertions.nix

          ./dotfiles/nix/system.nix
          ./dotfiles/nix/modules/iterm2.nix

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

          # Home Manager integration - ENABLED
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";  # Backup existing files before overwriting
              extraSpecialArgs = {
                inherit inputs nixpkgs-nh-dev nur nix-ai-tools wrappers;
                # Ghost Systems - Type Safety & Validation (Phase 1 Integration)
                inherit TypeAssertions ConfigAssertions ModuleAssertions Types;
                inherit UserConfig PathConfig State Validation;
              };
              users.larsartmann = {
                home = {
                  username = "larsartmann";
                  homeDirectory = "/Users/larsartmann";
                  stateVersion = "25.11";
                };
                imports = [
                  ./dotfiles/nix/home.nix
                ];
              };
            };
          }
        ];
      };

      # Expose crush from nix-ai-tools as flake output
      packages.${pkgs.stdenv.hostPlatform.system}.crush = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.crush or null;

      # NixOS Configuration for GMKtec AMD Ryzen™ AI Max+ 395
      # Build using:
      # $ nix build .#nixosConfigurations.evo-x2.config.system.build.toplevel
      nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = pkgsCross;
        specialArgs = {
          inherit inputs nixpkgs-nh-dev nur nix-ai-tools wrappers;
          # Ghost Systems - Type Safety & Validation (Phase 1 Integration)
          inherit TypeAssertions ConfigAssertions ModuleAssertions Types;
          inherit UserConfig PathConfig State;
          # Validation removed - has Darwin-specific code
          # inherit Validation;
        };
        modules = [
          # Apply custom packages overlay
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ heliumOverlay hyprlandOverlay ]; })

          # Core system configuration
          base

      # Cross-platform base packages
          ./platforms/common/packages/base.nix

          # NixOS system configuration
          ./platforms/nixos/system/configuration.nix

          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs nixpkgs-nh-dev nur nix-ai-tools wrappers;
                inherit TypeAssertions ConfigAssertions ModuleAssertions Types;
                inherit UserConfig PathConfig State;
              };
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
    };
}
