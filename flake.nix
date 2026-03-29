{
  description = "Lars nix-darwin + NixOS system flake - Modular Architecture with flake-parts";

  inputs = {
    # Use nixpkgs-unstable to match nix-darwin master
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add flake-parts for modular architecture
    flake-parts.url = "github:hercules-ci/flake-parts";

    # wrapper-modules for creating configured/wrapped packages
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    # Add NUR (Nix User Repository) for other packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helium Browser
    helium = {
      url = "github:vikingnope/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix-visualize for Nix configuration visualization
    nix-visualize = {
      url = "github:craigmbooth/nix-visualize";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix-colors for declarative color schemes
    nix-colors.url = "github:misterio77/nix-colors";

    # Add nix-homebrew for declarative Homebrew management
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Homebrew bundle for cask management
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    # Homebrew cask for headlamp and other GUI apps
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # Niri scrollable-tiling Wayland compositor
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenTelemetry TUI viewer
    otel-tui = {
      url = "github:ymtdzzz/otel-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AMD NPU (XDNA) driver for Ryzen AI Max+ Strix Halo
    nix-amd-npu = {
      url = "github:robcohen/nix-amd-npu";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management via sops + age
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nix-darwin,
    nixpkgs,
    home-manager,
    helium,
    nur,
    nix-visualize,
    nix-colors,
    nix-homebrew,
    homebrew-bundle,
    homebrew-cask,
    niri,
    otel-tui,
    nix-amd-npu,
    sops-nix,
    wrapper-modules,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

      # Import dendritic modules - each file is a self-contained flake-parts module
      imports = [
        ./modules/nixos/services/immich.nix
        ./modules/nixos/services/gitea.nix
        ./modules/nixos/services/caddy.nix
        ./modules/nixos/services/grafana.nix
        ./modules/nixos/services/ssh.nix
      ];

      # Per-system configuration (packages, devShells, etc.)
      perSystem = {
        pkgs,
        system,
        lib,
        ...
      }: {
        # Allow unfree and broken packages for all systems
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowBroken = false; ## <-- THIS MUST ALWAYS BE FALSE!
          overlays = [
            # Pin Go to version 1.26.1 for all systems
            # Note: buildGo126Module already exists in nixpkgs, no need to override buildGoModule
            (final: prev: {
              go = prev.go_1_26.overrideAttrs (oldAttrs: {
                version = "1.26.1";
                src = prev.fetchurl {
                  url = "https://go.dev/dl/go1.26.1.src.tar.gz";
                  hash = "sha256-MXIpPQSyCdwRRGmOe6E/BHf2uoxf/QvmbCD9vJeF37s=";
                };
              });
            })
            # Custom ActivityWatch watcher for system utilization monitoring
            (final: prev: {
              aw-watcher-utilization = prev.callPackage ./pkgs/aw-watcher-utilization.nix {};
            })
          ];
        };

        formatter = pkgs.alejandra;

        packages =
          {
            modernize = import ./pkgs/modernize.nix {
              inherit pkgs;
            };
            aw-watcher-utilization = pkgs.callPackage ./pkgs/aw-watcher-utilization.nix {};
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            # dnsblockd - serves HTML block pages for DNS-filtered domains
            dnsblockd = pkgs.callPackage ./pkgs/dnsblockd.nix {
              src = lib.cleanSourceWith {
                filter = path: type: baseNameOf path != "package.nix";
                src = ./platforms/nixos/programs/dnsblockd;
              };
            };
            # dnsblockd-processor - Go tool to merge/dedup blocklists at build time (replaces slow Nix eval)
            dnsblockd-processor = pkgs.callPackage ./pkgs/dnsblockd-processor/package.nix {
              src = lib.cleanSourceWith {
                filter = path: type: !lib.hasSuffix (baseNameOf path) ".nix";
                src = ./pkgs/dnsblockd-processor;
              };
            };
          };

        # Development shells for different program categories
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              alejandra
              treefmt
              deadnix
              shellcheck
              just # Task runner
              statix
            ];
            # Shell hook to provide jscpd command via bunx
            shellHook = ''
              # jscpd - code duplication detector
              alias jscpd="bunx jscpd"
            '';
          };
        };
      };

      # System configurations (maintain backward compatibility)
      flake = {
        darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit nixpkgs;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
            inherit otel-tui;
          };
          modules = [
            # Pin Go to version 1.26 for all packages in system
            {
              nixpkgs.overlays = [
                (final: prev: {
                  go = prev.go_1_26.overrideAttrs (oldAttrs: {
                    version = "1.26.1";
                    src = prev.fetchurl {
                      url = "https://go.dev/dl/go1.26.1.src.tar.gz";
                      hash = "sha256-MXIpPQSyCdwRRGmOe6E/BHf2uoxf/QvmbCD9vJeF37s=";
                    };
                  });
                  buildGo126Module = prev.buildGoModule.override {inherit (final) go;};
                  buildGoModule = prev.buildGoModule.override {inherit (final) go;};
                })
                # Custom ActivityWatch watcher for system utilization monitoring
                (final: prev: {
                  aw-watcher-utilization = prev.callPackage ./pkgs/aw-watcher-utilization.nix {};
                })
              ];
            }

            # Import nix-homebrew for declarative Homebrew management
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = "larsartmann";
                autoMigrate = true;
                # Pin Homebrew taps to flake inputs for reproducibility
                taps = {
                  "homebrew/bundle" = homebrew-bundle;
                  "homebrew/cask" = homebrew-cask;
                };
              };
            }

            # Import Home Manager module for Darwin
            inputs.home-manager.darwinModules.home-manager

            # Define Home Manager configuration inline for top-level visibility
            {
              # Home Manager configuration
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                users.larsartmann = import ./platforms/darwin/home.nix;
                extraSpecialArgs = {inherit nix-colors;};
              };
            }

            # Core Darwin configuration with Ghost Systems integration
            ./platforms/darwin/default.nix
          ];
        };

        # NixOS configuration
        nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
            inherit niri;
            inherit otel-tui;
          };
          modules = [
            # Core system configuration
            {
              system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
              # Allow unfree packages in NixOS
              nixpkgs.config.allowUnfree = true;

              # Add NUR overlay to make nur.repos available
              nixpkgs.overlays = [
                nur.overlays.default
                # Niri flake overlay for stable/unstable packages
                inputs.niri.overlays.niri
                # Custom ActivityWatch watcher for system utilization monitoring
                (final: prev: {
                  aw-watcher-utilization = prev.callPackage ./pkgs/aw-watcher-utilization.nix {};
                })
                # dnsblockd - DNS block page server + blocklist processor
                (final: prev: {
                  dnsblockd = prev.callPackage ./pkgs/dnsblockd.nix {
                    src = prev.lib.cleanSourceWith {
                      filter = path: type: baseNameOf path != "package.nix";
                      src = ./platforms/nixos/programs/dnsblockd;
                    };
                  };
                  dnsblockd-processor = prev.callPackage ./pkgs/dnsblockd-processor/package.nix {
                    src = prev.lib.cleanSourceWith {
                      filter = path: type: !prev.lib.hasSuffix (baseNameOf path) ".nix";
                      src = ./pkgs/dnsblockd-processor;
                    };
                  };
                })
              ];
            }

            # Import Home Manager module for NixOS
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                users.lars = import ./platforms/nixos/users/home.nix;
                extraSpecialArgs = {inherit nix-colors;};
              };
            }

            # Import the existing NixOS configuration
            inputs.niri.nixosModules.niri
            inputs.nix-amd-npu.nixosModules.default
            inputs.sops-nix.nixosModules.sops
            inputs.self.nixosModules.immich
            inputs.self.nixosModules.gitea
            inputs.self.nixosModules.caddy
            inputs.self.nixosModules.grafana
            inputs.self.nixosModules.ssh
            ./platforms/nixos/system/configuration.nix
          ];
        };
      };
    };
}
