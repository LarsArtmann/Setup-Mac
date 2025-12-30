{lib, ...}: {
  # TEMP: Disable common module import to avoid sandbox merging conflicts
  # TODO: Refactor to properly override sandbox setting
  # imports = [../../common/core/nix-settings.nix];

  # Darwin-specific Nix settings
  # NOTE: Common settings from ../../common/core/nix-settings.nix included below
  # but with sandbox disabled to fix build failures
  nix.settings = {
    # Common Nix settings (from nix-settings.nix)
    experimental-features = "nix-command flakes";
    builders-use-substitutes = true;
    connect-timeout = 5;
    fallback = true;
    http-connections = 25;
    keep-derivations = true;
    keep-outputs = true;
    log-lines = 25;
    max-free = 3000000000; # 3GB
    min-free = 1000000000; # 1GB
    sandbox = false; # OVERRIDE: Disabled to match generation 205 working state
    substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ]; # NOTE: cache.nixos.org is included by default, don't duplicate
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ]; # NOTE: cache.nixos.org key is included by default, don't duplicate
    warn-dirty = false;
  };
}
