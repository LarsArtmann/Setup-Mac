{ config, pkgs, ... }:

{
  imports =
    [
      # Import common packages shared with macOS
      ../../common/packages/base.nix
      # Include hardware configuration (will be generated on the machine)
      ../hardware/hardware-configuration.nix
    ];


  # Bootloader and Kernel Configuration
  boot = {
    # Systemd boot configuration
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 20; # Limit to 20 generations to prevent /boot full
      efi.canTouchEfiVariables = true;
    };

    # Use latest kernel for Ryzen AI Max+ support
    kernelPackages = pkgs.linuxPackages_latest;

    # AMD GPU optimization kernel parameters
    kernelParams = [
      "amdgpu.ppfeaturemask=0xfffd7fff"  # Enable all GPU features
      "amdgpu.deepfl=1"                  # Enable deep frequency control
      "amd_pstate=guided"                # Performance mode for AMD CPUs
      "processor.max_cstate=1"           # C-state optimization
    ];
  };

  # Enable ZRAM for better memory management
  zramSwap.enable = true;

  # Networking
  networking.hostName = "evo-x2"; # Machine name
  networking.networkmanager.enable = true;

  # Enable OpenSSH daemon with hardening
  services.openssh = {
    enable = true;
    settings = {
      # Basic hardening
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;

      # Key-based authentication only
      PubkeyAuthentication = true;
      AuthorizedKeysFile = ".ssh/authorized_keys";

      # Security settings
      Protocol = 2;
      X11Forwarding = false;
      AllowTcpForwarding = false;
      PermitTunnel = false;

      # Access control
      AllowUsers = [ "lars" ]; # Only allow lars user

      # Connection limits
      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 300; # 5 minutes
      ClientAliveCountMax = 2;

      # Strong cryptographic settings
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];



      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group14-sha256"
      ];

      # Logging
      LogLevel = "VERBOSE";

      # Banner
      Banner = "/etc/ssh/banner";
    };

    # Enable fail2ban integration for SSH protection
    openFirewall = true;
    ports = [ 22 ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin"; # Adjust as needed

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable SDDM (Simple Desktop Display Manager) with Wayland support
  # Replaces heavier GDM/GNOME setup
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

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

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true; # Not needed with pipewire
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
    # AMD GPU monitoring and control
    amdgpu_top     # GPU monitoring tool
    corectrl       # AMD CPU control
    vulkan-tools   # Vulkan utilities
    mesa-demos     # GPU testing tools
  ];

  # AMD GPU performance environment variables
  environment.sessionVariables = {
    # Graphics driver settings
    __GLX_VENDOR_LIBRARY_NAME = "mesa";
    LIBVA_DRIVER_NAME = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
    # Wayland/Hyprland specific
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    # Performance optimization
    MESA_VK_WSI_PRESENT_MODE = "fifo";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable dconf for settings management
  programs.dconf.enable = true;

  # SSH Banner
  environment.etc."ssh/banner".source = ../users/ssh-banner;

  # User account
  users.users.lars = {
    isNormalUser = true;
    description = "Lars";
    extraGroups = [ "networkmanager" "wheel" "docker" "input" "video" "audio" ];
    # INFO: Set password manually with `passwd lars` after installation
    # NOTE: After SSH hardening, password auth will be disabled - you MUST set up SSH keys
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # IMPORTANT: Replace this placeholder with your actual SSH public key!
      # You can add multiple keys - one per line
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-key-comment"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPlbcK0pvybFGNvQWDVxHmMZkjUHXa9JcnPcKWSZWE8 lars@MacBook-Air.local"
    ];
    packages = with pkgs; [
      firefox
      # Desktop packages are now managed via Home Manager (see platforms/nixos/desktop/hyprland.nix)
    ];
  };

  # Enable Fish shell system-wide
  programs.fish.enable = true;



  # AMD GPU Support (Critical for Ryzen AI Max+)
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Note: amdvlk has been deprecated, RADV is now the default driver
    # OpenCL support via ROCm
    extraPackages = with pkgs; [
      rocmPackages.clr.icd  # OpenCL support
      # amdvlk removed - RADV is now the default AMD Vulkan driver
      libva                 # Video acceleration API
      libvdpau-va-gl       # VDPAU backend for video acceleration
    ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
  ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "25.11";
}
