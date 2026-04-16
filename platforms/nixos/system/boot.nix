{pkgs, lib, ...}: {
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
      # TTM: increase page limit for GPU page allocations
      "amdgpu.ttm.pages_limit=15728640"
      # Disable IOMMU for ~6% memory read improvement on Strix Halo
      "amd_iommu=off"
    ];
  };

  # TTM memory pool configuration for GPU workloads
  boot.extraModprobeConfig = ''
    options ttm pages_limit=15728640
    options ttm page_pool_size=15728640
  '';

  # VM sysctl tuning for AI/ML workloads (128GB unified memory)
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = lib.mkForce 0; # Heuristic overcommit — prevents wild allocation beyond capacity (overrides Redis's "1")
    "vm.swappiness" = 30; # Swap sooner to avoid sudden OOM; compressed ZRAM is fast
    "vm.dirty_ratio" = 10; # Start writeback at 10% memory (~13GB)
    "vm.dirty_background_ratio" = 3; # Background writeback at 3% (~4GB)
    "vm.min_free_kbytes" = 2097152; # Keep 2GB free for kernel/GPU allocations
    "vm.max_map_count" = 2147483642; # Maximum for large model memory maps
    "vm.compaction_proactiveness" = 20; # Proactive compaction for hugepages
    "vm.oom_kill_allocating_task" = 1; # Kill the allocating task, not an innocent victim
  };

  # Resolve upstream conflict: earlyoom sets true, smartd sets false
  services.systembus-notify.enable = lib.mkForce true;

  # Userspace OOM protection — kills the largest memory hog before the kernel panics
  # Terminates processes at ~10% free RAM / ~10% free swap, giving the system time to recover
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10; # Kill when free RAM drops below 10% (~12.8GB)
    freeSwapThreshold = 10; # Kill when free swap drops below 10%
    enableNotifications = true; # Desktop notification before killing
    extraArgs = [
      "--avoid" "^(systemd|sshd|niri|waybar|kitty|fish|pipewire)$" # Never kill these
      "--prefer" "^(llama-server|python3|python|node|java|chrome|chromium)$" # Kill these first
    ];
  };

  # Enable ZRAM for compressed swap — fast, reduces pressure on disk swap
  zramSwap = {
    enable = true;
    memoryPercent = 50; # 50% of 128GB = 64GB ZRAM (compresses ~2-3x, effective ~128-192GB buffer)
  };
}
