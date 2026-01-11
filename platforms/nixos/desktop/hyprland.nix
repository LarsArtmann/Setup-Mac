{
  pkgs,
  lib,
  ...
}: let
  # Import Hyprland type safety framework
  hyprlandTypes = import ../../../common/core/HyprlandTypes.nix {inherit lib;};

  # Validate Hyprland configuration at evaluation time
  hyprlandConfig = {
    variables = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun -show-icons";
    };
    monitor = "HDMI-A-1,preferred,auto,1.25";
    workspaces = [
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
  };

  validationResult = hyprlandTypes.validateHyprlandConfig hyprlandConfig;
in {
  imports = [
    ./waybar.nix
    ./polkit.nix
  ];

  # Type safety assertions - fail early if configuration is invalid
  assertions = [
    {
      assertion = validationResult.valid;
      message = lib.concatStringsSep "\n" (
        ["❌ Hyprland configuration validation failed:"] ++ validationResult.errorMessages
      );
    }
  ];

  # Enable Hyprland via Home Manager
  wayland.windowManager.hyprland = {
    enable = true;

    # Enable Hyprland plugins
    plugins = [
      pkgs.hyprlandPlugins.hyprwinwrap
    ];

    # Recommended settings for best experience
    systemd.enable = true; # Try enabling for better keybinding support
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun -show-icons";

      # For TV display - 200% scaling
      monitor = "HDMI-A-1,preferred,auto,1.25"; # 125% scaling for TV display (reduced from 200% for workspace stability)
      # Fallback if above doesn't work:
      # monitor = "preferred,auto,2,transform,1";  # 2x scale + normal orientation

      # Workspace naming for better organization
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

      exec-once = [
        ''waybar''
        ''dunst''
        ''systemctl --user start polkit-gnome-authentication-agent-1''
        ''wl-paste --watch cliphist store''
        # Desktop consoles setup
        ''${pkgs.kitty}/bin/kitty --class htop-bg --hold -e htop'' # Process monitor
        ''${pkgs.kitty}/bin/kitty --class logs-bg --hold -e journalctl -f'' # System logs
        ''${pkgs.kitty}/bin/kitty --class nvim-bg --hold -e nvim ~/.config/hypr/hyprland.conf'' # Config editor
      ];

      # Hyprwinwrap plugin configuration
      plugin = {
        hyprwinwrap = {
          class = "btop-bg";
        };
      };

      windowrulev2 = [
        # Terminal windows on workspace 1
        "workspace 1,class:^(kitty)$"
        "workspace 1,class:^(ghostty)$"
        "workspace 1,class:^(alacritty)$"

        # Browser windows on workspace 2
        "workspace 2,class:^(firefox)$"
        "workspace 2,class:^(chromium)$"
        "workspace 2,class:^(helium)$"

        # File manager on workspace 3
        "workspace 3,class:^(dolphin)$"
        "workspace 3,class:^(thunar)$"
        "workspace 3,class:^(nautilus)$"

        # Editor windows on workspace 4
        "workspace 4,class:^(nvim)$"
        "workspace 4,class:^(code)$"
        "workspace 4,class:^(codium)$"

        # Communication apps on workspace 5
        "workspace 5,class:^(signal)$"
        "workspace 5,class:^(discord)$"

        # Dialogs should float
        "float, title:^(Open File|Save As|Choose File)"

        # Picture-in-Picture
        "float, title:^(Picture-in-Picture)"
        "pin, title:^(Picture-in-Picture)"

        # System dialogs
        "float, class:^(nm-connection-editor|blueman-manager|pavucontrol)$"
        "center, class:^(nm-connection-editor|blueman-manager|pavucontrol)$"

        # No blur for terminals (performance)
        "noblur, class:^(kitty|ghostty|alacritty)$"

        # Background consoles (keep visible on all workspaces)
        "float,class:^(htop-bg)$"
        "nofocus,class:^(htop-bg)$"
        "noblur,class:^(htop-bg)$"
        "noshadow,class:^(htop-bg)$"
        "noborder,class:^(htop-bg)$"
        "size 800 600,class:^(htop-bg)$"
        "move 100 100,class:^(htop-bg)$"

        # System logs
        "float,class:^(logs-bg)$"
        "nofocus,class:^(logs-bg)$"
        "noblur,class:^(logs-bg)$"
        "noshadow,class:^(logs-bg)$"
        "noborder,class:^(logs-bg)$"
        "size 800 600,class:^(logs-bg)$"
        "move 920 100,class:^(logs-bg)$"

        # Config editor
        "float,class:^(nvim-bg)$"
        "nofocus,class:^(nvim-bg)$"
        "noblur,class:^(nvim-bg)$"
        "noshadow,class:^(nvim-bg)$"
        "noborder,class:^(nvim-bg)$"
        "size 800 600,class:^(nvim-bg)$"
        "move 100 720,class:^(nvim-bg)$"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # MEMORY & PERFORMANCE OPTIMIZED DECORATION
      decoration = {
        rounding = 8; # Reduced from 10 for performance
        blur = {
          enabled = true;
          size = 2; # Reduced from 3
          passes = 1;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          ignore_opacity = true;
          new_optimizations = true; # Enable new blur optimizations
          xray = true; # X-ray blur for better performance
        };
      };

      # OPTIMIZED ANIMATIONS - BALANCED PERFORMANCE & SMOOTHNESS
      animations = {
        enabled = true;
        # Optimized bezier for smooth but fast animations
        bezier = "myBezier, 0.25, 0.46, 0.45, 0.94";
        # Reduced animation count and speed for better performance
        animation = [
          "windows, 1, 3, myBezier, slide"
          "windowsOut, 1, 2, default, popin 90%"
          "border, 1, 5, default"
          "borderangle, 1, 6, default"
          "fade, 1, 3, default"
          "workspaces, 1, 0.5, default, slidefadevert" # Faster switching (0.5s instead of 4s)
          "specialWorkspace, 1, 0.5, default, slidefadevert" # Faster switching (0.5s instead of 4s)
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        # new_is_master = true; # Deprecated in newer Hyprland
      };

      # PERFORMANCE OPTIMIZATIONS
      render = {
        direct_scanout = 1; # Reduced latency
        explicit_sync = 1; # Better frame timing
        new_render_scheduling = true; # Smoother animations
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = false;
        key_press_enables_dpms = false;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        vrr = 1; # Variable refresh rate
        vfr = true; # Variable frame rate
        animate_manual_resizes = false; # Responsive resizing
        animate_mouse_windowdragging = false; # Responsive dragging
        render_ahead_of_time = true; # Pre-render frames
      };

      input = {
        follow_mouse = 1; # Better focus behavior
        repeat_delay = 250; # Keyboard repeat
        repeat_rate = 40; # Faster repeat rate
      };

      # DEBUG & PERFORMANCE MONITORING
      debug = {
        disable_logs = false;
        disable_time = false;
        overlay = false;
        damage_blink = false;
      };

      bind = [
        # APPLICATION LAUNCHING
        "$mod, Q, exec, $terminal"
        "$mod, Return, exec, $terminal"
        "$mod, Space, exec, $menu"
        "$mod, R, exec, $menu"
        "$mod, N, exec, dolphin"
        "$mod, E, exec, dolphin" # File manager (should probably ensure one is installed)
        "$mod, B, exec, firefox" # Browser
        "$mod, D, exec, $menu -show run" # Run command

        # WINDOW MANAGEMENT
        "$mod, C, killactive,"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen,"
        "$mod, M, fullscreen, 1" # Maximize
        "$mod, P, pseudo," # dwindle
        "$mod, J, togglesplit," # dwindle
        "$mod, T, togglefloating,"

        # FOCUS NAVIGATION
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # WINDOW MOVEMENT
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # WORKSPACES
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

        # MOVE TO WORKSPACE
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

        # MOVE WITH WINDOW TO WORKSPACE
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

        # SPECIAL WORKSPACE
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # SCROLL THROUGH WORKSPACES
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # SYSTEM CONTROLS
        "$mod, Escape, exec, hyprlock" # Lock screen
        "$mod, X, exec, wlogout" # Power menu
        "$mod SHIFT, R, exec, hyprctl reload" # Reload config
        "$mod SHIFT, E, exec, wlogout" # Power menu
        "$mod, Print, exec, grimblast copy area" # Screenshot area
        "$mod SHIFT, Print, exec, grimblast copy screen" # Screenshot screen
        "$mod CTRL, Print, exec, grimblast copy window" # Screenshot window

        # AUDIO CONTROLS
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"

        # SCREEN BRIGHTNESS
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        # DESKTOP TERMINALS TOGGLE
        "$mod, F1, exec, hyprctl dispatch focuswindow ^btop-bg$"
        "$mod, F2, exec, hyprctl dispatch focuswindow ^htop-bg$"
        "$mod, F3, exec, hyprctl dispatch focuswindow ^logs-bg$"
        "$mod, F4, exec, hyprctl dispatch focuswindow ^nvim-bg$"

        # Development tool shortcuts
        "$mod, G, exec, gitui"
        "$mod, H, exec, btop"
        "$mod, A, exec, nvim ~/todo.md"

        # Clipboard history
        "$mod, V, exec, cliphist list | rofi -dmenu -p 'Clipboard:' | cliphist decode | wl-copy"
      ];

      bindm = [
        # Move/resize windows with mod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  # Essential packages for this config
  home.packages = with pkgs; [
    # Terminal & Core Tools
    kitty # Terminal
    ghostty # Modern terminal emulator
    # kdePackages.dolphin moved to multi-wm.nix (available system-wide)
    # rofi moved to multi-wm.nix (available system-wide)

    # Hyprland Ecosystem - Essential tools
    hyprpaper # Wallpaper utility (official)
    hyprlock # GPU-accelerated screen lock
    hypridle # Idle daemon for automatic lock/suspend
    hyprpicker # Color picker
    hyprsunset # Blue light filter
    hyprpolkitagent # Modern polkit agent for Hyprland

    # Status Bar & Notifications
    # waybar moved to multi-wm.nix (available system-wide)
    dunst # Notifications
    libnotify # Notification library

    # Clipboard & Utilities
    # wl-clipboard moved to multi-wm.nix (available system-wide)
    # cliphist moved to base.nix (available system-wide)

    # Animated wallpapers (optional but cool)
    # swww moved to base.nix (available system-wide)
    # imagemagick moved to base.nix (available system-wide)

    # System Monitoring (GPU tools for Hyprland background terminals)
    # radeontop moved to monitoring.nix (available system-wide)
    # amdgpu_top moved to hardware/amd-gpu.nix (available system-wide)
    # btop, nvtopPackages.amd moved to monitoring.nix

    # Additional useful tools
    # pavucontrol, grim, slurp moved to multi-wm.nix (available system-wide)

    # Enhanced tools for superb setup
    wlogout # Modern logout menu
    grimblast # Enhanced screenshot utility (requires grim and slurp from multi-wm.nix)
    playerctl # Media player control
    brightnessctl # Brightness control

    # AI/ML tools moved to ai-stack.nix to avoid duplication
    # - ROCm packages, python311, ollama, vllm, llama-cpp, tesseract4, poppler-utils, nvtop
    # Security & monitoring tools moved to dedicated modules:
    # - security-hardening.nix (security tools)
    # - monitoring.nix (performance monitoring tools)
    # Common desktop utilities moved to multi-wm.nix:
    # - kdePackages.dolphin, pavucontrol, grim, slurp, wl-clipboard
  ];
}
