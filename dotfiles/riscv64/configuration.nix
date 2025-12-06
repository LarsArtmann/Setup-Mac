{ config, pkgs, lib, TypeAssertions, ConfigAssertions, ModuleAssertions, Types, UserConfig, PathConfig, State, Validation, ... }:

{
  imports = [
    ../nixos/configuration.nix
    ./hardware.nix
    ./packages.nix
  ];

  # RISC-V specific system configuration

  # System identification
  networking.hostName = "riscv64-nixos";

  # RISC-V kernel configuration
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # RISC-V specific boot settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;

  # File systems optimized for RISC-V
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  # Binary cache configuration for RISC-V (essential to avoid building from source)
  nix.settings = {
    substituters = [
      "https://cache.ztier.in"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.ztier.link-1:3P5j2ZB9dNgFFFVkCQWT3mh0E+S3rIWtZvoql64UaXM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPSQI4R6DEizwc="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # RISC-V specific optimizations
    system-features = [ "riscv64" "big-parallel" "kvm" ];

    # Resource limits for RISC-V (typically lower-powered hardware)
    max-jobs = lib.mkDefault 2;
  };

  # RISC-V specific hardware settings
  hardware = {
    # Enable CPU frequency scaling for power management
    cpu.intel.updateMicrocode = lib.mkDefault false; # No Intel CPUs on RISC-V
    cpu.amd.updateMicrocode = lib.mkDefault false; # No AMD CPUs on RISC-V

    # Graphics configuration (typically minimal for RISC-V boards)
    graphics = {
      enable = true;
      # Use software rendering by default unless specific GPU present
      enable32Bit = lib.mkDefault false;
    };
  };

  # Power management optimized for RISC-V characteristics
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  # Swap configuration (important for memory-constrained RISC-V boards)
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB swap for memory-constrained systems
    }
  ];

  # Time zone (adjust as needed)
  time.timeZone = "Europe/Berlin";

  # RISC-V specific services
  services = {
    # Enable udev for hardware management
    udev.enable = true;

    # Enable early boot console for debugging
    earlyoom.enable = lib.mkDefault true;

    # Disable services not commonly needed on RISC-V boards
    printing.enable = lib.mkDefault false;
    avahi.enable = lib.mkDefault true; # For network discovery

    # Audio (basic configuration)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = false;
      pulse.enable = true;
    };
  };

  # User configuration
  users.users.lars = {
    isNormalUser = true;
    description = "Lars";
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    shell = pkgs.fish;
  };

  # RISC-V specific environment variables
  environment.variables = {
    # Optimize for RISC-V architecture
    RUSTFLAGS = lib.mkDefault "-C target-cpu=generic-rv64";
    CARGO_BUILD_TARGET = lib.mkDefault "riscv64gc-unknown-linux-gnu";
  };

  # Ghost Systems integration
  config.system.assertions = [
    {
      assertion = TypeAssertions != null;
      message = "Ghost Systems TypeAssertions not injected into RISC-V configuration!";
    }
    {
      assertion = pkgs.stdenv.isRiscV;
      message = "This configuration is specifically for RISC-V architecture!";
    }
  ];

  # Internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # System packages (RISC-V optimized)
  environment.systemPackages = with pkgs; [
    # System management
    vim
    git
    curl
    wget

    # RISC-V specific tools
    qemu
    dtc # Device Tree Compiler

    # Network tools
    networkmanager
    wireless-tools

    # File systems
    e2fsprogs
    dosfstools

    # Hardware monitoring
    lm_sensors
    htop
  ];

  # Security
  security.sudo.wheelNeedsPassword = false;

  # System version
  system.stateVersion = "24.05";
}