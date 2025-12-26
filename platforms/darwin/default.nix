{lib, pkgs, ...}: {
  # Import Darwin-specific system configurations
  imports = [
    ./networking/default.nix
    ./nix/settings.nix
    ./programs/shells.nix
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
}
