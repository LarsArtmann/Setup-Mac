{ pkgs, lib, ... }:
{
  # Import common environment variables
  imports = [ ../common/environment/variables.nix ];

  # Darwin-specific environment variables
  environment.variables = {
    # macOS-specific settings
    BROWSER = "google-chrome";
    TERMINAL = "iTerm2";
  };

  # Darwin-specific packages
  environment.systemPackages = with pkgs; [
    iterm2
    google-chrome
    # Homebrew managed packages are referenced but not installed here
  ];
}