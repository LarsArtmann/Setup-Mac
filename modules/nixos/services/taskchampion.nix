{inputs, ...}: {
  flake.nixosModules.taskchampion = {
    config,
    pkgs,
    lib,
    ...
  }: {
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

    systemd.services.taskchampion-sync-server.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      WatchdogSec = "30";
    };
  };
}
