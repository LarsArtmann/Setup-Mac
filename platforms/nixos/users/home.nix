{pkgs, ...}: {
  imports = [
    ../../common/home-base.nix
    ../programs/shells.nix # NixOS shell configuration
    ../programs/rofi.nix # Rofi launcher with Catppuccin theme
    ../programs/wlogout.nix # Power menu with Catppuccin theme
    ../programs/hyprlock.nix # Lock screen with Catppuccin theme
    ../programs/hypridle.nix # Idle management daemon
    ../programs/zellij.nix # Zellij terminal multiplexer
    ../desktop/hyprland.nix # RE-ENABLED for desktop functionality
    ../modules/hyprland-animated-wallpaper.nix
  ];

  # Programs configuration
  programs = {
    # Enable animated wallpaper with swww
    hyprland-animated-wallpaper = {
      enable = true;
      updateInterval = 30; # Change wallpaper every 30 seconds
      transitionType = "random"; # Random transition direction
      transitionStep = 90; # Faster transition
      transitionDuration = 3; # 3 second transition
    };

    # Kitty terminal configuration (TV-friendly font size)
    kitty = {
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

    # Foot terminal configuration (lightweight Wayland alternative)
    foot = {
      enable = true;
      settings = {
        main = {
          font = "JetBrainsMono Nerd Font:size=12";
          dpi-aware = "yes";
          pad = "12x12";
          shell = "fish";
        };
        cursor = {
          style = "block";
          blink = "yes";
        };
        mouse = {
          hide-when-typing = "yes";
        };
        colors = {
          alpha = "0.95";
          background = "1e1e2e";
          foreground = "cdd6f4";
          # Catppuccin Mocha colors
          regular0 = "45475a";  # black
          regular1 = "f38ba8";  # red
          regular2 = "a6e3a1";  # green
          regular3 = "f9e2af";  # yellow
          regular4 = "89b4fa";  # blue
          regular5 = "f5c2e7";  # magenta
          regular6 = "94e2d5";  # cyan
          regular7 = "bac2de";  # white
          bright0 = "585b70";   # bright black
          bright1 = "f38ba8";   # bright red
          bright2 = "a6e3a1";   # bright green
          bright3 = "f9e2af";   # bright yellow
          bright4 = "89b4fa";   # bright blue
          bright5 = "f5c2e7";   # bright magenta
          bright6 = "94e2d5";   # bright cyan
          bright7 = "a6adc8";   # bright white
        };
      };
    };
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

    # GTK Theming
    catppuccin-gtk
    papirus-icon-theme
    libsForQt5.qt5ct
    qt6.qtbase

    # System Tools
    # Note: rofi moved to multi-wm.nix for system-wide availability
    # Note: xdg-utils moved to base.nix for cross-platform consistency

    # Hyprland-specific packages (moved from desktop/hyprland.nix to avoid NixOS module conflict)
    kitty
    ghostty
    foot
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
    cliphist
    wl-clipboard
    zellij # Terminal multiplexer (modern tmux alternative)
    # Scripts dependencies
    jq # JSON processing for hyprctl scripts
    gawk # Text processing for zellij session menu
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

  # GTK settings for Catppuccin Mocha theme
  gtk = {
    enable = true;
    font = {
      name = "Sans";
      size = 16; # Increased for TV viewing (2m distance)
    };
    theme = {
      name = "Catppuccin-Mocha-Compact-Lavender-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["lavender"];
        size = "compact";
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # Qt settings for consistency with GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk2";
    style = {
      name = "gtk2";
      package = pkgs.qt6.qtbase;
    };
  };

  # Dunst notification configuration (TV-friendly)
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrainsMono Nerd Font Bold 16";
        markup = "full";
        format = "<b><span foreground='#89b4fa'>%s</span></b>\\n%b";
        sort = "yes";
        indicate_hidden = "yes";
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = "yes";
        ignore_newline = "no";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";
        icon_position = "left";
        max_icon_size = 128;
        sticky_history = "yes";
        history_length = 20;
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst:";
        browser = "${pkgs.firefox}/bin/firefox --new-tab";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 16;
        ignore_dbusclose = false;
        layer = "overlay";
        force_xinerama = false;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
        padding = 24;
        horizontal_padding = 24;
        text_icon_padding = 24;
        frame_width = 4;
        frame_color = "#89b4fa";
        separator_height = 2;
        separator_color = "frame";
        progress_bar = true;
        progress_bar_height = 12;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 400;
        progress_bar_corner_radius = 6;
        transparency = 10;
        idle_threshold = 120;
      };
      experimental = {
        per_monitor_dpi = false;
      };
      urgency_low = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        frame_color = "#89b4fa";
        timeout = 5;
        highlight = "#89b4fa";
      };
      urgency_normal = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        frame_color = "#89b4fa";
        timeout = 8;
        highlight = "#89b4fa";
      };
      urgency_critical = {
        background = "#1e1e2e";
        foreground = "#f38ba8";
        frame_color = "#f38ba8";
        timeout = 0;
        highlight = "#f38ba8";
      };
    };
  };
}
