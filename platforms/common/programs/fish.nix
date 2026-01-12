# Fish shell configuration
{config, lib, ...}: let
  # Import shared aliases from shell-aliases.nix
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;

  # Expected common aliases
  expectedAliases = ["l" "t" "gs" "gd" "ga" "gc" "gp" "gl"];

  # Type assertions
  assertions = [
    {
      assertion = lib.isAttrs commonAliases;
      message = "programs.fish.shellAliases: Must be an attribute set";
    }
    {
      assertion = lib.length (lib.attrNames commonAliases) == lib.length expectedAliases;
      message = "programs.fish.shellAliases: Must have exactly ${toString (lib.length expectedAliases)} aliases, found ${toString (lib.length (lib.attrNames commonAliases))}";
    }
    {
      assertion = lib.all (name: lib.hasAttr name commonAliases) expectedAliases;
      message = "programs.fish.shellAliases: All expected aliases must be defined (l, t, gs, gd, ga, gc, gp, gl)";
    }
  ];
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
