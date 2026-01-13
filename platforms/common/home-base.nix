# Common Home Manager configuration for all platforms
{config, pkgs, lib, ...}: {
  # Import common program configurations
  imports = [
    # Shell configurations (shared aliases, no duplication!)
    ./programs/fish.nix
    ./programs/zsh.nix
    ./programs/bash.nix
    ./programs/nushell.nix

    # Other program configurations
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/activitywatch.nix
    ./programs/tmux.nix
    ./programs/git.nix
    ./programs/fzf.nix
    ./programs/pre-commit.nix
  ];

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Cross-platform shell configurations (Fish, Zsh, Bash)
  # All shells now use shared aliases from shell-aliases.nix
  # Platform-specific aliases added via lib.mkAfter in platform configs

  # Go language configuration (Nix-native GOPATH management)
  programs.go = {
    enable = true;
    env = {
      GOPATH = "${config.home.homeDirectory}/go";
    };
  };

  # Home Manager version for compatibility
  home.stateVersion = "24.05";
}
