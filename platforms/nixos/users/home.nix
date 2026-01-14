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

    # Cursor size (3x extra large for TV display)
    XCURSOR_SIZE = "144";
  };

  # NixOS-specific packages
  home.packages = with pkgs; [
    # GUI Tools
    pavucontrol # Audio control (user-level access for audio settings)
    signal-desktop # Secure messaging application

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

  # XDG Directories (Linux specific)
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # GTK settings for cursor size and theme
  gtk = {
    enable = true;
    cursorTheme = {
      name = "Adwaita";
      size = 144;
    };
    font = {
      name = "Sans";
      size = 11;
    };
  };
}
