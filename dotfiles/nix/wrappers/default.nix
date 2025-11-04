# Advanced Nix Software Wrapping System
# Transforms traditional dotfiles into self-contained, portable packages

{ config, lib, pkgs, ... }:

with lib;

let
  # Import all wrapper modules
  batWrapper = import ./applications/bat.nix { inherit pkgs lib; };
  kittyWrapper = import ./applications/kitty.nix { inherit pkgs lib; };
  sublimeTextWrapper = import ./applications/sublime-text.nix { inherit pkgs lib; };
  activitywatchWrapper = import ./applications/activitywatch.nix { inherit pkgs lib; };
  fishWrapper = import ./shell/fish.nix { inherit pkgs lib; };
  starshipWrapper = import ./shell/starship.nix { inherit pkgs lib; };

in
{
  # Core wrapper system configuration
  environment.systemPackages = with pkgs; [
    batWrapper.bat
    starshipWrapper.starship
    fishWrapper.fish
    kittyWrapper.kitty
    sublimeTextWrapper."sublime-text"
    activitywatchWrapper.activitywatch
  ];
  
  # Set wrapped tools as defaults
  environment.shellAliases = {
    cat = "bat";  # Use wrapped bat instead of cat
  };
}