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

    # AMD GPU + NPU optimization kernel parameters for Strix Halo (64GB usable, 64GB GPU/NPU)
    kernelParams = [
      "amdgpu.ppfeaturemask=0xfffd7fff"
      "amdgpu.deepfl=1"
      "amd_pstate=guided"
      # GTT: allocate ~64GB for GPU compute memory via Graphics Translation Table
      "amdgpu.gttsize=65536"
      # TTM: increase page limit for GPU page allocations
      "amdgpu.ttm.pages_limit=15728640"
      # Disable IOMMU for ~6% memory read improvement on Strix Halo
      "amd_iommu=off"
    ];
  };

  # TTM memory pool configuration for GPU workloads
  boot.extraModprobeConfig = ''
    options amdgpu gttsize=61440
    options ttm pages_limit=15728640
    options ttm page_pool_size=15728640
  '';

  # VM sysctl tuning for AI/ML workloads (64GB usable RAM, 64GB dedicated to GPU/NPU)
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 0; # Heuristic overcommit — prevents wild allocation beyond capacity
    "vm.swappiness" = 30; # Swap sooner to avoid sudden OOM; compressed ZRAM is fast
    "vm.dirty_ratio" = 10; # Start writeback at 10% memory (~6GB)
    "vm.dirty_background_ratio" = 3; # Background writeback at 3% (~2GB)
    "vm.min_free_kbytes" = 2097152; # Keep 2GB free for kernel/GTT allocations
    "vm.max_map_count" = 2147483642; # Maximum for large model memory maps
    "vm.compaction_proactiveness" = 20; # Proactive compaction for hugepages
    "vm.oom_kill_allocating_task" = 1; # Kill the allocating task, not an innocent victim
  };

  # Userspace OOM protection — kills the largest memory hog before the kernel panics
  # Terminates processes at ~10% free RAM / ~10% free swap, giving the system time to recover
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10; # Kill when free RAM drops below 10% (~6.4GB)
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
    memoryPercent = 50; # 50% of 64GB = 32GB ZRAM (compresses ~2-3x, effective ~64-96GB buffer)
  };
}
