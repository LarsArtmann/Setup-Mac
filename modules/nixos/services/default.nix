{
  inputs,
  ...
}: {
  flake.nixosModules.default-services = _: {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    users.users.lars.extraGroups = ["docker"];
  };
}
