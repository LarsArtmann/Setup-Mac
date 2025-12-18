# Bat Wrapper - Enhanced cat with gruvbox theme
# Using centralized WrapperTemplate system to eliminate duplication

{ pkgs, lib, writeShellScriptBin, symlinkJoin, makeWrapper }:

let
  # Import centralized wrapper template with proper dependency injection
  wrapperTemplate = import ../../core/WrapperTemplate.nix {
    inherit lib writeShellScriptBin symlinkJoin makeWrapper;
  };

  # Create Bat wrapper using centralized template
  batWrapper = wrapperTemplate.createThemeWrapper "bat" pkgs.bat "gruvbox-dark" [
    "--style=numbers,changes,header"
  ];

in
{
  # Export wrapper for use in system packages
  bat = batWrapper;
}