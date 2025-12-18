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
    # Note: Google Chrome removed due to unfree license issues
    # iterm2  # Managed through nix-darwin directly
  ];
}