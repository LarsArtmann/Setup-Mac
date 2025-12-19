{ pkgs, lib, ... }:

let
  # Common aliases that work across platforms
  commonAliases = {
    # Essential shortcuts
    l = "ls -laSh";
    t = "tree -h -L 2 -C --dirsfirst";
  };

  # Platform-specific aliases (to be overridden by platform configs)
  platformAliases = {};

  # Common Fish shell initialization
  commonInit = ''
    # PERFORMANCE: Disable greeting for faster startup
    set -g fish_greeting

    # PERFORMANCE: Optimized history settings
    set -g fish_history_size 5000
    set -g fish_save_history 5000

    # Additional Fish-specific optimizations
    set -g fish_autosuggestion_enabled 1
  '';

  # Platform-specific initialization (to be overridden by platform configs)
  platformInit = "";

in {
  # Common Fish shell configuration
  programs.fish = {
    enable = true;
    
    # Merge common and platform-specific aliases
    shellAliases = commonAliases // platformAliases;
    
    # Merge common and platform-specific initialization
    interactiveShellInit = commonInit + platformInit;
  };
}