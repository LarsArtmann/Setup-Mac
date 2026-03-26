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
    wrapper-modules,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

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

        packages = {
          modernize = import ./pkgs/modernize.nix {
            inherit pkgs;
          };
          aw-watcher-utilization = pkgs.callPackage ./pkgs/aw-watcher-utilization.nix {};

          # Wrapped niri with embedded configuration
          # Following the vimjoyer pattern: https://www.vimjoyer.com/vid79-parts-wrapped
          niri-wrapped = wrapper-modules.wrappers.niri.wrap {
            inherit pkgs; # CRITICAL: Must inherit pkgs!

            settings = {
              # Spawn terminal at startup
              spawn-at-startup = [
                ["kitty"]
              ];

              # XWayland support
              xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

              # Input configuration
              input = {
                keyboard = {
                  xkb = {
                    layout = "us";
                    variant = "";
                  };
                };
                touchpad = {
                  tap = true;
                  natural-scroll = true;
                  dwt = true;
                };
                mouse = {
                  natural-scroll = false;
                };
              };

              # Layout configuration
              layout = {
                gaps = 8;
                center-focused-column = "never";
                preset-column-widths = [
                  {proportion = 0.33333;}
                  {proportion = 0.5;}
                  {proportion = 0.66667;}
                ];
                default-column-width = {proportion = 0.5;};
              };

              # Focus ring
              focus-ring = {
                enable = true;
                width = 2;
                active = {
                  color = "#89b4fa"; # Catppuccin Mocha blue
                };
                inactive = {
                  color = "#45475a"; # Catppuccin Mocha surface0
                };
              };

              # Keybindings
              binds = {
                # Terminal
                "Mod+Return".spawn = ["kitty"];
                "Mod+Shift+Return".spawn = ["foot"];

                # Window management
                "Mod+Q".close-window = null;
                "Mod+Shift+Q".quit = null;

                # Focus movement
                "Mod+Left".focus-column-left = null;
                "Mod+Right".focus-column-right = null;
                "Mod+Up".focus-window-up = null;
                "Mod+Down".focus-window-down = null;
                "Mod+H".focus-column-left = null;
                "Mod+L".focus-column-right = null;
                "Mod+K".focus-window-up = null;
                "Mod+J".focus-window-down = null;

                # Move windows
                "Mod+Shift+Left".move-column-left = null;
                "Mod+Shift+Right".move-column-right = null;
                "Mod+Shift+Up".move-window-up = null;
                "Mod+Shift+Down".move-window-down = null;
                "Mod+Shift+H".move-column-left = null;
                "Mod+Shift+L".move-column-right = null;
                "Mod+Shift+K".move-window-up = null;
                "Mod+Shift+J".move-window-down = null;

                # Column width
                "Mod+BracketLeft".consume-window-into-column = null;
                "Mod+BracketRight".expel-window-from-column = null;
                "Mod+R".switch-preset-column-width = null;
                "Mod+Shift+R".reset-window-height = null;
                "Mod+Minus".set-column-width = "-10%";
                "Mod+Equal".set-column-width = "+10%";

                # Workspaces
                "Mod+1".focus-workspace = 1;
                "Mod+2".focus-workspace = 2;
                "Mod+3".focus-workspace = 3;
                "Mod+4".focus-workspace = 4;
                "Mod+5".focus-workspace = 5;
                "Mod+6".focus-workspace = 6;
                "Mod+7".focus-workspace = 7;
                "Mod+8".focus-workspace = 8;
                "Mod+9".focus-workspace = 9;

                "Mod+Shift+1".move-column-to-workspace = 1;
                "Mod+Shift+2".move-column-to-workspace = 2;
                "Mod+Shift+3".move-column-to-workspace = 3;
                "Mod+Shift+4".move-column-to-workspace = 4;
                "Mod+Shift+5".move-column-to-workspace = 5;
                "Mod+Shift+6".move-column-to-workspace = 6;
                "Mod+Shift+7".move-column-to-workspace = 7;
                "Mod+Shift+8".move-column-to-workspace = 8;
                "Mod+Shift+9".move-column-to-workspace = 9;

                # Apps
                "Mod+D".spawn-sh = "rofi -show drun";
                "Mod+Shift+E".spawn-sh = "emacs";
                "Mod+Shift+F".spawn-sh = "firefox";

                # System
                "Mod+Shift+L".spawn-sh = "hyprlock";
                "Mod+Shift+P".power-off-monitors = null;
                "Mod+Shift+S".suspend = null;

                # Screenshot
                "Print".spawn-sh = "grimblast copy area";
                "Shift+Print".spawn-sh = "grimblast save area ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png";

                # Audio
                "XF86AudioRaiseVolume" = {
                  spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
                  allow-when-locked = true;
                };
                "XF86AudioLowerVolume" = {
                  spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                  allow-when-locked = true;
                };
                "XF86AudioMute" = {
                  spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                  allow-when-locked = true;
                };

                # Brightness
                "XF86MonBrightnessUp" = {
                  spawn-sh = "brightnessctl set +5%";
                  allow-when-locked = true;
                };
                "XF86MonBrightnessDown" = {
                  spawn-sh = "brightnessctl set 5%-";
                  allow-when-locked = true;
                };
              };

              # Environment variables
              environment = {
                DISPLAY = ":0";
                WAYLAND_DISPLAY = "wayland-1";
              };
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
        # NixOS module for using wrapped niri
        nixosModules.niri-wrapped = {
          pkgs,
          lib,
          ...
        }: {
          programs.niri = {
            enable = true;
            # Use our wrapped package instead of the default
            package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.niri-wrapped;
          };

          # xwayland-satellite for X11 app support
          environment.systemPackages = with pkgs; [
            xwayland-satellite
          ];
        };

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
            ./platforms/nixos/system/configuration.nix
          ];
        };

        # Standalone Home Manager configurations for CLI use
        homeConfigurations = let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in {
          "evo-x2" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {inherit nix-colors;};
            modules = [
              ./platforms/nixos/users/home.nix
              {
                home.username = "lars";
                home.homeDirectory = "/home/lars";
              }
            ];
          };
        };
      };
    };
}
