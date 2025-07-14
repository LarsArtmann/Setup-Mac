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
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.larsartmann = { config, pkgs, lib, ... }: {
                home = {
                  username = "larsartmann";
                  homeDirectory = "/Users/larsartmann";
                  stateVersion = "25.05";
                };

                programs.home-manager.enable = true;

                # Basic shell configuration
                programs.bash = {
                  enable = true;
                  shellAliases = {
                    l = "ls -la";
                    t = "tree -h -L 2 -C --dirsfirst";
                    nixup = "darwin-rebuild switch";
                    c2p = "code2prompt . --output=code2prompt.md --tokens";
                    diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
                  };
                };

                programs.zsh = {
                  enable = true;
                  shellAliases = {
                    l = "ls -la";
                    t = "tree -h -L 2 -C --dirsfirst";
                    nixup = "darwin-rebuild switch";
                    c2p = "code2prompt . --output=code2prompt.md --tokens";
                    diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
                  };
                };

                home.sessionVariables = {
                  EDITOR = "nano";
                  LANG = "en_GB.UTF-8";
                };

                home.sessionPath = [
                  "$HOME/.local/bin"
                  "$HOME/go/bin"
                  "$HOME/.bun/bin"
                  "$HOME/.turso"
                  "$HOME/.orbstack/bin"
                  "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
                ];
              };
            };
          }
        ];
      };
    };
}
