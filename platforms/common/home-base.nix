{
  config,
  pkgs,
  ...
}: {
  # Import common program configurations
  imports = [
    ./programs/fish.nix
    ./programs/starship.nix
    # ./programs/crush.nix  # REMOVED - crush is now installed as package, not module
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
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
    };
  };

  # Home Manager version for compatibility
  home.stateVersion = "24.05";

  # Shared session variables, path, and packages
  home = {
    sessionVariables = {
      EDITOR = "nano";
      LANG = "en_US.UTF-8";
    };

    # User PATH additions
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "$HOME/.bun/bin"
    ];

    # Core cross-platform packages
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
