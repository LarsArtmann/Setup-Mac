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
    # Nix path setup (Darwin-specific)
    # Required for system packages and Home Manager-managed binaries
    if type -q fish_add_path
        fish_add_path --prepend --global /run/current-system/sw/bin
        fish_add_path --prepend --global /etc/profiles/per-user/$USER/bin
    else
        if not contains /run/current-system/sw/bin $fish_user_paths
            set --global fish_user_paths /run/current-system/sw/bin $fish_user_paths
        end
        if not contains /etc/profiles/per-user/$USER/bin $fish_user_paths
            set --global fish_user_paths /etc/profiles/per-user/$USER/bin $fish_user_paths
        end
    end

    # Homebrew integration (Darwin-specific)
    if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    end

    # COMPLETIONS: Universal completion engine (1000+ commands)
    if command -v carapace >/dev/null 2>&1
        carapace _carapace fish | source
    end

    # PROMPT: Beautiful Starship prompt with 400ms timeout protection
    if command -v starship >/dev/null 2>&1
        starship init fish | source
    end

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
