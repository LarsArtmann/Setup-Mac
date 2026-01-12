# Fish shell configuration
{config, lib, ...}: let
  # Import shared aliases from shell-aliases.nix
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;
in {
  # Common Fish shell configuration
  programs.fish = {
    enable = true;

    # Use shared aliases (no duplication!)
    shellAliases = commonAliases;

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
