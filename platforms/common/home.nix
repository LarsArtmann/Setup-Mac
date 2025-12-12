{ config, pkgs, lib, ... }:

{
  # Common home configuration for all platforms
  home.sessionVariables = {
    # Common environment variables
    EDITOR = "vim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
  };

  # Common packages available on all platforms
  home.packages = with pkgs; [
    # Common CLI tools
    git
    vim
    fish
    starship
    curl
    wget
    tree
    ripgrep
    fd
    eza
    bat
    jq
    yq-go
    just
    glow
    bottom
    procs
    sd
    dust
    graphviz
  ];

  # Fish Shell Configuration (Common)
  programs.fish = {
    enable = true;
    shellAliases = {
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
    };
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  # Starship Prompt (Common)
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "$all$character";
    };
  };


}