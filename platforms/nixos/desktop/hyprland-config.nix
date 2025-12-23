{pkgs, ...}: {
  # Enable Hyprland with proper configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # ESSENTIAL for X11 application compatibility
    # Ensure the portal package is properly set
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    # Use UWSM for improved systemd support (recommended)
    withUWSM = true;
    # Set systemd path for proper application launching
    systemd.setPath.enable = true;
  };

  # XDG Desktop Portals configuration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk # For file picker support
    ];
  };

  # Enable dconf for settings management
  programs.dconf.enable = true;

  # Desktop integration packages
  environment.systemPackages = with pkgs; [
    # Qt Wayland support (required by some applications)
    qt5.qtwayland
    qt6.qtwayland
    # Desktop integration
    glib
  ];
}
