{pkgs, ...}: {
  # Import common Home Manager modules
  imports = [
    ../common/home-base.nix
    ./programs/shells.nix
  ];

  # Darwin-specific Home Manager overrides
  home.sessionVariables = {
    # Empty for now, use common defaults from home-base.nix
    # Add Darwin-specific variables here if needed in the future
  };

  # Note: Starship Fish integration is handled by Home Manager
  # via programs.starship.enableFishIntegration = true (in common/programs/starship.nix)
  # No manual 'starship init fish | source' needed here

  # Note: Shell aliases and initialization are now in ./programs/shells.nix
  # to avoid duplication between home.nix and shells.nix

  # Darwin-specific packages (user-level)
  home.packages = with pkgs; [
    # Add Darwin-specific user packages if needed
    # Most packages are in common/packages/base.nix
  ];
}
