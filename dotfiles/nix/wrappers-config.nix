# Wrappers Configuration Module
# Integrates wrapper system with existing Nix configuration

{ config, lib, pkgs, ... }:

with lib;

let
  wrappersSystem = import ./wrappers/default.nix { inherit config lib pkgs; };

in
{
  imports = [
    wrappersSystem
  ];
}