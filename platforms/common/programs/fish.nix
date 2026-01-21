# Fish shell configuration
_: let
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
      # LOCALE: Set English locale for git and other tools
      set -gx LANG en_US.UTF-8
      set -gx LC_ALL en_US.UTF-8
      set -gx LC_CTYPE en_US.UTF-8

      # PERFORMANCE: Disable greeting for faster startup
      set -g fish_greeting

      # PERFORMANCE: Optimized history settings
      set -g fish_history_size 5000
      set -g fish_save_history 5000

      # Additional Fish-specific optimizations
      set -g fish_autosuggestion_enabled 1

      # Private Go modules (use SSH instead of public proxy)
      set -gx GOPRIVATE "github.com/LarsArtmann/*"

      # Disable checksum database for private repos
      set -gx GONOSUMDB "github.com/LarsArtmann/*"

      # Note: GOPATH is managed by Home Manager programs.go
      # Fish will inherit GOPATH automatically from Home Manager session variables

      # GOPATH/bin needs to be in PATH for Go binaries
      fish_add_path --prepend --global $GOPATH/bin
    '';
  };
}
