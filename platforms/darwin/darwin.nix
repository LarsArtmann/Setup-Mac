{ config, pkgs, lib, ... }:
{
  imports = [
    ./default.nix
    ./environment.nix
    ../common/packages/base.nix
  ];
  
  # Enable unfree packages for Chrome
  nixpkgs.config.allowUnfree = true;
}