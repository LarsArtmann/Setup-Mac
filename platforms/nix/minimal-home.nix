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

  # Session variables that make sense to be user-specific (migrated from environment.nix)
  home.sessionVariables = {
    EDITOR = "nano";
    LANG = "en_GB.UTF-8";
  };

  # Session path additions (user-specific paths)
   home.sessionPath = [
    "$HOME/.local/bin/crush"
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.bun/bin"
    "$HOME/.turso"
    "$HOME/.orbstack/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  ];

  # Import custom modules
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