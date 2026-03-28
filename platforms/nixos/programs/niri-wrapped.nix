{
  pkgs,
  lib,
  ...
}: {
  programs.niri.settings = {
    prefer-no-csd = true;

    screenshot-path = "~/Pictures/screenshots/%Y-%m-%d %H-%M-%S.png";

    spawn-at-startup = [
      {argv = ["kitty"];}
    ];

    xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

    input = {
      keyboard = {
        xkb = {
          layout = "us";
          variant = "";
        };
        repeat-delay = 300;
        repeat-rate = 50;
        track-layout = "window";
      };

      touchpad = {
        tap = true;
        dwt = true;
        dwtp = true;
        natural-scroll = true;
        tap-button-map = "left-middle-right";
        click-method = "clickfinger";
      };

      mouse = {
        natural-scroll = false;
        accel-profile = "flat";
      };

      trackball = {
        scroll-method = "on-button-down";
        scroll-button = 273;
      };

      tablet = {
        map-to-output = "eDP-1";
      };

      warp-mouse-to-focus.enable = true;
      focus-follows-mouse = {
        max-scroll-amount = "10%";
      };
      workspace-auto-back-and-forth = true;
    };

    layout = {
      gaps = 8;
      center-focused-column = "on-overflow";
      always-center-single-column = true;
      background-color = "#1e1e2e";

      preset-column-widths = [
        {proportion = 0.33333;}
        {proportion = 0.5;}
        {proportion = 0.66667;}
      ];

      default-column-width = {proportion = 0.5;};

      focus-ring = {
        width = 2;
        active = {
          color = "#89b4fa";
        };
        inactive = {
          color = "#45475a";
        };
        urgent = {
          color = "#f38ba8";
        };
      };

      border = {
        width = 0;
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        draw-behind-window = true;
        color = "#00000060";
      };

      struts = {
        left = 0;
        right = 0;
        top = 0;
        bottom = 0;
      };
    };

    binds = let
      sh = cmd: ["sh" "-c" cmd];
    in {
      "Mod+Return".action.spawn = ["kitty"];
      "Mod+Shift+Return".action.spawn = ["foot"];

      "Mod+Q".action.close-window = {};
      "Mod+Shift+Q".action.quit = {};
      "Mod+F".action.fullscreen-window = {};
      "Mod+Shift+Space".action.toggle-window-floating = {};
      "Mod+Shift+M".action.maximize-column = {};
      "Mod+T".action.toggle-column-tabbed-display = {};

      "Mod+Left".action.focus-column-left = {};
      "Mod+Right".action.focus-column-right = {};
      "Mod+Up".action.focus-window-up = {};
      "Mod+Down".action.focus-window-down = {};

      "Mod+H".action.focus-column-left = {};
      "Mod+L".action.focus-column-right = {};
      "Mod+K".action.focus-window-up = {};
      "Mod+J".action.focus-window-down = {};

      "Mod+Shift+Left".action.move-column-left = {};
      "Mod+Shift+Right".action.move-column-right = {};
      "Mod+Shift+Up".action.move-window-up = {};
      "Mod+Shift+Down".action.move-window-down = {};

      "Mod+Shift+H".action.move-column-left = {};
      "Mod+Shift+L".action.move-column-right = {};
      "Mod+Shift+K".action.move-window-up = {};
      "Mod+Shift+J".action.move-window-down = {};

      "Mod+BracketLeft".action.consume-window-into-column = {};
      "Mod+BracketRight".action.expel-window-from-column = {};
      "Mod+R".action.switch-preset-column-width = {};
      "Mod+Shift+R".action.reset-window-height = {};
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;

      "Mod+Page_Up".action.focus-workspace-up = {};
      "Mod+Page_Down".action.focus-workspace-down = {};
      "Mod+Shift+Page_Up".action.move-column-to-workspace-up = {};
      "Mod+Shift+Page_Down".action.move-column-to-workspace-down = {};

      "Mod+D".action.spawn = ["rofi" "-show" "drun"];
      "Mod+Shift+E".action.spawn = ["emacs"];
      "Mod+Shift+B".action.spawn = ["firefox"];

      "Mod+Shift+Escape".action.spawn = ["swaylock"];
      "Mod+Shift+P".action.power-off-monitors = {};
      "Mod+Shift+S".action.suspend = {};

      "Print".action.screenshot-screen = {};
      "Shift+Print".action.screenshot = {};

      "Ctrl+Print".action.screenshot-window = {};

      "XF86AudioRaiseVolume" = {
        action.spawn = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.5";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action.spawn = sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        allow-when-locked = true;
      };

      "XF86AudioPlay" = {
        action.spawn = sh "playerctl play-pause";
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        action.spawn = sh "playerctl next";
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        action.spawn = sh "playerctl previous";
        allow-when-locked = true;
      };

      "XF86MonBrightnessUp" = {
        action.spawn = sh "brightnessctl set +5%";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action.spawn = sh "brightnessctl set 5%-";
        allow-when-locked = true;
      };
    };

    window-rules = [
      {
        matches = [{is-floating = false;}];
        geometry-corner-radius = {
          top-left = 8.0;
          top-right = 8.0;
          bottom-left = 8.0;
          bottom-right = 8.0;
        };
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
      {
        matches = [{title = "^Picture-in-Picture$";}];
        open-floating = true;
      }
      {
        matches = [{app-id = "^pavucontrol$";}];
        open-floating = true;
      }
      {
        matches = [{app-id = "^xdg-desktop-portal-gtk$";}];
        open-floating = true;
      }
      {
        matches = [{app-id = "^org.keepassxc.KeePassXC$"; title = "Generate Password";}];
        open-floating = true;
      }
      {
        matches = [
          {app-id = "^firefox$";}
          {app-id = "^Firefox$";}
        ];
        default-column-width = {proportion = 0.75;};
      }
      {
        matches = [{app-id = "^emacs$";}];
        default-column-width = {proportion = 0.66667;};
      }
    ];

    environment = {
      NIXOS_OZONE_WL = "1";
      DISPLAY = ":0";
      WAYLAND_DISPLAY = "wayland-1";
    };
  };
}
