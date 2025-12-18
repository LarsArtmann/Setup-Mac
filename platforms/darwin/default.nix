{ pkgs, lib, ... }:
{
  # Import Darwin-specific system configurations
  imports = [
    ./system/defaults.nix
    ./system/activation.nix
    ./programs/shells.nix
  ];
}