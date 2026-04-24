{...}: {
  flake.nixosModules.monitoring = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      radeontop # AMD GPU specific monitor (CLI, lightweight)
      # nvtopPackages.amd moved to hardware/amd-gpu.nix (alongside other GPU tools)
      # amdgpu_top moved to hardware/amd-gpu.nix (available system-wide)

      # System monitoring
      # btop moved to base.nix (available cross-platform)

      # System monitoring and debugging
      strace # System call tracer
      ltrace # Library call tracer

      # Network monitoring
      nethogs # Network process monitoring
      iftop # Network bandwidth
    ];
  };
}
