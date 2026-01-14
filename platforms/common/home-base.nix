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

  # Cross-platform shell configurations (Fish, Zsh, Bash)
  # All shells now use shared aliases from shell-aliases.nix
  # Platform-specific aliases added via lib.mkAfter in platform configs

  # Common program configurations
  programs = {
    # Enable Home Manager to manage itself
    home-manager.enable = true;

    # Go language configuration (Nix-native GOPATH management)
    go = {
      enable = true;
      # Note: env variables are set via home.sessionVariables below
      # This ensures GOPATH is available in all shells, not just Go commands
    };

    # uBlock Origin filter management
    ublock-filters = {
      enable = false; # Temporarily disabled due to time parsing issues
      enableAutoUpdate = true;
      updateInterval = "09:00";
    };
  };

  # Home configuration
  home = {
    # Session variables (available to all shells and applications)
    sessionVariables = {
      # Go development
      GOPATH = "${config.home.homeDirectory}/go";
    };

    # PATH additions (available to all shells)
    sessionPath = [
      # Go binaries (must use same path as GOPATH variable)
      "${config.home.homeDirectory}/go/bin"
    ];

    # Home Manager version for compatibility
    stateVersion = "24.05";
  };
}
