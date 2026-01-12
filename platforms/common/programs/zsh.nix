# Zsh shell configuration (Cross-Platform)
# Performance-optimized config migrated from dotfiles/.zshrc
{config, lib, ...}: let
  # Import shared aliases from shell-aliases.nix
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;

  # Expected common aliases
  expectedAliases = ["l" "t" "gs" "gd" "ga" "gc" "gp" "gl"];

  # Type assertions
  assertions = [
    {
      assertion = lib.isAttrs commonAliases;
      message = "programs.zsh.shellAliases: Must be an attribute set";
    }
    {
      assertion = lib.length (lib.attrNames commonAliases) == lib.length expectedAliases;
      message = "programs.zsh.shellAliases: Must have exactly ${toString (lib.length expectedAliases)} aliases, found ${toString (lib.length (lib.attrNames commonAliases))}";
    }
    {
      assertion = lib.all (name: lib.hasAttr name commonAliases) expectedAliases;
      message = "programs.zsh.shellAliases: All expected aliases must be defined (l, t, gs, gd, ga, gc, gp, gl)";
    }
  ];
in {
  # Common Zsh shell configuration
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    # Use shared aliases (no duplication!)
    shellAliases = commonAliases;

    # Autosuggestions
    autosuggestion.enable = true;

    # History
    history = {
      ignoreDups = true;
      ignoreSpace = true;
      save = 10000;
      size = 10000;
      share = false;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    # Syntax highlighting
    syntaxHighlighting.enable = true;

    # Environment variables
    envExtra = ''
      # Environment variables
      export GPG_TTY=$(tty)
      export GH_PAGER=""

      # Source private environment variables (not tracked in git)
      if [[ -f ~/.env.private ]]; then
        source ~/.env.private
      fi
    '';
  };
}
