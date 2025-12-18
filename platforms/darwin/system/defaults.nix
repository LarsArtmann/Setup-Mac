{ pkgs, lib, ... }:
{
  # macOS system defaults configuration
  system.defaults = {
    # Global macOS settings
    NSGlobalDomain = {
      # Keyboard configuration
      KeyRepeat = 2;  # Key repeat rate
      InitialKeyRepeat = 15;  # Delay before repeat

      # Trackpad configuration
      "com.apple.trackpad.scaling" = 1.0;
      "com.apple.mouse.scaling" = 1.0;
    };

    # Finder preferences
    finder = {
      FXCalculateAllSizes = true;  # Always calculate folder sizes
      FXPreferredViewStyle = "Nlsv";  # List view
      ShowStatusBar = true;
      ShowPathbar = true;
    };
  };
}