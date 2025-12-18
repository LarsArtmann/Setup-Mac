{ pkgs, ... }:

{
  # Enable X11 windowing system.
  services.xserver.enable = true;

  # Enable SDDM (Simple Desktop Display Manager) with Wayland support
  # Replaces heavier GDM/GNOME setup
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = pkgs.sddm-sugar-dark;
  };

  # Enable Hyprland with proper configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # ESSENTIAL for X11 application compatibility
    # Ensure the portal package is properly set
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    # Use UWSM for improved systemd support (recommended)
    withUWSM = true;
    # Set systemd path for proper application launching
    systemd.setPath.enable = true;
  };

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Add polkit GNOME authentication agent service
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

  # Add Swaylock PAM service for screen locking
  security.pam.services.swaylock = {};

  # XDG Desktop Portals configuration (Hyprland module will set up the basic ones)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk  # For file picker support
    ];
  };

  # Enable D-Bus for portal communication
  services.dbus.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Add essential system packages for Hyprland
  environment.systemPackages = with pkgs; [
    # SDDM theme for beautiful login screen
    sddm-sugar-dark
    # Authentication and portal support
    polkit_gnome
    xdg-utils
    # Qt Wayland support (required by some applications)
    qt5.qtwayland
    qt6.qtwayland
    # Desktop integration
    glib
    # Authentication helper
    gnome-keyring
  ];

  # Enable dconf for settings management
  programs.dconf.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}