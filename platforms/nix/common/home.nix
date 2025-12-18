{ config, pkgs, lib, ... }:

{
  # Enable Home Manager to manage itself
  programs = {
    home-manager.enable = true;

    # Shell configuration
    bash = {
      enable = true;
      profileExtra = ''
        # Using PATH and environment variables from nix-darwin instead of setting them here
        # This ensures consistency across shells
        # JAVA_HOME is now set in dotfiles/nix/environment.nix

        export GOPRIVATE=github.com/LarsArtmann/*
      '';
      initExtra = ''
        # Keep this empty
        # Using PATH from nix-darwin instead of modifying it here
        # All PATH modifications are now consolidated in dotfiles/nix/environment.nix

        export GH_PAGER=""
      '';
    };
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
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
