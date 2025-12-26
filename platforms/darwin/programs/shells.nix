# Import common Fish configuration with platform-specific overrides
{lib, ...}: {
  imports = [
    ../../common/programs/fish.nix
    ../../common/programs/starship.nix
    ../../common/programs/tmux.nix
  ];

  # Override platform aliases with Darwin-specific ones
  programs.fish.shellAliases = lib.mkAfter {
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
}
