{ pkgs, ... }:

{
  imports = [
    ./waybar.nix
  ];

  # Enable Hyprland via Home Manager
  wayland.windowManager.hyprland = {
    enable = true;

    # Enable Hyprland plugins
    plugins = [
      pkgs.hyprlandPlugins.hyprwinwrap
    ];

    # Recommended settings for best experience
    systemd.enable = true;
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun -show-icons";

      monitor = "preferred,auto,2";

      exec-once = [
        "waybar"
        "dunst"
        "wl-paste --watch cliphist store"
        # Btop as desktop background
        "kitty --class btop-bg --hold -e btop"
      ];

      # Hyprwinwrap plugin configuration
      plugin = {
        hyprwinwrap = {
          class = "btop-bg";
        };
      };

      windowrulev2 = [
        # Configure btop as a pseudo-wallpaper
        "float,class:^(btop-bg)$"
        "fullscreen,class:^(btop-bg)$"
        "noanim,class:^(btop-bg)$"
        "nofocus,class:^(btop-bg)$"
        "noblur,class:^(btop-bg)$"
        "noshadow,class:^(btop-bg)$"
        "noborder,class:^(btop-bg)$"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        # drop_shadow = true; # Deprecated in newer Hyprland
        # shadow_range = 4;
        # shadow_render_power = 3;
        # "col.shadow" = "rgba(1a1a1aee)";
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        # new_is_master = true; # Deprecated in newer Hyprland
      };

      gestures = {
        workspace_swipe = true;
      };

      misc = {
        force_default_wallpaper = 0;
        # Performance optimizations
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_refocus = false;
        new_window_takes_over_fullscreen = true;
      };

      # Rendering optimizations for AMD GPUs
      render = {
        explicit_sync = true;
        direct_scanout = true;
      };

      bind = [
        "$mod, Q, exec, $terminal"
        "$mod, C, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, dolphin" # File manager (should probably ensure one is installed)
        "$mod, V, togglefloating,"
        "$mod, R, exec, $menu"
        "$mod, P, pseudo," # dwindle
        "$mod, J, togglesplit," # dwindle
        "$mod, F, fullscreen,"

        # Move focus with mod + arrow keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Switch workspaces with mod + [0-9]
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

        # Move active window to a workspace with mod + SHIFT + [0-9]
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

        # Scroll through existing workspaces with mod + scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
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
    kitty # Terminal
    kdePackages.dolphin # File manager
    rofi # App launcher (wayland support included)
    waybar # Status bar
    dunst # Notifications
    libnotify # Notification library
    wl-clipboard # Clipboard support
    hyprpaper # Wallpaper (official tool, lower overhead)
    swww # Animated wallpapers (for cool transitions)
    imagemagick # Image manipulation for wallpaper management
    btop # System monitor (used for background)
    # Additional monitoring tools
    nvtopPackages.amd # AMD GPU/process monitor
    radeontop # AMD GPU specific monitor
  ];
}
