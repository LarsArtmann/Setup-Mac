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
      Restart = lib.mkForce "on-failure";
      RestartSec = lib.mkForce "5";
      PrivateTmp = lib.mkForce true;
      NoNewPrivileges = lib.mkForce true;
      ProtectClock = lib.mkForce true;
      ProtectHostname = lib.mkForce true;
      RestrictNamespaces = lib.mkForce true;
      LockPersonality = lib.mkForce true;
      WatchdogSec = lib.mkForce "30";
    };
  };
}
