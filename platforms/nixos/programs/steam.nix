{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.steam = {
    enable = true;
    extest.enable = true;
    localNetworkGameTransfers.openFirewall = true;
    protontricks.enable = true;
  };

  hardware.steam-hardware = {
    enable = true;
  };

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

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    steam
    gamemode
    mangohud
    gamescope
  ];
}
