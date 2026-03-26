# Wrapped Niri Module
#
# This module creates a wrapped niri package with embedded configuration.
# Following the vimjoyer pattern from: https://www.vimjoyer.com/vid79-parts-wrapped
#
# Benefits:
# - Configuration is embedded in the package itself
# - Self-contained wrapped program
# - Can reference other wrapped packages from the same flake
{
  self,
  inputs,
  ...
}: {
  # NixOS module that enables niri and uses our wrapped package
  flake.nixosModules.niri-wrapped = {
    pkgs,
    lib,
    ...
  }: {
    programs.niri = {
      enable = true;
      # Use our wrapped package instead of the default
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri-wrapped;
    };

    # xwayland-satellite for X11 app support
    environment.systemPackages = with pkgs; [
      xwayland-satellite
    ];
  };

  # Per-system package definition for the wrapped niri
  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: {
    packages.niri-wrapped = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # CRITICAL: Must inherit pkgs!

      settings = {
        # Spawn terminal at startup
        spawn-at-startup = [
          {
            command = ["kitty"];
          }
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
          "Mod+Return".spawn = "kitty";
          "Mod+Shift+Return".spawn = "foot";

          # Window management
          "Mod+Q".close-window = [];
          "Mod+Shift+Q".quit = [];

          # Focus movement
          "Mod+Left".focus-column-left = [];
          "Mod+Right".focus-column-right = [];
          "Mod+Up".focus-window-up = [];
          "Mod+Down".focus-window-down = [];
          "Mod+H".focus-column-left = [];
          "Mod+L".focus-column-right = [];
          "Mod+K".focus-window-up = [];
          "Mod+J".focus-window-down = [];

          # Move windows
          "Mod+Shift+Left".move-column-left = [];
          "Mod+Shift+Right".move-column-right = [];
          "Mod+Shift+Up".move-window-up = [];
          "Mod+Shift+Down".move-window-down = [];
          "Mod+Shift+H".move-column-left = [];
          "Mod+Shift+L".move-column-right = [];
          "Mod+Shift+K".move-window-up = [];
          "Mod+Shift+J".move-window-down = [];

          # Column width
          "Mod+BracketLeft".consume-window-into-column = [];
          "Mod+BracketRight".expel-window-from-column = [];
          "Mod+R".switch-preset-column-width = [];
          "Mod+Shift+R".reset-window-height = [];
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
          "Mod+D".spawn = "rofi -show drun";
          "Mod+Shift+E".spawn = "emacs";
          "Mod+Shift+F".spawn = "firefox";

          # System
          "Mod+Shift+L".spawn = "hyprlock";
          "Mod+Shift+P".power-off-monitors = [];
          "Mod+Shift+S".suspend = [];

          # Screenshot
          "Print".spawn = "grimblast copy area";
          "Shift+Print".spawn = "grimblast save area ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png";

          # Audio
          "XF86AudioRaiseVolume" = {
            spawn = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
            allow-when-locked = true;
          };
          "XF86AudioLowerVolume" = {
            spawn = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            allow-when-locked = true;
          };
          "XF86AudioMute" = {
            spawn = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            allow-when-locked = true;
          };

          # Brightness
          "XF86MonBrightnessUp" = {
            spawn = "brightnessctl set +5%";
            allow-when-locked = true;
          };
          "XF86MonBrightnessDown" = {
            spawn = "brightnessctl set 5%-";
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
}
