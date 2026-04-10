{inputs, ...}: {
  flake.nixosModules.taskchampion = {
    config,
    pkgs,
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
  };
}
