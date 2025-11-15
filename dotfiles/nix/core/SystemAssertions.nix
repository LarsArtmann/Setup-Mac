# 🏗️ System-Level Assertions Framework
# Provides comprehensive validation for entire Nix configuration

{ lib, pkgs, config, ... }:

let
  # System state validation assertions
  # Note: config.assertions expects { assertion = bool; message = str; } format
  systemAssertions = [
    {
      assertion = config.environment.systemPackages != [];
      message = "System must have packages defined";
    }
    {
      assertion = lib.all (pkg: pkg != null) config.environment.systemPackages;
      message = "All packages must be valid (no null values)";
    }
    {
      assertion = config.environment.shellAliases != {};
      message = "Shell aliases must be defined";
    }
    {
      assertion = config.environment.variables != null;
      message = "Environment variables must be defined";
    }
    {
      assertion = lib.versionAtLeast lib.version "2.4.0";
      message = "Nix version 2.4.0+ required for assertion features";
    }
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
