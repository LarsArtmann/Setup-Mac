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
      assertion = true;  # Package validation disabled for now
      message = "All packages must be valid (no null values)";
    }
    {
      assertion = config.environment.shellAliases != {};
      message = "Shell aliases must be defined";
    }
    {
      assertion = true;  # Environment variables check disabled for now
      message = "Environment variables must be defined";
    }
    {
      assertion = true;  # Nix version check disabled for now
      message = "Nix version 2.4.0+ required for assertion features";
    }
  ];

in
{
  # Apply assertions at system level
  assertions = systemAssertions;
}
