{ lib, pkgs, ... }:

# Platform Detection Library
#
# Provides centralized platform detection logic for use in Nix configurations
#
# Usage:
# { config, lib, pkgs, ... }:
# {
#   # Use platform checks
#   services.my-service.enable = lib.platform.isLinux;
#
#   # Use platform values
#   environment.sessionVariables.PLATFORM = lib.platform.name;
# }

{
  platform = {
    # Platform names
    name = if pkgs.stdenv.isDarwin then "darwin"
           else if pkgs.stdenv.isLinux then "linux"
           else "unknown";

    # Platform family
    family = if pkgs.stdenv.isDarwin then "unix"
            else if pkgs.stdenv.isLinux then "unix"
            else "unknown";

    # Platform-specific boolean checks
    isDarwin = pkgs.stdenv.isDarwin;
    isLinux = pkgs.stdenv.isLinux;
    isNixOS = pkgs.stdenv.isLinux && (builtins.substring 0 4 pkgs.stdenv.hostPlatform.system == "nixo"); # "nixos"
    isMacOS = pkgs.stdenv.isDarwin;
    isWindows = pkgs.stdenv.isWindows;

    # Architecture checks
    isx86_64 = pkgs.stdenv.hostPlatform.system == "x86_64-linux"
             || pkgs.stdenv.hostPlatform.system == "x86_64-darwin";

    isAarch64 = pkgs.stdenv.hostPlatform.system == "aarch64-linux"
              || pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
              || pkgs.stdenv.hostPlatform.system == "armv7a-linux";

    # Platform-specific packages
    packages = {
      # Linux-only packages
      linux = [ ]; // Add Linux-specific packages here

      # Darwin-only packages
      darwin = [ ]; // Add Darwin-specific packages here

      # NixOS-only packages
      nixos = [ ]; // Add NixOS-specific packages here
    };

    # Platform-specific environment variables
    env = {
      # Linux environment variables
      linux = { };

      # Darwin environment variables
      darwin = { };

      # NixOS environment variables
      nixos = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        GDK_BACKEND = "wayland";
        SDL_VIDEODRIVER = "wayland";
      };
    };

    # Platform-specific aliases (for Fish shell)
    aliases = {
      # Linux aliases (nixos-rebuild)
      linux = {
        nixup = "sudo nixos-rebuild switch --flake .";
        nixbuild = "nixos-rebuild build --flake .";
        nixcheck = "nixos-rebuild check --flake .";
      };

      # Darwin aliases (darwin-rebuild)
      darwin = {
        nixup = "darwin-rebuild switch --flake .";
        nixbuild = "darwin-rebuild build --flake .";
        nixcheck = "darwin-rebuild check --flake .";
      };
    };
  };
}
