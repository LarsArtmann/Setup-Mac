{pkgs, ...}: {
  # AMD NPU (XDNA) Support for Ryzen AI Max+ 395 (Strix Halo)
  # Requires kernel 6.14+ (6.19.8 current) with built-in amdxdna driver
  # Provides: XRT runtime, XDNA shim plugin, udev rules, memlock limits

  hardware.amd-npu = {
    enable = false;
    enableDevTools = true;
    memlockLimit = "unlimited";
  };
}
