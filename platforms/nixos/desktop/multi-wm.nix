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
    config = {
      # Basic LabWC configuration
      theme = {
        name = "Adwaita-dark";
        fontName = "sans";
        fontSize = 11;
      };
      keyboard = {
        keybind = [
          # Basic keybinds
          {
            key = "A-Tab";
            action = "NextWindow";
          }
          {
            key = "A-F4";
            action = "Close";
          }
          {
            key = "A-Return";
            action = "Execute";
            command = "foot";
          }
          {
            key = "A-space";
            action = "ShowMenu";
            command = "root-menu";
          }
        ];
      };
      mouse = {
        defaultAction = "Move";
        context = [
          {
            name = "Root";
            action = "ShowMenu";
            command = "root-menu";
          }
          {
            name = "TitleBar";
            action = "Focus";
          }
        ];
      };
    };
  };

  # Awesome - Dynamic window manager with Lua scripting
  programs.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      lgi
    ];
  };

  # X11 Window Manager for Awesome (since Awesome is X11-based)
  services.xserver.windowManager.awesome.enable = true;

  # Additional packages needed for all window managers
  environment.systemPackages = with pkgs; [
    # Common terminal for all WMs
    foot

    # Application launcher for all WMs
    wofi

    # Screen lockers
    swaylock

    # Status bars
    waybar

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

  # Enable D-Bus for all window managers
  services.dbus.enable = true;

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Add polkit GNOME authentication agent service (shared)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

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