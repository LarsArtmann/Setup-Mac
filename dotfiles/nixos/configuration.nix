{ config, pkgs, ... }:

{
  imports =
    [
      # Import common packages shared with macOS
      ../common/packages.nix
      # Include hardware configuration (will be generated on the machine)
      ./hardware-configuration.nix
    ];


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20; # Limit to 20 generations to prevent /boot full
  boot.loader.efi.canTouchEfiVariables = true;
  # Use latest kernel for Ryzen AI Max+ support
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # SSH Banner
  environment.etc."ssh/banner".source = ./ssh-banner;

  # User account
  users.users.lars = {
    isNormalUser = true;
    description = "Lars";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
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
      # Add desktop-specific packages here (that you don't want on Mac)
      pavucontrol # Audio control
      wl-clipboard # Clipboard for Wayland
      wofi # Application launcher
      waybar # Status bar
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
    extraPackages = [
      pkgs.rocmPackages.clr.icd
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
