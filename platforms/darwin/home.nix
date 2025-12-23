{pkgs, ...}: {
  imports = [
    ../common/home-base.nix
    ./modules/iterm2.nix
  ];

  # Darwin-specific Fish shell overrides
  programs.fish.shellAliases = {
    ll = "ls -la";
    update = "darwin-rebuild switch --flake .#Lars-MacBook-Air";
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
