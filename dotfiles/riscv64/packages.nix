{ config, pkgs, lib, ... }:

{
  # Import common packages shared with other architectures
  imports = [
    ../common/packages.nix
  ];

  # RISC-V specific packages

  # Add RISC-V specific packages to the existing list
  nixpkgs.config = {
    # Allow unfree packages if needed for RISC-V
    allowUnfree = lib.mkDefault true;

    # RISC-V specific package configuration
    packageOverrides = pkgs: {
      # RISC-V optimized versions of packages can be defined here
      # Example:
      # mypackage = pkgs.mypackage.overrideAttrs (old: {
      #   configureFlags = (old.configureFlags or []) ++ [ "--enable-riscv-optimizations" ];
      # });
    };
  };

  # RISC-V specific system packages (in addition to common packages)
  environment.systemPackages = with pkgs; [
    # RISC-V development tools
    gcc
    gdb
    binutils
    gnumake

    # Cross-compilation support
    buildPackages.qemu

    # RISC-V specific tools
    dtc              # Device Tree Compiler
    riscv64-unknown-elf-binutils  # RISC-V cross-binutils

    # Hardware debugging tools
    usbutils         # lsusb
    pciutils        # lspci

    # Performance monitoring for RISC-V
    perf

    # File systems commonly used on RISC-V boards
    e2fsprogs       # ext4
    dosfstools       # FAT
    btrfs-progs     # Btrfs

    # Network debugging tools
    wireshark-cli
    tcpdump

    # System monitoring optimized for embedded systems
    htop
    iotop
    iftop

    # RISC-V specific benchmarking tools
    riscv-tools

    # Embedded development tools
    openocd          # On-Chip Debugger
    picocom          # Minimal serial terminal

    # Boot configuration tools
    u-boot-tools     # For working with U-Boot
  ];

  # RISC-V specific environment variables
  environment.variables = {
    # Optimize for RISC-V architecture
    RUSTFLAGS = "-C target-cpu=generic-rv64";
    CARGO_BUILD_TARGET = "riscv64gc-unknown-linux-gnu";

    # Cross-compilation support
    CROSS_COMPILE = "riscv64-unknown-linux-gnu-";
    ARCH = "riscv";

    # Performance tuning for embedded systems
    MALLOC_TRIM_THRESHOLD_ = "100000";
  };

  # Development environment configuration
  programs = {
    # Enable RISC-V specific development tools
    fish = {
      enable = true;
      # RISC-V specific fish completions and functions can be added here
    };

    # Configure vim for RISC-V development
    vim = {
      enable = true;
      # RISC-V specific vim configuration
      defaultEditor = true;
    };
  };

  # RISC-V specific services
  services = {
    # Enable hardware monitoring
    lm_sensors = {
      enable = true;
      # Common sensors for RISC-V boards
      hwmonConfig = ''
        # Auto-detect sensors
        chip "*"
      '';
    };

    # Early OOM for memory-constrained systems
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;  # 5% free memory threshold
      enableNotifications = true;
    };
  };

  # Performance tuning for RISC-V characteristics
  systemd = {
    # Reduce journal size to save disk space (common on RISC-V boards)
    extraConfig = ''
      [Journal]
      Storage=volatile
      RuntimeMaxUse=100M
      SystemMaxUse=200M
    '';

    # Optimize services for embedded systems
    services = {
      # Disable services not commonly needed on RISC-V boards
      "systemd-journal-flush".enable = lib.mkDefault false;
      "systemd-update-utmp".enable = lib.mkDefault false;

      # Optimize core services
      "systemd-journald".serviceConfig = {
        # Reduce memory usage
        MemoryMax = "100M";
        # Reduce disk I/O
        RateLimitIntervalSec = "30s";
        RateLimitBurst = 10000;
      };
    };
  };

  # File system optimizations for RISC-V boards
  fileSystems = lib.mkIf (config.fileSystems ? "/") {
    "/" = {
      options = [
        "noatime"         # Reduce disk I/O
        "commit=30"       # Reduce write frequency
        "data=ordered"    # Safer data ordering
      ];
    };
  };

  # Network configuration for RISC-V boards
  networking = {
    # Enable firewall with reduced rules for embedded systems
    firewall.enable = lib.mkDefault true;

    # Optimize for wireless networks (common on RISC-V boards)
    wireless = {
      enable = lib.mkDefault true;
      # Configure as needed for specific wireless hardware
    };
  };

  # Power management for battery-powered RISC-V boards
  powerManagement = {
    enable = true;

    # Conservative power settings for embedded systems
    cpuFreqGovernor = lib.mkDefault "ondemand";

    # Power management for RISC-V CPUs
    powertop.enable = lib.mkDefault true;
  };

  # Security configuration optimized for embedded systems
  security = {
    # Basic security without heavy overhead
    sudo.wheelNeedsPassword = false;

    # AppArmor (if supported on RISC-V)
    apparmor.enable = lib.mkDefault false;  # Disable to reduce overhead

    # SELinux (if supported on RISC-V)
    selinux.enable = lib.mkDefault false;   # Disable to reduce overhead
  };

  # User-specific RISC-V packages
  users.users.lars = {
    packages = with pkgs; [
      # Development tools for the user
      git
      vim

      # RISC-V specific user tools
      riscv-tools

      # System monitoring for the user
      htop
      iotop
    ];
  };
}