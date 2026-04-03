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

    # AMD GPU + NPU optimization kernel parameters for Strix Halo (128GB unified memory)
    kernelParams = [
      "amdgpu.ppfeaturemask=0xfffd7fff"
      "amdgpu.deepfl=1"
      "amd_pstate=guided"
      # GTT: allocate ~128GB for GPU compute memory via Graphics Translation Table
      "amdgpu.gttsize=131072"
      # TTM: increase page limit to ~120GB (31457280 pages × 4KB)
      "amdgpu.ttm.pages_limit=31457280"
      # Disable IOMMU for ~6% memory read improvement on Strix Halo
      "amd_iommu=off"
    ];
  };

  # TTM memory pool configuration for unified memory AI workloads
  boot.extraModprobeConfig = ''
    options amdgpu gttsize=122800
    options ttm pages_limit=31457280
    options ttm page_pool_size=31457280
  '';

  # VM sysctl tuning for AI/ML workloads on 128GB unified memory
  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # Prefer keeping model data in RAM over swap
    "vm.dirty_ratio" = 15; # Start writeback at 15% memory (~19GB)
    "vm.dirty_background_ratio" = 5; # Background writeback at 5% (~6GB)
    "vm.min_free_kbytes" = 1048576; # Keep 1GB free for GTT allocations
    "vm.max_map_count" = 2147483642; # Maximum for large model memory maps
    "vm.compaction_proactiveness" = 20; # Proactive compaction for hugepages
  };

  # Enable ZRAM for better memory management
  zramSwap = {
    enable = true;
    memoryPercent = 25; # Cap at 25% of RAM (~32GB on 128GB system)
  };
}
