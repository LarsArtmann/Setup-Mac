{pkgs, ...}: {
  imports = [
    ../../common/home-base.nix
    ../programs/shells.nix # NixOS shell configuration
    ../desktop/hyprland.nix # RE-ENABLED for desktop functionality
    ../modules/hyprland-animated-wallpaper.nix
  ];

  # Enable animated wallpaper with swww
  programs.hyprland-animated-wallpaper = {
    enable = true;
    updateInterval = 30; # Change wallpaper every 30 seconds
    transitionType = "random"; # Random transition direction
    transitionStep = 90; # Faster transition
    transitionDuration = 3; # 3 second transition
  };

  # NixOS-specific session variables
  home.sessionVariables = {
    # Wayland/Hyprland specific
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = "1";

    # Cursor theme for Hyprland (Wayland)
    # Note: XCURSOR_SIZE does NOT work in Wayland/Hyprland
    # Cursor size is determined by the cursor theme's built-in sizes
    # Bibata has XL size (96px) built-in
    XCURSOR_THEME = "Bibata-Modern-Classic";

    # Fallback for X11 applications (rarely used)
    XCURSOR_SIZE = "96";
  };

  # NixOS-specific packages
  home.packages = with pkgs; [
    # GUI Tools
    pavucontrol # Audio control (user-level access for audio settings)
    signal-desktop # Secure messaging application

    # XL Cursor theme for TV viewing (2 meters away)
    bibata-cursors

    # Development tools
    gitui # Terminal UI for git

    # Cursor themes
    adwaita-icon-theme
    hicolor-icon-theme

    # System Tools
    # Note: rofi moved to multi-wm.nix for system-wide availability
    # Note: xdg-utils moved to base.nix for cross-platform consistency

    # Hyprland-specific packages (moved from desktop/hyprland.nix to avoid NixOS module conflict)
    kitty
    ghostty
    hyprpaper
    hyprlock
    hypridle
    hyprpicker
    hyprsunset
    dunst
    libnotify
    wlogout
    grimblast
    playerctl
    brightnessctl
  ];

  # XDG configuration (Linux specific)
  xdg = {
    enable = true;

    # User directories
    userDirs = {
      enable = true;
      createDirectories = true;
    };

    # Default applications for MIME types
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Web browsing
        "text/html" = ["helium.desktop"];
        "application/xhtml+xml" = ["helium.desktop"];
        "x-scheme-handler/http" = ["helium.desktop"];
        "x-scheme-handler/https" = ["helium.desktop"];

        # Terminal
        "x-scheme-handler/terminal" = ["kitty.desktop"];
        "application/x-terminal-emulator" = ["kitty.desktop"];

        # Text files (use terminal editors for now)
        "text/plain" = ["kitty.desktop"];
        "text/markdown" = ["kitty.desktop"];
        "application/json" = ["kitty.desktop"];
        "application/x-yaml" = ["kitty.desktop"];
      };
    };
  };

  # GTK settings for theme (NOTE: cursor settings don't affect Hyprland compositor)
  gtk = {
    enable = true;
    font = {
      name = "Sans";
      size = 16; # Increased for TV viewing (2m distance)
    };
  };

  # Qt cursor settings for consistency
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
  };

  # Kitty terminal configuration (TV-friendly font size)
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 16; # TV viewing size (2m distance)
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      background_opacity = "0.85";
      confirm_os_window_close = 0;
      update_check_interval = 0;
      enable_audio_bell = false;
    };
  };

  # Dunst notification configuration (TV-friendly)
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrainsMono Nerd Font 16";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        sort = "yes";
        indicate_hidden = "yes";
        alignment = "center";
        show_age_threshold = 60;
        word_wrap = "yes";
        ignore_newline = "no";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";
        icon_position = "left";
        max_icon_size = 64;
        sticky_history = "yes";
        history_length = 20;
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst:";
        browser = "${pkgs.firefox}/bin/firefox --new-tab";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 12;
        ignore_dbusclose = false;
        layer = "overlay";
        force_xinerama = false;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };
      experimental = {
        per_monitor_dpi = false;
      };
      urgency_low = {
        background = "rgba(30,30,46,0.9)";
        foreground = "#cdd6f4";
        frame_color = "#89b4fa";
        timeout = 5;
      };
      urgency_normal = {
        background = "rgba(30,30,46,0.9)";
        foreground = "#cdd6f4";
        frame_color = "#89b4fa";
        timeout = 5;
      };
      urgency_critical = {
        background = "rgba(243,139,168,0.9)";
        foreground = "#1e1e2e";
        frame_color = "#f38ba8";
        timeout = 0;
      };
    };
  };
}
