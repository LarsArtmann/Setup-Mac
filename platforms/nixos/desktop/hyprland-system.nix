{ pkgs, ... }:

{
  services = {
    # Enable X11 windowing system.
    xserver = {
      enable = true;
      
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    
    # Enable SDDM (Simple Desktop Display Manager) with X11 support
    # Replaces heavier GDM/GNOME setup
    # Note: Wayland disabled for stability with AMD GPU
    displayManager.sddm = {
      enable = true;
      wayland.enable = false;  # Disabled for AMD GPU stability
      theme = "sugar-dark";
      enableHidpi = true;
      autoNumlock = true;
      extraPackages = [ pkgs.sddm-sugar-dark ];
    };
    
    # Enable D-Bus for portal communication
    dbus = {
      enable = true;
      # Use dbus-broker for better Wayland support (UWSM preferred)
      implementation = "broker";
    };
    
    # Enable sound with pipewire.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };
    
    # Pulseaudio disabled (conflicts with pipewire)
    pulseaudio.enable = false;
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

  security = {
    # Enable polkit for authentication
    polkit.enable = true;
    
    # Add Swaylock PAM service for screen locking
    pam.services.swaylock = {};
    
    # Realtime scheduling for audio
    rtkit.enable = true;
  };
  
  # Note: polkit-gnome authentication agent handled by system-level services
  # Removing manual user service to avoid conflicts

  # XDG Desktop Portals configuration (Hyprland module will set up the basic ones)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk  # For file picker support
    ];
  };

  # Enable D-Bus for portal communication
  services.dbus = {
    enable = true;
    # Use dbus-broker for better Wayland support (UWSM preferred)
    implementation = "broker";
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