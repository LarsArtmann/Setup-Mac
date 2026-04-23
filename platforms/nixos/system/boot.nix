{
  pkgs,
  lib,
  ...
}: {
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
      # Disabled 2026-04-20: overdrive was causing GPU hangs → niri SIGABRT → full desktop crash.
      # The kernel warns: "amdgpu: Overdrive is enabled, please disable it before reporting any bugs"
      # Re-enable only if you need manual fan/clk control and accept the instability risk.
      # "amdgpu.ppfeaturemask=0xfffd7fff"
      "amdgpu.deepfl=1"
      # Increase ring lockup timeout (default 10s) — prevents false-positive GPU resets
      # under heavy compute/ML workloads on Strix Halo
      "amdgpu.lockup_timeout=30000"
      "amd_pstate=guided"
      # GTT: allocate ~128GB for GPU compute memory via Graphics Translation Table
      # Without this, kernel defaults to ~31GB GTT, crippling AI workloads on unified memory.
      # Removed in crash fix but root cause was overdrive (now disabled), not GTT sizing.
      "amdgpu.gttsize=131072"
      # TTM: increase page limit to ~120GB for GPU page allocations
      "amdgpu.ttm.pages_limit=31457280"
      # IOMMU enabled — required for full 128GB memory mapping on Strix Halo.
      # Previously set to "off" for ~6% memory read improvement, but this prevented
      # the kernel from seeing the upper 64GB of RAM (only 64GB of 128GB visible).
      "amd_iommu=on"
    ];
  };

  # TTM memory pool configuration for GPU workloads (128GB unified memory)
  boot.extraModprobeConfig = ''
    options amdgpu gttsize=131072
    options ttm pages_limit=31457280
    options ttm page_pool_size=31457280
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
    "vm.oom_kill_allocating_task" = 0; # Let kernel pick the biggest memory hog (not the allocating process)
  };

  # Protect critical services from OOM killer
  # These must survive memory pressure — killing them makes the system unusable
  systemd.services = {
    "sshd".serviceConfig.OOMScoreAdjust = -500;
    "systemd-journald".serviceConfig.OOMScoreAdjust = -250;
  };

  # Protect niri (user service) from OOM — without it the entire desktop dies
  systemd.user.services = {
    "niri".serviceConfig.OOMScoreAdjust = -500;
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
      "--avoid"
      "^(systemd|sshd|niri|waybar|kitty|fish|pipewire)$" # Never kill these
      "--prefer"
      "^(ollama|llama-server|python3|python|node|java|chrome|chromium)$" # Kill these first
    ];
  };

  # Enable ZRAM for compressed swap — fast, reduces pressure on disk swap
  zramSwap = {
    enable = true;
    memoryPercent = 50; # 50% of 128GB = 64GB ZRAM (compresses ~2-3x, effective ~128-192GB buffer)
  };
}
