{ config, pkgs, lib, ... }:
let
  # Import centralized user and path configuration
  userConfig = (import ./core/UserConfig.nix { inherit lib; });
  pathConfig = (import ./core/PathConfig.nix { inherit lib; }) userConfig.defaultUser.username;

in {
  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Shell configuration temporarily disabled to isolate Home Manager issues
  # programs.bash.enable = false;
  # programs.zsh.enable = false;
  # programs.fish.enable = false;

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
