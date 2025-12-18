{ config, pkgs, lib, ... }:
{
  imports = [
    ./default.nix
    ./environment.nix
  ];
}