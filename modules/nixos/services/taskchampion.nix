_: {
  flake.nixosModules.taskchampion = {
    config,
    lib,
    ...
  }: let
    cfg = config.services.taskchampion-config;
    harden = import ../../../lib/systemd.nix;
    serviceDefaults = import ../../../lib/systemd/service-defaults.nix;
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

      systemd.services.taskchampion-sync-server.serviceConfig =
        harden {}
        // serviceDefaults {};
    };
  };
}
