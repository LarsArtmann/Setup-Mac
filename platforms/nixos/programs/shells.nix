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
    # NixOS-specific completions
    if test -d /etc/profiles/per-user/$USER/share/nixos/completions
        set -g fish_complete_path /etc/profiles/per-user/$USER/share/nixos/completions $fish_complete_path
    end

    # COMPLETIONS: Universal completion engine (1000+ commands)
    carapace _carapace fish | source

    # PROMPT: Beautiful Starship prompt with 400ms timeout protection
    starship init fish | source

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
