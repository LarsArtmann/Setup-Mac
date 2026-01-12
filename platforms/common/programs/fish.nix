# Fish shell configuration
{config, lib, ...}: {
  # Common Fish shell configuration
  programs.fish = {
    enable = true;

    # Common aliases (platform-specific added via lib.mkAfter in platform configs)
    shellAliases = {
      # Essential shortcuts
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
    };

    # Common Fish shell initialization
    interactiveShellInit = ''
      # PERFORMANCE: Disable greeting for faster startup
      set -g fish_greeting

      # PERFORMANCE: Optimized history settings
      set -g fish_history_size 5000
      set -g fish_save_history 5000

      # Additional Fish-specific optimizations
      set -g fish_autosuggestion_enabled 1
    '';
  };
}
