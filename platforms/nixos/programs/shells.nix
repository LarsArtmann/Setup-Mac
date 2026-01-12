# NixOS shell configurations with platform-specific overrides
{lib, ...}: {
  # Override Fish aliases with NixOS-specific ones
  programs.fish.shellAliases = lib.mkAfter {
    # NixOS-specific aliases
    nixup = "sudo nixos-rebuild switch --flake .";
    nixbuild = "sudo nixos-rebuild build --flake .";
    nixcheck = "sudo nixos-rebuild test --flake .";
  };

  # Override Zsh aliases with NixOS-specific ones
  programs.zsh.shellAliases = lib.mkAfter {
    # NixOS-specific aliases
    nixup = "sudo nixos-rebuild switch --flake .";
    nixbuild = "sudo nixos-rebuild build --flake .";
    nixcheck = "sudo nixos-rebuild test --flake .";
  };

  # Override Bash aliases with NixOS-specific ones
  programs.bash.shellAliases = lib.mkAfter {
    # NixOS-specific aliases
    nixup = "sudo nixos-rebuild switch --flake .";
    nixbuild = "sudo nixos-rebuild build --flake .";
    nixcheck = "sudo nixos-rebuild test --flake .";
  };

  # NixOS-specific Fish shell initialization
  programs.fish.shellInit = lib.mkAfter ''
    # Nix path setup (NixOS-specific)
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

    # NixOS-specific completions
    if test -d /etc/profiles/per-user/$USER/share/nixos/completions
        set -g fish_complete_path /etc/profiles/per-user/$USER/share/nixos/completions $fish_complete_path
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
  '';

  # NixOS-specific Zsh shell initialization
  programs.zsh.initContent = lib.mkAfter ''
    # NixOS-specific completions
    if [ -d /etc/profiles/per-user/$USER/share/nixos/completions ]; then
      fpath+=/etc/profiles/per-user/$USER/share/nixos/completions
    fi

    # COMPLETIONS: Universal completion engine (1000+ commands)
    if command -v carapace >/dev/null 2>&1; then
      source <(carapace _carapace zsh)
    fi
  '';

  # NixOS-specific Bash shell initialization
  programs.bash.initExtra = lib.mkAfter ''
    # NixOS-specific completions
    if [ -d /etc/profiles/per-user/$USER/share/nixos/completions ]; then
      fpath+=/etc/profiles/per-user/$USER/share/nixos/completions
    fi
  '';
}
