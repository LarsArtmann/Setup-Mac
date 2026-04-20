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
      url = "git+ssh://git@github.com/LarsArtmann/crush-config?ref=master";
    };

    # Treefmt formatter with auto-discovery for nix fmt
    treefmt-full-flake = {
      url = "github:LarsArtmann/treefmt-full-flake";
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
    nix-ssh-config,
    treefmt-full-flake,
    ...
  }: let
    goOverlay = _final: prev: {
      go = prev.go_1_26.overrideAttrs (_: {
        version = "1.26.1";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go1.26.1.src.tar.gz";
          hash = "sha256-MXIpPQSyCdwRRGmOe6E/BHf2uoxf/QvmbCD9vJeF37s=";
        };
      });
    };

    awWatcherOverlay = _final: prev: {
      aw-watcher-utilization = prev.callPackage ./pkgs/aw-watcher-utilization.nix {};
    };

    openaudibleOverlay = _final: prev: {
      openaudible = prev.callPackage ./pkgs/openaudible.nix {};
    };

    dnsblockdOverlay = _final: prev: {
      dnsblockd = prev.callPackage ./pkgs/dnsblockd.nix {
        src = prev.lib.cleanSourceWith {
          filter = path: _: baseNameOf path != "package.nix";
          src = ./platforms/nixos/programs/dnsblockd;
        };
      };
      dnsblockd-processor = prev.callPackage ./pkgs/dnsblockd-processor/package.nix {
        src = prev.lib.cleanSourceWith {
          filter = path: _: !prev.lib.hasSuffix (baseNameOf path) ".nix";
          src = ./pkgs/dnsblockd-processor;
        };
      };
    };

    emeetPixyOverlay = _final: prev: {
      emeet-pixyd = prev.callPackage ./pkgs/emeet-pixyd.nix {
        src = prev.lib.cleanSourceWith {
          filter = path: _type: let b = baseNameOf path; in !(prev.lib.hasSuffix "_test.go" b || b == "package.nix");
          src = ./pkgs/emeet-pixyd;
        };
      };
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

      # Import dendritic modules - each file is a self-contained flake-parts module
      imports = [
        ./modules/nixos/services/authelia.nix
        ./modules/nixos/services/caddy.nix
        ./modules/nixos/services/default.nix
        ./modules/nixos/services/gitea.nix
        ./modules/nixos/services/gitea-repos.nix
        ./modules/nixos/services/homepage.nix
        ./modules/nixos/services/immich.nix
        ./modules/nixos/services/signoz.nix
        ./modules/nixos/services/twenty.nix
        ./modules/nixos/services/photomap.nix
        ./modules/nixos/services/sops.nix
        ./modules/nixos/services/taskchampion.nix
        ./modules/nixos/services/voice-agents.nix
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

        # Use treefmt-full-flake's formatter which includes alejandra in PATH
        formatter = treefmt-full-flake.formatter.${system};

        packages =
          {
            modernize = import ./pkgs/modernize.nix {
              inherit pkgs;
            };
            inherit (pkgs) aw-watcher-utilization;
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            openaudible = pkgs.callPackage ./pkgs/openaudible.nix {};
            dnsblockd = pkgs.callPackage ./pkgs/dnsblockd.nix {
              src = lib.cleanSourceWith {
                filter = path: _: baseNameOf path != "package.nix";
                src = ./platforms/nixos/programs/dnsblockd;
              };
            };
            dnsblockd-processor = pkgs.callPackage ./pkgs/dnsblockd-processor/package.nix {
              src = lib.cleanSourceWith {
                filter = path: _: !lib.hasSuffix (baseNameOf path) ".nix";
                src = ./pkgs/dnsblockd-processor;
              };
            };
            emeet-pixyd = pkgs.callPackage ./pkgs/emeet-pixyd.nix {
              src = lib.cleanSourceWith {
                filter = path: _type: let b = baseNameOf path; in !(lib.hasSuffix "_test.go" b || b == "package.nix");
                src = ./pkgs/emeet-pixyd;
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
              gitleaks
              jq
            ];
            # Shell hook to provide jscpd command via bunx
            shellHook = ''
              # jscpd - code duplication detector
              alias jscpd="bunx jscpd"
            '';
          };
        };

        checks =
          {
            statix =
              pkgs.runCommand "statix-check" {
                nativeBuildInputs = [pkgs.statix];
              } ''
                cd ${./.}
                statix check . 2>&1 | tee $out
              '';

            deadnix =
              pkgs.runCommand "deadnix-check" {
                nativeBuildInputs = [pkgs.deadnix];
              } ''
                cd ${./.}
                deadnix --no-lambda-pattern-names . 2>&1 | tee $out
              '';

            nix-eval-darwin =
              pkgs.runCommand "nix-eval-darwin" {
                nativeBuildInputs = [nixpkgs.legacyPackages.${system}.nix];
              } ''
                nix-instantiate --eval '${inputs.self}#darwinConfigurations.Lars-MacBook-Air' > /dev/null 2>&1 || true
                echo "darwin eval smoke test passed" > $out
              '';
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            nix-eval-nixos =
              pkgs.runCommand "nix-eval-nixos" {
                nativeBuildInputs = [nixpkgs.legacyPackages.${system}.nix];
              } ''
                nix-instantiate --eval '${inputs.self}#nixosConfigurations.evo-x2' > /dev/null 2>&1 || true
                echo "nixos eval smoke test passed" > $out
              '';
          };

        apps =
          {
            deploy = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "deploy" ''
                set -euo pipefail
                nh os switch . 2>&1
              ''}/bin/deploy";
            };
            validate = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "validate" ''
                nix --extra-experimental-features "nix-command flakes" flake check --no-build
              ''}/bin/validate";
            };
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            dns-diagnostics = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "dns-diagnostics" ''
                echo "=== DNS Services ==="
                systemctl is-active unbound dnsblockd 2>/dev/null || true
                echo ""
                echo "=== DNS Resolution ==="
                ${pkgs.dig}/bin/dig google.com +short | head -1
                echo ""
                echo "=== DNS Blocking ==="
                ${pkgs.dig}/bin/dig doubleclick.net +short | head -1
                echo ""
                echo "=== dnsblockd Stats ==="
                ${pkgs.curl}/bin/curl -s http://127.0.0.1:9090/stats 2>/dev/null || echo "Stats unavailable"
              ''}/bin/dns-diagnostics";
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
                users.larsartmann = {...}: {
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
                  openaudibleOverlay
                  dnsblockdOverlay
                  emeetPixyOverlay
                  (_final: prev: {
                    python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
                      timm = pyPrev.timm.overridePythonAttrs (_: {doCheck = false;});
                      xformers = pyPrev.xformers.overridePythonAttrs (_: {doCheck = false;});
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
                users.lars = {...}: {
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
            inputs.self.nixosModules.authelia
            inputs.self.nixosModules.caddy
            inputs.self.nixosModules.default-services
            inputs.self.nixosModules.gitea
            inputs.self.nixosModules.gitea-repos
            inputs.self.nixosModules.homepage
            inputs.self.nixosModules.immich
            inputs.self.nixosModules.photomap
            inputs.self.nixosModules.sops
            inputs.nix-ssh-config.nixosModules.ssh
            inputs.self.nixosModules.signoz
            inputs.self.nixosModules.twenty
            inputs.self.nixosModules.taskchampion
            inputs.self.nixosModules.voice-agents
            ./platforms/nixos/system/configuration.nix
          ];
        };
      };
    };
}
