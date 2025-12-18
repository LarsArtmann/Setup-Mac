{ config, pkgs, lib, ... }:

{
  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Cross-platform shell configurations
  programs = {
    bash = {
      enable = true;
      profileExtra = ''
        export GOPRIVATE=github.com/LarsArtmann/*
      '';
      initExtra = ''
        export GH_PAGER=""
      '';
    };
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
    };
  };

  # Shared session variables
  home.sessionVariables = {
    EDITOR = "nano";
    LANG = "en_US.UTF-8";
  };

  # User PATH additions
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.bun/bin"
  ];

  # Core cross-platform packages
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