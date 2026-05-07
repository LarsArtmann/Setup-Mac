_: {
  flake.nixosModules.default-services = {
    config,
    lib,
    ...
  }: {
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

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
