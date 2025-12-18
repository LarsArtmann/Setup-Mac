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
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager }:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };

      # Import lib for ghost system dependencies
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        localSystem.system = "aarch64-darwin";
        stdenv.hostPlatform.system = "aarch64-darwin";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lars-MacBook-Air
      darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          # Core system configuration
          base

          ({ pkgs, ... }: {
            # Basic packages for development
            environment.systemPackages = with pkgs; [
              hello
              git
              neovim
              tmux
              curl
            ];
            system.stateVersion = 5;

            # Shells
            programs.zsh.enable = true;
            programs.bash.enable = true;

            # Home Manager integration
            users.users.larsartmann = {
              home = "/Users/larsartmann";
              shell = pkgs.zsh;
            };
          })

          # Home Manager integration
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.larsartmann = {
                home = {
                  username = "larsartmann";
                  homeDirectory = "/Users/larsartmann";
                  stateVersion = "25.11";
                };
                programs = {
                  zsh = {
                    enable = true;
                    shellAliases = {
                      ll = "ls -la";
                      update = "darwin-rebuild switch --flake .#Lars-MacBook-Air";
                    };
                  };
                };
              };
            };
          }
        ];
      };

      # Expose minimal packages
      packages.${pkgs.stdenv.hostPlatform.system}.hello = pkgs.hello;
    };
}
