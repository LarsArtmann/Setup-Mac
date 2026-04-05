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

  # GameMode - optimize CPU/GPU performance for games
  programs.gamemode = {
    enable = true;
    settings = {
      Governor = "performance";
      gputempthreshold = 80;
      renice = 10;
    };
  };

  # Add Steam, GameMode, and MangoHud to system packages
  environment.systemPackages = with pkgs; [
    steam
    gamemode
    mangohud
  ];
}
