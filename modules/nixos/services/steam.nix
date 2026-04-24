{...}: {
  flake.nixosModules.steam = {
    lib,
    config,
    pkgs,
    ...
  }: {
    programs = {
      steam = {
        enable = true;
        extest.enable = true;
        localNetworkGameTransfers.openFirewall = false;
        protontricks.enable = true;
      };

      gamemode = {
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

      gamescope = {
        enable = true;
        capSysNice = true;
      };
    };

    hardware.steam-hardware = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      steam
      gamemode
      mangohud
      gamescope
    ];
  };
}
