{pkgs, ...}: {
  # Bootloader and Kernel Configuration
  boot = {
    # Systemd boot configuration
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 50; # Limit to 50 generations to prevent /boot full
      efi.canTouchEfiVariables = true;
    };

    # Use latest kernel for Ryzen AI Max+ support
    kernelPackages = pkgs.linuxPackages_latest;

    # Load I2C module for DDC/CI monitor brightness control
    kernelModules = ["i2c-dev"];

    # AMD GPU + NPU optimization kernel parameters
    kernelParams = [
      "amdgpu.ppfeaturemask=0xfffd7fff"
      "amdgpu.deepfl=1"
      "amd_pstate=guided"
      # NPU: increase TTM page limit for unified memory AI workloads
      "amdgpu.ttm.pages_limit=29360128"
    ];
  };

  # Enable ZRAM for better memory management
  zramSwap.enable = true;
}
