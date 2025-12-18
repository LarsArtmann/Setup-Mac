{ pkgs, lib, ... }:
{
  # macOS system defaults configuration
  system = {
    # Set system state version for nix-darwin
    stateVersion = 6;
    
    defaults = {
      # Global macOS settings
      NSGlobalDomain = {
        # Keyboard configuration
        KeyRepeat = 2;  # Key repeat rate
        InitialKeyRepeat = 15;  # Delay before repeat

        # Trackpad configuration
        "com.apple.trackpad.scaling" = 1.0;
      };

      # Finder preferences
      finder = {
        FXPreferredViewStyle = "Nlsv";  # List view
        ShowStatusBar = true;
        ShowPathbar = true;
      };
    };
  };
}