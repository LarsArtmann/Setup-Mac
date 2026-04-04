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

    # SilentSDDM - customizable SDDM theme with Catppuccin support
    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SigNoz observability platform sources
    signoz-src = {
      url = "github:SigNoz/signoz/v0.117.1";
      flake = false;
    };
    signoz-collector-src = {
      url = "github:SigNoz/signoz-otel-collector/v0.144.2";
      flake = false;
    };

    nix-ssh-config = {
      url = "github:LarsArtmann/nix-ssh-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Crush AI Agent Configuration — global AI assistant settings
    # This ensures AGENTS.md and all references are synced across machines
    crush-config = {
      url = "github:LarsArtmann/crush-config";
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
    silent-sddm,
    signoz-src,
    signoz-collector-src,
    nix-ssh-config,
    ...
  }: let
    goOverlay = final: prev: {
      go = prev.go_1_26.overrideAttrs (oldAttrs: {
        version = "1.26.1";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go1.26.1.src.tar.gz";
          hash = "sha256-MXIpPQSyCdwRRGmOe6E/BHf2uoxf/QvmbCD9vJeF37s=";
        };
      });
    };

    awWatcherOverlay = final: prev: {
      aw-watcher-utilization = prev.callPackage ./pkgs/aw-watcher-utilization.nix {};
    };

    dnsblockdOverlay = final: prev: {
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
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

      # Import dendritic modules - each file is a self-contained flake-parts module
      imports = [
        ./modules/nixos/services/caddy.nix
        ./modules/nixos/services/default.nix
        ./modules/nixos/services/gitea.nix
        ./modules/nixos/services/gitea-repos.nix
        ./modules/nixos/services/grafana.nix
        ./modules/nixos/services/homepage.nix
        ./modules/nixos/services/immich.nix
        ./modules/nixos/services/monitoring.nix
        ./modules/nixos/services/signoz.nix
        ./modules/nixos/services/photomap.nix
        ./modules/nixos/services/sops.nix
        # SSH module now loaded from nix-ssh-config flake input
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
            goOverlay
            awWatcherOverlay
          ];
        };

        formatter = pkgs.alejandra;

        packages =
          {
            modernize = import ./pkgs/modernize.nix {
              inherit pkgs;
            };
            inherit (pkgs) aw-watcher-utilization;
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            dnsblockd = pkgs.callPackage ./pkgs/dnsblockd.nix {
              src = lib.cleanSourceWith {
                filter = path: type: baseNameOf path != "package.nix";
                src = ./platforms/nixos/programs/dnsblockd;
              };
            };
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
            {
              nixpkgs = {
                hostPlatform = "aarch64-darwin";
                config.allowUnfree = true;
                overlays = [
                  nur.overlays.default
                  awWatcherOverlay
                ];
              };
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
                users.larsartmann = {
                  config,
                  pkgs,
                  lib,
                  nix-colors,
                  nix-ssh-config,
                  ...
                }: {
                  imports = [
                    ./platforms/darwin/home.nix
                  ];
                };
                extraSpecialArgs = {
                  inherit nix-colors;
                  inherit nix-ssh-config;
                };
              };
            }

            # Core Darwin configuration
            ./platforms/darwin/default.nix
          ];
        };

        # NixOS configuration
        nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
            inherit niri;
            inherit otel-tui;
            inherit nix-amd-npu;
            inherit nix-ssh-config;
          };
          modules = [
            {
              nixpkgs = {
                hostPlatform = "x86_64-linux";
                config.allowUnfree = true;
                overlays = [
                  nur.overlays.default
                  inputs.niri.overlays.niri
                  goOverlay
                  awWatcherOverlay
                  dnsblockdOverlay
                  (final: prev: {
                    python313Packages = prev.python313Packages.overrideScope (pyFinal: pyPrev: {
                      timm = pyPrev.timm.overridePythonAttrs (old: {doCheck = false;});
                      xformers = pyPrev.xformers.overridePythonAttrs (old: {doCheck = false;});
                    });
                  })
                ];
              };
              system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            }
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                users.lars = {
                  config,
                  pkgs,
                  lib,
                  nix-colors,
                  nix-ssh-config,
                  ...
                }: {
                  imports = [
                    ./platforms/nixos/users/home.nix
                  ];
                };
                extraSpecialArgs = {
                  inherit nix-colors;
                  inherit nix-ssh-config;
                };
              };
            }

            # Import the existing NixOS configuration
            inputs.niri.nixosModules.niri
            inputs.nix-amd-npu.nixosModules.default
            inputs.sops-nix.nixosModules.sops
            inputs.silent-sddm.nixosModules.default
            inputs.self.nixosModules.caddy
            inputs.self.nixosModules.default-services
            inputs.self.nixosModules.gitea
            inputs.self.nixosModules.gitea-repos
            inputs.self.nixosModules.grafana
            inputs.self.nixosModules.homepage
            inputs.self.nixosModules.immich
            inputs.self.nixosModules.monitoring
            inputs.self.nixosModules.photomap
            inputs.self.nixosModules.sops
            inputs.nix-ssh-config.nixosModules.ssh
            inputs.self.nixosModules.signoz
            ./platforms/nixos/system/configuration.nix
          ];
        };
      };
    };
}
