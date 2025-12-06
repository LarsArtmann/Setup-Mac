{ config, pkgs, lib, ... }:

{
  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Shell configuration
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Shared Session variables
  home.sessionVariables = {
    EDITOR = "nano";
    LANG = "en_US.UTF-8";
  };

  # Shared Session path additions
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.bun/bin"
  ];

  # Core shared packages
  home.packages = with pkgs; [
    git
    curl
    wget
    ripgrep
    fd
    bat
    jq
    starship
  ];
}
