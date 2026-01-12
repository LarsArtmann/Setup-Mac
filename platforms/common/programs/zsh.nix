# Zsh shell configuration
{config, ...}: let
  # Import shared aliases from shell-aliases.nix
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;
in {
  # Common Zsh shell configuration
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    # Use shared aliases (no duplication!)
    shellAliases = commonAliases;
  };
}
