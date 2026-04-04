{
  lib,
  config,
  pkgs,
  ...
}: {
  # Steam support for Linux gaming
  programs.steam = {
    enable = true;
  };

  # Steam hardware support for controllers and VR
  hardware.steam-hardware = {
    enable = true;
  };

  # Add Steam to system packages
  environment.systemPackages = with pkgs; [
    steam
  ];
}
