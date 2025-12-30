{
  lib,
  pkgs,
  config,
  ...
}: {
  # Import Darwin-specific system configurations
  imports = [
    ./networking/default.nix
    ./nix/settings.nix
    ./security/pam.nix
    ./services/default.nix
    ./system/activation.nix
    ./system/settings.nix
    ./environment.nix
    ../common/packages/base.nix
    ../common/packages/fonts.nix
  ];

  ## TODO: Should we move these nixpkgs configs to ../common/?
  # Enable unfree packages for Chrome and Terraform
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["terraform"];
  };

  # Define users for Home Manager (workaround for nix-darwin/common.nix import issue)
  users.users.larsartmann = {
    name = "larsartmann";
    home = "/Users/larsartmann";
  };
}
