{ config, pkgs, lib, ... }:
{
  imports = [
    ./default.nix
    ./environment.nix
    ./nix/settings.nix
    ../common/packages/base.nix
  ];

  # Enable unfree packages for Chrome and Terraform
  nixpkgs.config.allowUnfree = true;

  # Allow terraform (unfree package)
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
}