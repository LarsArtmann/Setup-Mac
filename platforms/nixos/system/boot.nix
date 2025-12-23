{pkgs, ...}: {
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
      "amdgpu.ppfeaturemask=0xfffd7fff" # Enable all GPU features
      "amdgpu.deepfl=1" # Enable deep frequency control
      "amd_pstate=guided" # Performance mode for AMD CPUs
      "processor.max_cstate=1" # C-state optimization
    ];
  };

  # Enable ZRAM for better memory management
  zramSwap.enable = true;
}
