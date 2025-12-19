{ pkgs, lib, ... }:
{
  # Fish shell configuration (cross-platform)
  programs.fish = {
    enable = true;
    shellAliases = {
      # Essential shortcuts only
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch --flake .";
      nixbuild = "darwin-rebuild build --flake .";
      nixcheck = "darwin-rebuild check --flake .";
    };
    shellInit = ''
      # PERFORMANCE: Disable greeting for faster startup
      set -g fish_greeting

      # HOMEBREW INTEGRATION: Add Homebrew to PATH (critical for CLI tools)
      if test -f /opt/homebrew/bin/brew
          eval (/opt/homebrew/bin/brew shellenv)
      end

      # COMPLETIONS: Universal completion engine (1000+ commands)
      carapace _carapace fish | source

      # PROMPT: Beautiful Starship prompt with 400ms timeout protection
      starship init fish | source

      # PERFORMANCE: Optimized history settings
      set -g fish_history_size 5000
      set -g fish_save_history 5000

      # Additional Fish-specific optimizations
      set -g fish_autosuggestion_enabled 1
      set -g fish_complete_path /usr/local/share/fish/completions $fish_complete_path
    '';
  };
}