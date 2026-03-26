# evo-x2 Host Module (Optional)
#
# This module is provided as an alternative way to define the evo-x2 configuration.
# Currently, the main configuration is defined in flake.nix for backward compatibility.
#
# To migrate to this module:
# 1. Remove the nixosConfigurations."evo-x2" definition from flake.nix
# 2. Uncomment the imports in this module
#
# Following the vimjoyer pattern: https://www.vimjoyer.com/vid79-parts-wrapped
{
  self,
  inputs,
  ...
}: let
  # Uncomment to enable this host module
  # {
  #   # Define the NixOS configuration
  #   flake.nixosConfigurations.evo-x2 = inputs.nixpkgs.lib.nixosSystem {
  #     system = "x86_64-linux";
  #     modules = [
  #       self.nixosModules.evo-x2-configuration
  #     ];
  #   };
  # }
in {
  # Placeholder - configuration moved to flake.nix for backward compatibility
  # See modules/features/niri-wrapped.nix for wrapped niri package
}
