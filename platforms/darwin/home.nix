{
  pkgs,
  nix-ssh-config,
  ...
}: {
  imports = [
    ../common/home-base.nix
    ./programs/shells.nix
    nix-ssh-config.homeManagerModules.ssh
  ];
}
