{ pkgs, ... }:

{
  # Enable multiple window managers alongside Hyprland
  # This allows switching between different WMs at SDDM login screen

  # Sway - i3 successor for stable tiling
  programs.sway = {
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
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # LabWC - Openbox-inspired floating window manager
  programs.labwc = {
    enable = true;
  };

  # Awesome - Dynamic window manager with Lua scripting
  services.xserver.windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      lgi
    ];
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

    # Authentication agents
    polkit_gnome

    # XDG utilities
    xdg-utils

    # Audio utilities
    pavucontrol

    # Screenshot tools
    grim
    slurp

    # Clipboard
    wl-clipboard
  ];

  # D-Bus is enabled in hyprland-system.nix to avoid duplication

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Polkit authentication agent handled by system-level services
  # Removed manual user service to avoid conflicts with UWSM

  # XDG Desktop Portals configuration (works with all WMs)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk  # For file picker support
      pkgs.xdg-desktop-portal-wlr  # For wlroots-based WMs
    ];
  };

  # Configure keymap in X11 (for X11-based WMs)
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire (shared across all WMs)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable dconf for settings management
  programs.dconf.enable = true;
}