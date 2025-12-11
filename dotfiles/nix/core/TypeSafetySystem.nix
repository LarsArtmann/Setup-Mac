# 🚀 Core Type Safety System
{ lib, pkgs, config, ... }:

let
  # Import assertion frameworks
  typeAssertions = import ./TypeAssertions.nix { inherit lib; };

in
{
  # Apply type safety to current configuration
  assertions = [
    # Check wrappers only if they exist (optional configuration)
    {
      assertion = !config ? wrappers || (config.wrappers != null && builtins.isAttrs config.wrappers);
      message = "Type safety system: wrappers must be defined as attribute set if present";
    }
    {
      assertion = config.environment.systemPackages != null && builtins.isList config.environment.systemPackages;
      message = "Type safety system: system packages must be defined as list";
    }
  ];
}