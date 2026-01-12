# Bash shell configuration
{config, lib, ...}: let
  # Import shared aliases from shell-aliases.nix
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;

  # Expected common aliases
  expectedAliases = ["l" "t" "gs" "gd" "ga" "gc" "gp" "gl"];

  # Type assertions
  assertions = [
    {
      assertion = lib.isAttrs commonAliases;
      message = "programs.bash.shellAliases: Must be an attribute set";
    }
    {
      assertion = lib.length (lib.attrNames commonAliases) == lib.length expectedAliases;
      message = "programs.bash.shellAliases: Must have exactly ${toString (lib.length expectedAliases)} aliases, found ${toString (lib.length (lib.attrNames commonAliases))}";
    }
    {
      assertion = lib.all (name: lib.hasAttr name commonAliases) expectedAliases;
      message = "programs.bash.shellAliases: All expected aliases must be defined (l, t, gs, gd, ga, gc, gp, gl)";
    }
  ];
in {
  # Common Bash shell configuration
  programs.bash = {
    enable = true;

    # Use shared aliases (no duplication!)
    shellAliases = commonAliases;

    # Bash-specific configuration
    profileExtra = ''
      export GOPRIVATE=github.com/LarsArtmann/*
    '';

    initExtra = ''
      export GH_PAGER=""
    '';
  };
}
