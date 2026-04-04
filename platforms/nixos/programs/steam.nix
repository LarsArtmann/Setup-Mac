{
  lib,
  config,
  pkgs,
  ...
}:
{
  # Steam support for Linux gaming
  programs.steam = {
    enable = true;
    # Enable remote play via Steam's streaming feature
    remotePlayTogether.enable = true;
  };

  # Steam hardware support for controllers and VR
  hardware.steam-hardware = {
    enable = true;
    # Enable NVIDIA GPU support (for hybrid graphics laptops with Steam)
    nvidiaSupport = false;
  };

  # Add Steam to system packages
  environment.systemPackages = with pkgs; [
    steam
  ];
}
