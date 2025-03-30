{
  description = "Lars nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
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

  #TODO: Configure standard apps (e.g. what program is used when I open a .json file) for my mac in Nix config.

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew, ... }:
    let
      configuration = { pkgs, lib, overlays, ... }: {
        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # MacOS
        security.pam.services.sudo_local.touchIdAuth = true;
        # TODO: ADD https://mynixos.com/nix-darwin/options/security
        # TODO: ADD https://mynixos.com/nix-darwin/options/services.tailscale

        time.timeZone = null;

        nix = {
          enable = true;
          settings = {
            # Necessary for using flakes on this system.
            experimental-features = "nix-command flakes";
          };
          gc = {
            automatic = true;
            interval = { Hour = 0; Minute = 0; };
            options = "--delete-older-than 3d";
          };
          optimise = {
            automatic = true;
            interval = { Weekday = 0; Hour = 0; Minute = 0; };
          };
        };

        nixpkgs = {
          # The platform the configuration will be used on.
          hostPlatform = "aarch64-darwin";
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
            "vault" # ‘bsl11’ licence
            "terraform" # ‘bsl11’ licence
            #"cloudflare-warp" # ‘unfree’ licence
            "cursor" # ‘unfree’
          ];
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        modules = [
          # Core system configuration
          configuration
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
        ];
      };
    };
}
