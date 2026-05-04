{
  pkgs,
  config,
  lib,
  wallpapers,
  colorScheme,
  ...
}: let
  colors = colorScheme.palette;
  wallpaperDir = "$HOME/.local/share/wallpapers";
  cfg = config.services.niri-session;

  fallbackCommands = lib.concatStringsSep "\n      " (lib.forEach (lib.range 0 ((lib.length cfg.fallbackApps) - 1)) (i: let
    app = lib.elemAt cfg.fallbackApps i;
    cmd =
      if app.args == []
      then app.app_id
      else "${app.app_id} ${lib.concatStringsSep " " app.args}";
  in
    if i == 0
    then "${cmd} &"
    else "sleep 0.3\n      ${cmd} &"));

  niri-session-save = pkgs.writeShellApplication {
    name = "niri-session-save";
    runtimeInputs = with pkgs; [niri-unstable jq procps coreutils];
    text = builtins.readFile ../../../scripts/niri-session-save.sh;
  };

  niri-session-restore = pkgs.writeShellApplication {
    name = "niri-session-restore";
    runtimeInputs = with pkgs; [niri-unstable jq coreutils procps libnotify];
    text = builtins.replaceStrings ["@maxSessionAgeDays@" "@fallbackCommands@"] [
      (toString cfg.maxSessionAgeDays)
      fallbackCommands
    ] (builtins.readFile ../../../scripts/niri-session-restore.sh);
  };
in {
  options.services.niri-session = {
    sessionSaveInterval = lib.mkOption {
      type = lib.types.str;
      default = "60s";
      description = "Systemd timer interval for saving niri session state";
    };

    maxSessionAgeDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = "Maximum age in days before session snapshot is discarded";
    };

    fallbackApps = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          app_id = lib.mkOption {
            type = lib.types.str;
            description = "Application ID to spawn";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments to pass to the application";
          };
        };
      });
      default = [
        {
          app_id = "kitty";
          args = [];
        }
        {
          app_id = "kitty";
          args = ["-e" "btop"];
        }
        {
          app_id = "kitty";
          args = ["-e" "nvtop"];
        }
        {
          app_id = "amdgpu_top";
          args = [];
        }
        {
          app_id = "helium";
          args = [];
        }
        {
          app_id = "signal-desktop";
          args = [];
        }
      ];
      description = "Fallback applications to spawn when no valid session exists";
    };
  };

  config = {
    home.file.".local/share/wallpapers".source = wallpapers;

    programs.niri.settings = {
      prefer-no-csd = true;

      screenshot-path = "~/Pictures/screenshots/%Y-%m-%d %H-%M-%S.png";

      spawn-at-startup = [
        {argv = ["${niri-session-restore}/bin/niri-session-restore"];}
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
          drag = true;
          disabled-on-external-mouse = true;
        };

        mouse = {
          natural-scroll = false;
          accel-profile = "flat";
        };

        trackball = {
          accel-profile = "flat";
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

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 96;
      };

      layout = {
        gaps = 8;
        center-focused-column = "on-overflow";
        always-center-single-column = true;
        background-color = "#${colors.base00}";

        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];

        default-column-width = {proportion = 0.5;};

        focus-ring = {
          width = 2;
          active = {
            color = "#${colors.base0D}";
          };
          inactive = {
            color = "#${colors.base03}";
          };
          urgent = {
            color = "#${colors.base08}";
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
        "F11".action.fullscreen-window = {};
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
        "Mod+Space".action.spawn = ["rofi" "-show" "drun"];
        "Mod+Shift+Slash".action.spawn = sh "niri msg binds | rofi -dmenu -p 'Keybindings:' -theme-str 'window {width: 80%; height: 80%;}'";
        "Alt+C".action.spawn = sh "cliphist list | rofi -dmenu -p 'Clipboard:' -kb-delete-entry 'Ctrl+Delete' -theme-str 'window {width: 50%;} listview {columns: 1; lines: 12; scrollbar: true; } element {orientation: horizontal; padding: 8px; spacing: 8px; } element-text {horizontal-align: 0.0; vertical-align: 0.5; } scrollbar {enabled: true; width: 4px; padding: 0; } scrollbar-handle {background-color: @selected; border-radius: 2px; }' | cliphist decode | wl-copy";
        "Mod+period".action.spawn = sh "rofi -modi emoji -show emoji -theme-str 'window {width: 40%;}'";
        "Mod+Shift+C".action.spawn = sh "rofi -show calc -modi calc -no-show-match -no-sort -theme-str 'window {width: 30%;}'";
        "Mod+Shift+N".action.spawn = sh "dunstctl history | jq -r '.data[0][] | \"\\(.summary.data[0] // \\\"\\\") — \\(.body.data[0] // \\\"\\\") [\\(.timestamp.data[0] / 1000000 | strftime(\\\"%H:%M\\\"))]\"' 2>/dev/null | rofi -dmenu -p 'Notifications:' -theme-str 'window {width: 60%; height: 60%;} listview {columns: 1; lines: 15;} element {padding: 10px;}' || true";
        "Mod+Shift+E".action.spawn = ["emacs"];
        "Mod+Shift+B".action.spawn = ["firefox"];
        "Mod+Z".action.spawn = ["zed"];
        "Mod+Shift+F".action.spawn = sh "kitty --class floating -e yazi";
        "Mod+Shift+D".action.spawn = sh "zellij --layout dev";

        "Mod+Shift+Escape".action.spawn = ["swaylock"];
        "Mod+Shift+P".action.power-off-monitors = {};
        "Mod+Shift+S".action.suspend = {};

        "Mod+W".action.spawn = sh "img=$(${pkgs.coreutils}/bin/ls ${wallpaperDir}/*.{jpg,jpeg,png,webp} 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n1) && [ -n \"$img\" ] && ${pkgs.awww}/bin/awww img \"$img\" --transition-type random --transition-duration 3";

        "Mod+Shift+F11".action.spawn = sh "mkdir -p ~/Pictures/screenshots && grim -g \"$(slurp)\" /tmp/screenshot.png && wl-copy < /tmp/screenshot.png && swappy -f /tmp/screenshot.png";
        "Mod+F11".action.spawn = sh "mkdir -p ~/Pictures/screenshots && grim /tmp/screenshot.png && wl-copy < /tmp/screenshot.png && swappy -f /tmp/screenshot.png";
        "Mod+Ctrl+F11".action.spawn = sh "mkdir -p ~/Pictures/screenshots && grim -o $(niri msg focused-output | head -1) /tmp/screenshot.png && wl-copy < /tmp/screenshot.png && swappy -f /tmp/screenshot.png";

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
          action.spawn = sh "ddcutil setvcp 10 + 10 2>/dev/null || brightnessctl set +5%";
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action.spawn = sh "ddcutil setvcp 10 - 10 2>/dev/null || brightnessctl set 5%-";
          allow-when-locked = true;
        };
      };

      window-rules = [
        {
          matches = [{app-id = "^org.prismlauncher.PrismLauncher$";}];
          opacity = 1.0;
        }
        {
          matches = [{is-floating = false;}];
          opacity = 0.95;
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
          matches = [
            {app-id = "^pavucontrol$";}
            {app-id = "^com.saivert.pwvucontrol$";}
          ];
          open-floating = true;
        }
        {
          matches = [{app-id = "^floating$";}];
          open-floating = true;
          default-floating-position = {
            x = 0.25;
            y = 0.15;
            relative-to = "top-left";
          };
          default-column-width = {proportion = 0.5;};
          default-window-height = {proportion = 0.7;};
        }
        {
          matches = [
            {app-id = "^steam_app_.*";}
          ];
          open-fullscreen = true;
          opacity = 1.0;
        }
        {
          matches = [
            {app-id = "^steam_app_.*";}
            {app-id = "^steam$";}
            {title = "^Counter-Strike";}
          ];
          open-fullscreen = true;
          opacity = 1.0;
        }
        {
          matches = [{app-id = "^xdg-desktop-portal-gtk$";}];
          open-floating = true;
        }
        {
          matches = [
            {
              app-id = "^org.keepassxc.KeePassXC$";
              title = "Generate Password";
            }
          ];
          open-floating = true;
        }
        {
          matches = [
            {app-id = "^firefox$";}
            {app-id = "^Firefox$";}
          ];
          open-on-workspace = "browser";
          default-column-width = {proportion = 0.75;};
        }
        {
          matches = [
            {app-id = "^kitty$";}
            {app-id = "^foot$";}
            {app-id = "^helium$";}
          ];
          open-on-workspace = "main";
          default-column-width = {proportion = 0.75;};
        }
        {
          matches = [{app-id = "^emacs$";}];
          open-on-workspace = "dev";
          default-column-width = {proportion = 0.66667;};
        }
        {
          matches = [
            {app-id = "^Slack$";}
            {app-id = "^discord$";}
            {app-id = "^vesktop$";}
            {app-id = "^telegramdesktop$";}
            {app-id = "^signal$";}
          ];
          open-on-workspace = "chat";
        }
        {
          matches = [
            {app-id = "^Spotify$";}
            {app-id = "^spotify$";}
          ];
          open-on-workspace = "media";
        }
      ];

      workspaces = {
        main = {};
        browser = {};
        dev = {};
        chat = {};
        media = {};
      };

      animations = {
        horizontal-view-movement = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 1000;
            epsilon = 0.0001;
          };
        };
        window-open = {
          kind.spring = {
            damping-ratio = 0.7;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
        window-close = {
          kind.spring = {
            damping-ratio = 0.7;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
        window-movement = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 1000;
            epsilon = 0.0001;
          };
        };
        window-resize = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
        workspace-switch = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 1000;
            epsilon = 0.0001;
          };
        };
      };
    };

    systemd.user.services = {
      awww-daemon = {
        Unit = {
          Description = "awww wallpaper daemon";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          StartLimitBurst = 5;
          StartLimitIntervalSec = 120;
        };
        Service = {
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          Restart = "always";
          RestartSec = "3s";
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      awww-wallpaper = {
        Unit = {
          Description = "Set random wallpaper";
          After = ["awww-daemon.service"];
          Wants = ["awww-daemon.service"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'img=$(${pkgs.coreutils}/bin/ls ${wallpaperDir}/*.{jpg,jpeg,png,webp} 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n1) && [ -n \"$img\" ] && for i in $(${pkgs.coreutils}/bin/seq 1 60); do ${pkgs.awww}/bin/awww img \"$img\" --transition-type random --transition-duration 3 && break; ${pkgs.coreutils}/bin/sleep 1; done'";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      swayidle = {
        Unit = {
          Description = "Idle management daemon";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          StartLimitBurst = 3;
          StartLimitIntervalSec = 120;
        };
        Service = {
          ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 43200 ${
            pkgs.writeShellScript "swayidle-suspend" ''
              ${pkgs.systemd}/bin/systemctl suspend
            ''
          } before-sleep ${pkgs.swaylock}/bin/swaylock";
          Restart = "always";
          RestartSec = "5s";
          TimeoutStartSec = "10s";
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      cliphist = {
        Unit = {
          Description = "Clipboard history watcher";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          StartLimitBurst = 3;
          StartLimitIntervalSec = 120;
        };
        Service = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "always";
          RestartSec = "5s";
          TimeoutStartSec = "10s";
        };
        Install.WantedBy = ["graphical-session.target"];
      };
      niri-session-save = {
        Unit = {
          Description = "Save niri session state for crash recovery";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          OnFailure = ["niri-session-save-failure.service"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${niri-session-save}/bin/niri-session-save";
        };
      };
      niri-session-save-failure = {
        Unit.Description = "Notify on niri session save failure";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.libnotify}/bin/notify-send -u critical 'Session Save Failed' 'The niri session save timer failed. Check systemctl --user status niri-session-save'";
        };
      };
    };

    systemd.user.timers.niri-session-save = {
      Unit.Description = "Periodically save niri session state";
      Timer = {
        OnBootSec = cfg.sessionSaveInterval;
        OnUnitActiveSec = cfg.sessionSaveInterval;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
