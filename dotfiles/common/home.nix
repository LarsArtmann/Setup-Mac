{ config, pkgs, lib, ... }:

{
  # Enable Home Manager to manage itself
  programs = {
    home-manager.enable = true;

    # Shell configuration
    bash.enable = true;
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
    };
    fish.enable = true;
  };

  # Shared Session variables, path, and packages
  home = {
    sessionVariables = {
      EDITOR = "nano";
      LANG = "en_US.UTF-8";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "$HOME/.bun/bin"
    ];

    # Core shared packages
    packages = with pkgs; [
      git
      curl
      wget
      ripgrep
      fd
      bat
      jq
      starship
    ];
  };
}
