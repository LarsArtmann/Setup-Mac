{
  pkgs,
  lib,
  ...
}: let
  # Common development environment variables (platform-agnostic)
  commonEnvVars = {
    # Core system settings
    EDITOR = "nano";
    LANG = "en_GB.UTF-8";

    # Optimize NIX_PATH for better performance
    NIX_PATH = lib.mkForce "nixpkgs=flake:nixpkgs";

    # Locale optimization
    LC_ALL = "en_GB.UTF-8";
    LC_CTYPE = "en_GB.UTF-8";

    # Development environment enhancements
    NODE_OPTIONS = "--max-old-space-size=4096";
    NPM_CONFIG_AUDIT = "false";
    NPM_CONFIG_FUND = "false";

    # Build and deployment optimization
    NIXPKGS_ALLOW_UNFREE = "1";
    NIXPKGS_ALLOW_BROKEN = "0"; # Strict: No broken packages
    NIXPKGS_ALLOW_INSECURE = "0"; # Strict: No insecure packages

    # Additional environment variables
    PAGER = "less";
    LESS = "-R"; # Enable color output in less
    CLICOLOR = "1"; # Enable color output in ls
    LSCOLORS = "ExGxBxDxCxEgEdxbxgxcxd"; # Custom ls colors
  };
in {
  # Shell configuration (platform-agnostic)
  environment.shells = with pkgs; [fish zsh bash];

  # Environment variables
  environment.variables = commonEnvVars;
}
