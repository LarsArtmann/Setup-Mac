# Advanced Nix Software Wrapping System
# Simplified to working components only

{ config, lib, pkgs, ... }:

with lib;

let
  # Import only working wrapper modules
  starshipWrapper = import ./shell/starship.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };
  dynamicLibsWrapper = import ./applications/dynamic-libs.nix { inherit pkgs lib; };

in {
  # Active wrappers for current configuration (tested working)
  home.packages = [
    starshipWrapper.starship  # Deploys starship.toml configuration
    dynamicLibsWrapper.dynamic-libs  # Dynamic library management
  ];
}