{ pkgs, ... }:

{
  # Enable multiple window managers alongside Hyprland
  # This allows switching between different WMs at SDDM login screen

  programs = {
    # Sway - i3 successor for stable tiling
    sway = {
      enable = true;
      wrapperFeatures.gtk = true; # So that GTK applications work properly
      extraPackages = with pkgs; [
        swaylock # Screen locker
        swayidle # Idle management daemon
        waybar # Status bar
        wofi # Application launcher
        foot # Terminal
      ];
    };

    # Niri - Scrollable tiling window manager
    niri = {
      enable = true;
      package = pkgs.niri;
    };

    # LabWC - Openbox-inspired floating window manager
    labwc = {
      enable = true;
    };
  };

  services = {
    xserver = {
      # Awesome - Dynamic window manager with Lua scripting
      windowManager.awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          lgi
        ];
      };

      # Configure keymap in X11 (for X11-based WMs)
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  # Additional packages needed for all window managers
  environment.systemPackages = with pkgs; [
    # Common terminal for all WMs
    foot

    # Application launcher for all WMs
    wofi

    # Screen lockers
    swaylock

    # Status bars - REMOVED to avoid conflicts with Home Manager
    # waybar # Already configured in Home Manager waybar.nix

    # File manager
    kdePackages.dolphin

    # Notification daemon
    mako

    # Background settings
    swaybg

    # Authentication agents and XDG utilities moved to security-hardening.nix
    # - polkit_gnome, xdg-utils

    # Audio utilities
    pavucontrol

    # Screenshot tools
    grim
    slurp

    # Clipboard
    wl-clipboard
  ];


}