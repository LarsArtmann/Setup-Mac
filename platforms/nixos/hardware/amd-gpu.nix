{ pkgs, ... }:

{
  # AMD GPU Support (Critical for Ryzen AI Max+)
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Use unstable Mesa for better performance with latest Hyprland
    package = pkgs.mesa;
    package32 = pkgs.pkgsi686Linux.mesa;
    # Note: amdvlk has been deprecated, RADV is now the default driver
    # OpenCL support via ROCm
    extraPackages = with pkgs; [
      rocmPackages.clr.icd  # OpenCL support
      # amdvlk removed - RADV is now the default AMD Vulkan driver
      libva                 # Video acceleration API
      libvdpau-va-gl       # VDPAU backend for video acceleration
    ];
  };

  # AMD GPU performance environment variables
  environment.sessionVariables = {
    # Graphics driver settings
    __GLX_VENDOR_LIBRARY_NAME = "mesa";
    LIBVA_DRIVER_NAME = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
    # Performance optimization
    MESA_VK_WSI_PRESENT_MODE = "fifo";
    # Remove problematic variables that can cause issues with modern Hyprland
    # WLR_RENDERER_ALLOW_SOFTWARE = "1";  # Only for debugging
    # WLR_NO_HARDWARE_CURSORS = "1";     # Only if cursor issues occur
  };

  # Add essential system packages for AMD GPU
  environment.systemPackages = with pkgs; [
    # AMD GPU monitoring and control
    amdgpu_top     # GPU monitoring tool
    corectrl       # AMD CPU control
    vulkan-tools   # Vulkan utilities
    mesa-demos     # GPU testing tools
  ];
}