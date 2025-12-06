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
  boot.loader.efi.canTouchEfiVariables = true;
  # Use latest kernel for Ryzen AI Max+ support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.hostName = "evo-x2"; # Machine name
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin"; # Adjust as needed

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment (as backup/login manager)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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

  # User account
  users.users.lars = {
    isNormalUser = true;
    description = "Lars";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # AMD GPU Support (Critical for Ryzen AI Max+)
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Note: amdvlk has been deprecated, RADV is now the default driver
    # OpenCL support can be added with rocm-packages if needed
  };

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "24.05";
}
