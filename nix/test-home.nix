{ config, pkgs, lib, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "larsartmann";
    homeDirectory = "/Users/larsartmann";  # Explicitly set for now
    stateVersion = "25.05";
  };

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Import ghost wallpaper module only
  imports = [
    ./modules/ghost-wallpaper.nix
  ];

  # Enable Ghost Btop Wallpaper
  programs.ghost-btop-wallpaper = {
    enable = true;
    updateRate = 2000;
    backgroundOpacity = "0.0";
  };
}