{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "larsartmann";
    homeDirectory = "/Users/larsartmann";
    stateVersion = "25.05"; # Please read the comment before changing.
  };

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Shell configuration with aliases migrated from environment.nix
  programs.bash = {
    enable = true;
    shellAliases = {
      l = "ls -la";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      l = "ls -la";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };

  # Session variables that make sense to be user-specific (migrated from environment.nix)
  home.sessionVariables = {
    EDITOR = "nano";
    LANG = "en_GB.UTF-8";
  };

  # Session path additions (user-specific paths)
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.bun/bin"
    "$HOME/.turso"
    "$HOME/.orbstack/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  ];
}