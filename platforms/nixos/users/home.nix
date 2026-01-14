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
      size = 11;
    };
  };

  # Qt cursor settings for consistency
  qt = {
    enable = true;
    platformTheme = "adwaita";
  };
}
