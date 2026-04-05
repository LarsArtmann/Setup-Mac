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
      general = {
        renice = 10;
      };
      gpu = {
        gputempthreshold = 80;
      };
      cpu = {
        Governor = "performance";
      };
    };
  };

  # Add Steam, GameMode, and MangoHud to system packages
  environment.systemPackages = with pkgs; [
    steam
    gamemode
    mangohud
  ];
}
