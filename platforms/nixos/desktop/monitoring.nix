{ pkgs, lib, ... }:

{
  # Performance monitoring
  environment.systemPackages = with pkgs; [
    # GPU monitoring
    nvtopPackages.amd
    radeontop  # AMD GPU specific monitor (CLI)
    amdgpu_top  # Advanced AMD GPU monitoring (CLI)

    # System monitoring
    btop  # System monitor

    # System monitoring and debugging
    strace  # System call tracer
    ltrace  # Library call tracer

    # Network monitoring
    nethogs  # Network process monitoring
    iftop  # Network bandwidth
  ];
}
