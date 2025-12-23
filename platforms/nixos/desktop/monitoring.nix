{ pkgs, lib, ... }:

{
  # Performance monitoring
  environment.systemPackages = with pkgs; [
    # GPU monitoring
    nvtopPackages.amd

    # System monitoring and debugging
    strace  # System call tracer
    ltrace  # Library call tracer

    # Network monitoring
    nethogs  # Network process monitoring
    iftop  # Network bandwidth
  ];
}
