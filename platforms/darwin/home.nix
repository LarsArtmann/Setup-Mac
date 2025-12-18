{ config, pkgs, lib, ... }:
{
  imports = [
    ../common/home-base.nix
  ];

  # Fish Shell Configuration (Darwin-specific)
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      update = "darwin-rebuild switch --flake .#Lars-MacBook-Air";
    };
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  # Starship Prompt (Darwin-specific)
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "$all$character";
    };
  };

  # Darwin-specific home configuration
  home.sessionVariables = {
    # Add macOS-specific environment variables
    BROWSER = "google-chrome";
    TERMINAL = "iTerm2";
  };

  # Darwin-specific packages
  home.packages = with pkgs; [
    # Note: Google Chrome and iTerm2 removed due to unfree/license issues
    # These will be managed through system packages or Homebrew
  ];
}