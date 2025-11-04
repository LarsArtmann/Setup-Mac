# 🚀 Type-Safe Wrappers Configuration Module
# Integrates wrapper system with comprehensive type safety and assertions

{ config, lib, pkgs, ... }:

with lib;

let
  # Import unified type safety system
  typeSafetySystem = import ./core/TypeSafetySystem.nix { inherit pkgs lib config; };
  
  # Type-safe wrapper system import
  wrappersSystem = import ./wrappers/default.nix { inherit config lib pkgs; };

in
{
  # Apply type-safe wrappers configuration
  imports = [
    typeSafetySystem  # Import type safety system
    wrappersSystem   # Import type-safe wrapper system
  ];
  
  # Add type safety assertions
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
}
