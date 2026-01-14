{
  pkgs,
  lib,
  config,
  ...
}: let
  # Import Hyprland type safety module
  hyprlandTypes = import ../core/HyprlandTypes.nix {inherit lib;};
in {
  imports = [
    ./waybar.nix
  ];

  config = {
    # Type-safe Hyprland configuration with custom validation
    wayland.windowManager.hyprland = {
      enable = true;

      # Plugins
      plugins = with pkgs.hyprlandPlugins; [
        hyprwinwrap # Background windows
        hy3 # i3-style tiling (tabbed/stacked layouts)
        hyprsplit # Dynamic window splitting
      ];

      # System integration
      systemd.enable = true;
      xwayland.enable = true;

      # All settings (type-safe via Nix types - auto-validated)
      settings = {
        # Variables
        "$mod" = "SUPER";
        "$terminal" = "kitty";
        "$menu" = "rofi -show drun -show-icons";

        # Plugin
        plugin = {
          hyprwinwrap = {
            class = "btop-bg";
          };
        };

        # Input (typed: int, str, bool validated by Nix)
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          repeat_delay = 250;
          repeat_rate = 40;
        };

        # General (types validated automatically)
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
        };

        # hy3 plugin settings (i3-style tiling)
        hy3 = {
          gaps_between = 10;
          tab_split_threshold = 0;
        };

        # Decoration (nested types validated)
        decoration = {
          rounding = 8;
          blur = {
            enabled = true;
            size = 2;
            passes = 1;
            noise = 0.0117;
            contrast = 0.8916;
            brightness = 0.8172;
            ignore_opacity = true;
            new_optimizations = true;
            xray = true;
          };
        };

        # Animations
        animations = {
          enabled = true;
          bezier = "myBezier, 0.25, 0.46, 0.45, 0.94";
          animation = [
            "windows, 1, 3, myBezier, slide"
            "windowsOut, 1, 2, default, popin 90%"
            "border, 1, 5, default"
            "borderangle, 1, 6, default"
            "fade, 1, 3, default"
            "workspaces, 1, 0.5, default, slidefadevert"
            "specialWorkspace, 1, 0.5, default, slidefadevert"
          ];
        };

        # Monitor
        monitor = "HDMI-A-1,preferred,auto,1.25";

        # Workspaces
        workspace = [
          "1, name:💻 Dev"
          "2, name:🌐 Web"
          "3, name:📁 Files"
          "4, name:📝 Edit"
          "5, name:💬 Chat"
          "6, name:🔧 Tools"
          "7, name:🎮 Games"
          "8, name:🎵 Media"
          "9, name:📊 Mon"
          "10, name:🌟 Misc"
        ];

        # Window rules
        windowrulev2 = [
          "workspace 1,class:^(kitty)$"
          "workspace 1,class:^(ghostty)$"
          "workspace 1,class:^(alacritty)$"
          "workspace 2,class:^(firefox)$"
          "workspace 2,class:^(chromium)$"
          "workspace 2,class:^(helium)$"
          "workspace 3,class:^(dolphin)$"
          "workspace 3,class:^(thunar)$"
          "workspace 3,class:^(nautilus)$"
          "workspace 4,class:^(nvim)$"
          "workspace 4,class:^(code)$"
          "workspace 4,class:^(codium)$"
          "workspace 5,class:^(signal)$"
          "workspace 5,class:^(discord)$"
          "float, title:^(Open File|Save As|Choose File)"
          "float, title:^(Picture-in-Picture)"
          "pin, title:^(Picture-in-Picture)"
          "float, class:^(nm-connection-editor|blueman-manager|pavucontrol)$"
          "center, class:^(nm-connection-editor|blueman-manager|pavucontrol)$"
          "noblur, class:^(kitty|ghostty|alacritty)$"
          "float,class:^(htop-bg)$"
          "nofocus,class:^(htop-bg)$"
          "noblur,class:^(htop-bg)$"
          "noshadow,class:^(htop-bg)$"
          "noborder,class:^(htop-bg)$"
          "size 800 600,class:^(htop-bg)$"
          "move 100 100,class:^(htop-bg)$"
          "float,class:^(logs-bg)$"
          "nofocus,class:^(logs-bg)$"
          "noblur,class:^(logs-bg)$"
          "noshadow,class:^(logs-bg)$"
          "noborder,class:^(logs-bg)$"
          "size 800 600,class:^(logs-bg)$"
          "move 920 100,class:^(logs-bg)$"
          "float,class:^(nvim-bg)$"
          "nofocus,class:^(nvim-bg)$"
          "noblur,class:^(nvim-bg)$"
          "noshadow,class:^(nvim-bg)$"
          "noborder,class:^(nvim-bg)$"
          "size 800 600,class:^(nvim-bg)$"
          "move 100 720,class:^(nvim-bg)$"

          # Quake terminal rules (dropdown terminal)
          "float,class:^(kitty-quake)$"
          "size 80% 40%,class:^(kitty-quake)$"
          "move 10% 5%,class:^(kitty-quake)$"
          "noborder,class:^(kitty-quake)$"
          "noshadow,class:^(kitty-quake)$"
        ];

        # Startup
        exec-once = [
          "waybar"
          "dunst"
          "wl-paste --watch cliphist store"
          "${pkgs.kitty}/bin/kitty --class htop-bg --hold -e ${pkgs.htop}/bin/htop"
          "${pkgs.kitty}/bin/kitty --class logs-bg --hold -e journalctl -f"
          "${pkgs.kitty}/bin/kitty --class kitty-quake --name Quake -e zsh"
        ];

        # Keybindings
        bind = [
          "$mod, Q, exec, $terminal"
          "$mod, Return, exec, $terminal"
          "$mod, Space, exec, $menu"
          "$mod, R, exec, $menu"
          "$mod, N, exec, ${pkgs.kdePackages.dolphin}/bin/dolphin"
          "$mod, E, exec, ${pkgs.kdePackages.dolphin}/bin/dolphin"
          "$mod, B, exec, ${pkgs.firefox}/bin/firefox"
          "$mod, D, exec, $menu -show run"
          "$mod, C, killactive,"
          "$mod, V, togglefloating,"
          "$mod, F, fullscreen,"
          "$mod, M, fullscreen, 1"
          "$mod, P, pseudo,"
          "$mod, J, togglesplit,"
          "$mod, T, togglefloating,"
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"
          "$mod SHIFT, left, movewindow, l"
          "$mod SHIFT, right, movewindow, r"
          "$mod SHIFT, up, movewindow, u"
          "$mod SHIFT, down, movewindow, d"
          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"
          "ALT SHIFT, 1, movetoworkspacesilent, 1"
          "ALT SHIFT, 2, movetoworkspacesilent, 2"
          "ALT SHIFT, 3, movetoworkspacesilent, 3"
          "ALT SHIFT, 4, movetoworkspacesilent, 4"
          "ALT SHIFT, 5, movetoworkspacesilent, 5"
          "ALT SHIFT, 6, movetoworkspacesilent, 6"
          "ALT SHIFT, 7, movetoworkspacesilent, 7"
          "ALT SHIFT, 8, movetoworkspacesilent, 8"
          "ALT SHIFT, 9, movetoworkspacesilent, 9"
          "ALT SHIFT, 0, movetoworkspacesilent, 10"
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"
          "$mod, grave, togglespecialworkspace, quake" # Quake terminal (Super+~)
          "$mod SHIFT, grave, movetoworkspace, special:quake"
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"
          "$mod, Escape, exec, ${pkgs.hyprlock}/bin/hyprlock"
          "$mod, X, exec, ${pkgs.wlogout}/bin/wlogout"
          "$mod SHIFT, R, exec, hyprctl reload"
          "$mod SHIFT, E, exec, ${pkgs.wlogout}/bin/wlogout"
          "$mod, Print, exec, ${pkgs.grimblast}/bin/grimblast copy area"
          "$mod SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast copy screen"
          "$mod CTRL, Print, exec, ${pkgs.grimblast}/bin/grimblast copy window"
          ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
          ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
          ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
          ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
          ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
          ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
          ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set +5%"
          ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
          "$mod, F1, exec, hyprctl dispatch focuswindow ^btop-bg$"
          "$mod, F2, exec, hyprctl dispatch focuswindow ^htop-bg$"
          "$mod, F3, exec, hyprctl dispatch focuswindow ^logs-bg$"
          "$mod, F4, exec, hyprctl dispatch focuswindow ^nvim-bg$"
          "$mod, G, exec, ${pkgs.gitui}/bin/gitui"
          "$mod, H, exec, ${pkgs.btop}/bin/btop"
          "$mod, A, exec, ${pkgs.neovim}/bin/nvim ~/todo.md"

          # hy3 layout switching (i3-style tiling)
          "$mod, T, hy3:changegroup, tab" # Tabbed layout
          "$mod, Y, hy3:changegroup, stack" # Stacked layout
          "$mod, W, hy3:changegroup, hsplit" # Horizontal split
          "$mod, V, hy3:changegroup, vsplit" # Vertical split
          "$mod, E, hy3:makegroup, hsplit" # New horizontal group
          "$mod SHIFT, E, hy3:makegroup, vsplit" # New vertical group
          "$mod, O, exec, ${pkgs.writeShellScriptBin "clipboard-menu" ''
            ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu -p 'Clipboard:' | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
          ''}/bin/clipboard-menu"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        # Performance (all types validated)
        render = {
          direct_scanout = 1;
          explicit_sync = 1;
          new_render_scheduling = true;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          mouse_move_enables_dpms = false;
          key_press_enables_dpms = false;
          always_follow_on_dnd = true;
          layers_hog_keyboard_focus = true;
          vrr = 1;
          vfr = true;
          animate_manual_resizes = false;
          animate_mouse_windowdragging = false;
          render_ahead_of_time = true;
        };

        debug = {
          disable_logs = false;
          disable_time = false;
          overlay = false;
          damage_blink = false;
        };
      };
    };

    # Type safety assertions - catch config errors at build time using HyprlandTypes validation
    assertions = let
      inherit (config.wayland.windowManager.hyprland) settings;

      # Build config object for validation
      hyprlandConfig = {
        variables = {
          "$mod" = settings."$mod";
          "$terminal" = settings."$terminal";
          "$menu" = settings."$menu";
        };
        inherit (settings) monitor;
        workspaces = settings.workspace;
        windowRules = settings.windowrulev2;
        keybindings = settings.bind;
        mouseBindings = settings.bindm;
      };

      # Validate using HyprlandTypes
      validation = hyprlandTypes.validateHyprlandConfig hyprlandConfig;
    in
      [
        {
          assertion = validation.valid;
          message = lib.concatStringsSep "\n" validation.errorMessages;
        }
      ]
      ++ lib.mapAttrsToList (name: package: {
        assertion = builtins.hasAttr name pkgs || (name == "dolphin" && pkgs.kdePackages ? dolphin);
        message =
          if name == "dolphin"
          then "Package '${name}' not found in pkgs.kdePackages - add to platforms/nixos/desktop/multi-wm.nix"
          else "Package '${name}' not found in nixpkgs - add to appropriate package list";
      }) {
        htop = null;
        btop = null;
        firefox = null;
        gitui = null;
        neovim = null;
        grimblast = null;
        playerctl = null;
        brightnessctl = null;
        dolphin = null;
      };
  };
}
