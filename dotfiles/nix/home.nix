{ config, pkgs, lib, ... }:
let
  # Import centralized user and path configuration
  userConfig = (import ./core/UserConfig.nix { inherit lib; });
  pathConfig = (import ./core/PathConfig.nix { inherit lib; }) userConfig.defaultUser.username;

in {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = userConfig.defaultUser.username;
    homeDirectory = userConfig.defaultUser.homeDir;
    stateVersion = "25.05"; # Please read the comment before changing.
  };

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Shell configuration with aliases migrated from environment.nix
  programs.bash = {
    enable = true;
    shellAliases = {
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude ${pathConfig.home}/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude ${pathConfig.home}/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude ${pathConfig.home}/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };

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
