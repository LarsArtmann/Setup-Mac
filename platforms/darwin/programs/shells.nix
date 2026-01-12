# Import common shell configurations with platform-specific overrides
{lib, ...}: {
  imports = [
    ../../common/programs/fish.nix
  ];

  # Override Fish aliases with Darwin-specific ones
  programs.fish.shellAliases = lib.mkAfter {
    # Darwin-specific aliases
    nixup = "darwin-rebuild switch --flake .";
    nixbuild = "darwin-rebuild build --flake .";
    nixcheck = "darwin-rebuild check --flake .";
  };

  # Override Zsh aliases with Darwin-specific ones
  programs.zsh.shellAliases = lib.mkAfter {
    # Darwin-specific aliases
    nixup = "darwin-rebuild switch --flake .";
    nixbuild = "darwin-rebuild build --flake .";
    nixcheck = "darwin-rebuild check --flake .";
  };

  # Darwin-specific Fish shell initialization
  programs.fish.shellInit = lib.mkAfter ''
    # Homebrew integration (Darwin-specific)
    if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    end

    # COMPLETIONS: Universal completion engine (1000+ commands)
    carapace _carapace fish | source

    # PROMPT: Beautiful Starship prompt with 400ms timeout protection
    starship init fish | source

    # Additional Fish-specific optimizations
    set -g fish_autosuggestion_enabled 1
    set -g fish_complete_path /usr/local/share/fish/completions $fish_complete_path
  '';

  # Darwin-specific Zsh shell initialization
  programs.zsh.initContent = lib.mkAfter ''
    # Homebrew integration (Darwin-specific)
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # COMPLETIONS: Universal completion engine (1000+ commands)
    if command -v carapace >/dev/null 2>&1; then
      source <(carapace _carapace zsh)
    fi
  '';
}
