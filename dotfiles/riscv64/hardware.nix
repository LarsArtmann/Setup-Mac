{ config, pkgs, lib, ... }:

{
  # RISC-V specific hardware configuration

  # Kernel modules commonly needed for RISC-V boards
  boot.initrd.availableKernelModules = [
    # USB support
    "usb_storage"
    "usbhid"

    # Common file systems
    "ext4"
    "vfat"
    "btrfs"

    # Network interfaces
    "rtl8150"  # Realtek USB Ethernet
    "smsc95xx" # SMSC LAN95xx USB Ethernet
    "r8169"    # Realtek PCIe Ethernet

    # SD/MMC card readers
    "mmc_block"
    "mmc_core"
    "sdhci"

    # Display (if applicable)
    "drm"
    "drm_kms_helper"
    "simpledrm"

    # Input devices
    "evdev"
    "hid_generic"
    "hid_multitouch"
  ];

  # Additional kernel modules
  boot.kernelModules = [
    # RISC-V specific features
    "riscv_pmu"     # Performance Monitoring Unit
    "riscv_gpio"    # GPIO support
    "riscv_iommu"   # IOMMU support

    # Thermal management
    "thermal"
    "gpio_thermal"

    # Power management
    "cpuidle"

    # Hardware monitoring
    "hwmon"
    "hwmon_vid"
  ];

  # Kernel parameters optimized for RISC-V
  boot.kernelParams = [
    # Memory management
    "cma=256M"      # Contiguous Memory Allocator for devices

    # Console configuration
    "console=ttyS0,115200n8"  # Serial console for debugging
    "console=tty0"            # Framebuffer console

    # RISC-V specific
    "nopti"         # Page Table Isolation (not needed on RISC-V)
    "nospectre_v2"  # Spectre V2 mitigation (RISC-V specific)

    # Performance
    "mitigations=off"  # Disable performance-reducing mitigations
  ];

  # RISC-V specific firmware (if applicable)
  hardware.firmware = with pkgs; [
    # Add firmware packages as needed for specific boards
    # wireless-firmware
    # linux-firmware
  ];

  # Device Tree configuration (important for RISC-V boards)
  hardware.deviceTree = {
    enable = true;

    # Enable device tree overlays for board-specific hardware
    # overlays = [
    #   {
    #     name = "custom-overlay";
    #     dtsFile = ./overlays/custom.dts;
    #   }
    # ];
  };

  # GPU configuration (typically minimal for RISC-V boards)
  hardware.graphics = {
    enable = true;

    # RISC-V boards typically use software rendering or simple GPUs
    # No 32-bit support needed for RISC-V
    enable32Bit = false;

    # Use llvmpipe for software rendering if no hardware GPU
    extraPackages = with pkgs; [
      mesa.drivers
      mesa.opencl
    ];
  };

  # Sound configuration for RISC-V boards
  hardware.pulseaudio.enable = lib.mkDefault false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;  # Not needed for RISC-V
    pulse.enable = true;

    # Low latency configuration for embedded systems
    config.pipewire-pulse = {
      "context.properties" = {
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 256;
      };
    };
  };

  # Network configuration for RISC-V boards
  networking = {
    # Enable DHCP for automatic network configuration
    useDHCP = lib.mkDefault true;

    # Enable network manager for WiFi support
    networkmanager.enable = true;

    # Network interface configuration (adjust for specific board)
    # interfaces.enp1s0.ipv4.addresses = [{
    #   address = "192.168.1.100";
    #   prefixLength = 24;
    # }];
  };

  # USB configuration for RISC-V boards
  services.udev.extraRules = ''
    # Allow USB devices without additional permissions
    SUBSYSTEM=="usb", MODE="0666"
    SUBSYSTEM=="usb_device", MODE="0666"

    # Serial port configuration for debugging
    KERNEL=="ttyS*", GROUP="dialout", MODE="0666"
    KERNEL=="ttyUSB*", GROUP="dialout", MODE="0666"
    KERNEL=="ttyACM*", GROUP="dialout", MODE="0666"
  '';

  # Hardware monitoring for RISC-V boards
  services.lm_sensors = {
    enable = true;

    # Common sensors for RISC-V boards
    hwmonConfig = ''
      # Load common sensor drivers
      # Adjust based on actual board sensors
      chip "riscv-*"
    '';
  };

  # Thermal management (important for embedded RISC-V boards)
  services.thermald.enable = lib.mkDefault true;
  services.auto-cpufreq.enable = lib.mkDefault true;

  # Early boot services for hardware initialization
  systemd.services = {
    # Hardware initialization service
    riscv-hw-init = {
      description = "RISC-V Hardware Initialization";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udevd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"RISC-V hardware initialized\"'";
        RemainAfterExit = true;
      };
    };
  };
}