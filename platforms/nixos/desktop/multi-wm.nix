{pkgs, ...}: {
  # Backup window manager alongside Niri
  # This allows switching between different WMs at SDDM login screen

  programs = {
    # Sway - i3 successor for stable tiling (backup WM)
    sway = {
      enable = true;
      wrapperFeatures.gtk = true; # So that GTK applications work properly
      extraPackages = with pkgs; [
        swaylock-effects # Screen locker with blur effects
        swayidle # Idle management daemon
        waybar # Status bar
        wofi # Application launcher
        foot # Terminal
      ];
    };
  };

  services = {
    xserver = {
      # Configure keymap in X11 (for X11-based WMs like Sway)
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  # Additional packages needed for Sway backup WM
  environment.systemPackages = with pkgs; [
    # Common terminal - foot included in sway extraPackages above

    # Application launcher for all WMs
    wofi
    rofi

    # Screen lockers
    swaylock-effects

    # Status bars - REMOVED to avoid conflicts with Home Manager
    # waybar # Already configured in Home Manager waybar.nix

    # File manager
    kdePackages.dolphin

    # Notification daemon
    mako

    # Screenshot tools
    grim
    slurp

    # Clipboard
    wl-clipboard
  ];
}
