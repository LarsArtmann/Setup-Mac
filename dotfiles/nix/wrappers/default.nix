# Advanced Nix Software Wrapping System
# Transforms traditional dotfiles into self-contained, portable packages

{ config, lib, pkgs, ... }:

with lib;

let
  # Import all wrapper modules with dependency injection
  # batWrapper = import ./applications/bat.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };  # WrapperTemplate build issue
  kittyWrapper = import ./applications/kitty.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };
  # sublimeTextWrapper = import ./applications/sublime-text.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };  # sublimetext4 is Linux-only
  # activitywatchWrapper = import ./applications/activitywatch.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };  # python3.13-pynput is broken
  fishWrapper = import ./shell/fish.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };
  starshipWrapper = import ./shell/starship.nix { inherit pkgs lib; inherit (pkgs) writeShellScriptBin symlinkJoin makeWrapper; };

  # Enhanced dynamic library wrappers
  dynamicLibsWrapper = import ./applications/dynamic-libs.nix { inherit pkgs lib; };
  exampleWrappers = import ./applications/example-wrappers.nix { inherit pkgs lib; };

in
{
  # Core wrapper system configuration
  environment.systemPackages = with pkgs; [
    # batWrapper.bat  # WrapperTemplate build issue - TODO: fix
    starshipWrapper.starship
    fishWrapper.fish
    kittyWrapper.kitty
    # sublimeTextWrapper."sublime-text"  # sublimetext4 is Linux-only (no Darwin support)
    # activitywatchWrapper.activitywatch  # python3.13-pynput dependency is broken

    # Enhanced dynamic library wrappers (testing enabled)
    exampleWrappers.vscode
    # exampleWrappers.docker
  ];

  # Set wrapped tools as defaults
  environment.shellAliases = {
    # cat = "bat";  # Use wrapped bat instead of cat - TODO: fix bat wrapper
    ll = "ls -lah";  # Common alias for detailed listing
  };

  # Export dynamic library wrapper functions for use in other modules
  _module.args.dynamicLibsWrapper = dynamicLibsWrapper;
  _module.args.exampleWrappers = exampleWrappers;
}