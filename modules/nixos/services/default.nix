{inputs, ...}: {
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

    virtualisation.containers.storage.settings.storage = {
      driver = "overlay";
      graphroot = "/data/containers/storage";
      runroot = "/run/containers/storage";
    };

    users.users.lars.extraGroups = ["docker"];
  };
}
