_: {
  flake.nixosModules.taskchampion = {
    config,
    lib,
    ...
  }: let
    cfg = config.services.taskchampion-config;
  in {
    options.services.taskchampion-config = {
      enable = lib.mkEnableOption "TaskChampion sync server with SystemNix configuration";
    };

    config = lib.mkIf cfg.enable {
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
        Restart = lib.mkForce "always";
        RestartSec = lib.mkForce "5";
        StartLimitBurst = lib.mkForce 3;
        StartLimitIntervalSec = lib.mkForce 300;
        PrivateTmp = lib.mkForce true;
        NoNewPrivileges = lib.mkForce true;
        ProtectClock = lib.mkForce true;
        ProtectHostname = lib.mkForce true;
        RestrictNamespaces = lib.mkForce true;
        LockPersonality = lib.mkForce true;
      };
    };
  };
}
