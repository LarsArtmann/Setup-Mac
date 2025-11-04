# 🚀 Core Type Safety System
{ lib, pkgs, config, ... }:

let
  # Import assertion frameworks
  typeAssertions = import ./TypeAssertions.nix { inherit lib; };
  
in
{
  # Apply type safety to current configuration
  config = {
    assertions = [
      (lib.assertMsg 
        (config.wrappers != null && builtins.isAttrs config.wrappers) 
        "Type safety system: wrappers must be defined as attribute set"
      )
      (lib.assertMsg 
        (config.environment.systemPackages != null && builtins.isList config.environment.systemPackages) 
        "Type safety system: system packages must be defined as list"
      )
    ];
  };
}