# Common Home Manager configuration for all platforms
{config, ...}: {
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
    ./programs/ublock-filters.nix
  ];

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Cross-platform shell configurations (Fish, Zsh, Bash)
  # All shells now use shared aliases from shell-aliases.nix
  # Platform-specific aliases added via lib.mkAfter in platform configs

  # Go language configuration (Nix-native GOPATH management)
  programs.go = {
    enable = true;
    # Note: env variables are set via home.sessionVariables below
    # This ensures GOPATH is available in all shells, not just Go commands
  };

  # uBlock Origin filter management
  programs.ublock-filters = {
    enable = true;
    enableAutoUpdate = true;
    updateInterval = "09:00";
  };

  # Session variables (available to all shells and applications)
  home.sessionVariables = {
    # Go development
    GOPATH = "${config.home.homeDirectory}/go";
  };

  # PATH additions (available to all shells)
  home.sessionPath = [
    # Go binaries
    "$GOPATH/bin"
  ];

  # Home Manager version for compatibility
  home.stateVersion = "24.05";
}
