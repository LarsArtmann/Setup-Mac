{inputs, ...}: {
  flake.nixosModules.taskchampion = {
    config,
    pkgs,
    lib,
    ...
  }: let
    systemd = import ../../../lib/systemd.nix {inherit lib;};
  in {
    services.taskchampion-sync-server = {
      enable = true;
      host = "127.0.0.1";
      port = 10222;
      openFirewall = false;
      snapshot = {
        versions = 100;
        days = 14;
      };
    };

    systemd.services.taskchampion-sync-server.serviceConfig =
      systemd.mkHardenedServiceConfig {memoryMax = "256M";}
      // systemd.mkServiceRestartConfig {watchdogSec = "30";};
  };
}
