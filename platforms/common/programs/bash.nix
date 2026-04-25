# Bash shell configuration
_: let
  # Import shared aliases from shell-aliases.nix
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;
  # Expected common aliases
  # Type assertions
in {
  # Common Bash shell configuration
  programs.bash = {
    enable = true;

    # Use shared aliases (no duplication!)
    shellAliases = commonAliases;

    # Bash-specific configuration
    initExtra = ''
      export GH_PAGER=""

      # History
      export HISTCONTROL=ignoredups:erasedups
      export HISTSIZE=10000
      export HISTFILESIZE=10000
      shopt -s histappend checkwinsize autocd
    '';
  };
}
