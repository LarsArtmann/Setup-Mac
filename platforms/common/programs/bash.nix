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
    profileExtra = ''
      export GOPRIVATE="github.com/LarsArtmann/*"
      export GONOSUMDB="github.com/LarsArtmann/*"
    '';

    initExtra = ''
      export GH_PAGER=""
    '';
  };
}
