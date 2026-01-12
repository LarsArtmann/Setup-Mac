{
  config,
  pkgs,
  ...
}: {
  # Import common program configurations
  imports = [
    # Shell configurations (shared aliases, no duplication!)
    ./programs/fish.nix
    ./programs/zsh.nix

    # Other program configurations
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/activitywatch.nix
    ./programs/tmux.nix
  ];

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
  };

  # Home Manager version for compatibility
  home.stateVersion = "24.05";

  # Shared session variables, path, and packages
  home = {
    # Note: EDITOR, LANG, and LC_ALL are set in common/environment/variables.nix
    # Home Manager home.sessionVariables override common environment.sessionVariables
    # Keeping this empty to use common environment variables
    # sessionVariables = { EDITOR = "micro"; };  # Uncomment to override

    # User PATH additions
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "$HOME/.bun/bin"
    ];

    # Core cross-platform packages (only packages NOT in base.nix)
    packages = with pkgs; [
      # Git, curl, wget, ripgrep, fd, bat, jq, starship are in base.nix
    ];
  };
}
