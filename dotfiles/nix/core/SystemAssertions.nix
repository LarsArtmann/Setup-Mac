# 🏗️ System-Level Assertions Framework
# Provides comprehensive validation for entire Nix configuration

{ lib, pkgs, config, ... }:

let
  # System state validation assertions
  systemAssertions = [
    (lib.assertMsg
      (config.environment.systemPackages != [])
      "System must have packages defined"
    )
    (lib.assertMsg
      (all (pkg: pkg != null) config.environment.systemPackages)
      "All packages must be valid (no null values)"
    )
    (lib.assertMsg
      (config.environment.shellAliases != {})
      "Shell aliases must be defined"
    )
    (lib.assertMsg
      (config.environment.variables != null)
      "Environment variables must be defined"
    )
    (lib.assertMsg
      (lib.versionAtLeast lib.version "2.4.0")
      "Nix version 2.4.0+ required for assertion features"
    )
  ];

in
{
  # Apply assertions at system level
  config = lib.mkMerge [
    (builtins.trace "🔍 Applying system assertions..." {})
    {
      assertions = systemAssertions;
    }
  ];
}
