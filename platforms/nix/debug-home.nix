{ config, pkgs, lib, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "larsartmann";
    homeDirectory = "/Users/larsartmann";
    stateVersion = "25.05";
  };

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Test package
  home.packages = [ pkgs.hello ];
}