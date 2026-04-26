_: {
  flake.nixosModules.default-services = _: {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      storageDriver = "overlay2";
      daemon.settings = {
        data-root = "/data/docker";
      };
    };

    users.users.lars.extraGroups = ["docker"];
  };
}
