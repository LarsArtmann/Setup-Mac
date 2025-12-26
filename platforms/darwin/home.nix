{config, pkgs, lib, ...}: {
  # Import common Home Manager modules
  imports = [
    ../common/home-base.nix
  ];

  # Darwin-specific Home Manager overrides
  home.sessionVariables = {
    # Empty for now, use common defaults from home-base.nix
    # Add Darwin-specific variables here if needed in the future
  };

  # Darwin-specific Fish shell overrides
  programs.fish.shellAliases = {
    # Darwin-specific aliases
    nixup = "darwin-rebuild switch --flake .";
    nixbuild = "darwin-rebuild build --flake .";
    nixcheck = "darwin-rebuild check --flake .";
  };

  # Darwin-specific Fish shell initialization
  programs.fish.shellInit = ''
    # Homebrew integration (Darwin-specific)
    if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    end

    # COMPLETIONS: Universal completion engine (1000+ commands)
    carapace _carapace fish | source

    # Additional Fish-specific optimizations
    set -g fish_autosuggestion_enabled 1
    set -g fish_complete_path /usr/local/share/fish/completions $fish_complete_path
  '';

  # Note: Starship Fish integration is handled by Home Manager
  # via programs.starship.enableFishIntegration = true (in common/programs/starship.nix)
  # No manual 'starship init fish | source' needed here

  # Darwin-specific packages (user-level)
  home.packages = with pkgs; [
    # Add Darwin-specific user packages if needed
    # Most packages are in common/packages/base.nix
  ];
}
