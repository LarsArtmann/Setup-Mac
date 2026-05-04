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
      "amdgpu.gpu_recovery=1" # Attempt GPU reset on hang instead of leaving GPU in dead state
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

    binfmt.emulatedSystems = ["aarch64-linux"];
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

    # Crash recovery — prevent needing hard power cuts when GPU/driver hangs
    "kernel.sysrq" = 1; # Full SysRq — enables REISUB emergency reboot from keyboard
    "kernel.panic" = 30; # Auto-reboot 30s after kernel panic (time to read/photograph stack trace, then recover)
    "kernel.softlockup_panic" = 1; # Panic on soft lockup (CPU stuck in kernel with interrupts disabled)
    "kernel.watchdog_thresh" = 20; # Soft lockup detection threshold in seconds (default: 10, raised to avoid GPU compute false positives)
    "kernel.hung_task_panic" = 1; # Panic when a task is stuck in D state for too long
    "kernel.hung_task_timeout_secs" = 120; # Hung task timeout (default: 120 = 2 min)
    "vm.panic_on_oom" = 0; # Don't panic on OOM — let OOM killer do its job (earlyoom handles this)
  };

  # Raise per-user process limit — default 4096 is too low for desktop + AI workloads
  # (4832 threads across 297 processes observed, causing niri EAGAIN on thread spawn)
  security.pam.loginLimits = [
    {
      domain = "@users";
      type = "soft";
      item = "nproc";
      value = "65536";
    }
    {
      domain = "@users";
      type = "hard";
      item = "nproc";
      value = "262144";
    }
  ];

  # Protect critical services from OOM killer
  # sshd: -1000 (maximum protection — remote access is the last resort)
  # NixOS sets -1000 by default for sshd, but be explicit to prevent overrides
  # niri: -900 (compositor death = entire desktop gone, but SSH should outlive it)
  # caddy: -500 (reverse proxy loss means all services unreachable)
  # journald: -500 (lost journald = lost crash diagnostics — saw this in the real OOM event)
  systemd.services = {
    "sshd".serviceConfig.OOMScoreAdjust = -1000;
    "systemd-journald".serviceConfig.OOMScoreAdjust = -500;
  };

  systemd.user.services = {
    "waybar".serviceConfig.OOMScoreAdjust = -500;
    "pipewire".serviceConfig.OOMScoreAdjust = -500;
  };

  # Hardware watchdog — last resort: hard-reboots the system if it becomes completely unresponsive.
  # SP5100 TCO timer (AMD chipset) will fire if watchdogd stops petting it within the timeout.
  # Catches GPU driver hangs, kernel deadlocks, and other scenarios where even SysRq fails.
  services = {
    watchdogd = {
      enable = true;
      settings = {
        device = "/dev/watchdog0";
        timeout = 30; # Hard reset after 30s without a kick
        interval = 10; # Pet the watchdog every 10s
        safe-exit = true; # Disable WDT on clean shutdown
        meminfo = {
          enabled = true;
          warning = 0.95; # Warn at 95% RAM usage
          critical = 0.98; # Reboot at 98% RAM usage (OOM imminent, system likely unresponsive)
        };
      };
    };

    systembus-notify.enable = lib.mkForce true;

    earlyoom = {
      enable = true;
      freeMemThreshold = 10; # Kill when free RAM drops below 10% (~12.8GB)
      freeSwapThreshold = 10; # Kill when free swap drops below 10%
      enableNotifications = true; # Desktop notification before killing
      extraArgs = [
        "--avoid"
        "^(systemd|sshd|niri|waybar|kitty|fish|pipewire)$" # Never kill these
        "--prefer"
        "^(ollama|llama-server|python3|python|node|java|chrome|chromium|generate_happy_girl)$" # Kill these first
      ];
    };
  };

  # Enable ZRAM for compressed swap — fast, reduces pressure on disk swap
  zramSwap = {
    enable = true;
    memoryPercent = 50; # 50% of 128GB = 64GB ZRAM (compresses ~2-3x, effective ~128-192GB buffer)
  };
}
