{ pkgs, lib, ... }:

let
  # Base configuration (cross-platform)
  baseConfig = {
    # ActivityWatch Configuration (Cross-Platform)
    services.activitywatch = {
      enable = true;
      package = pkgs.activitywatch;
      watchers = {
        # Enable AFK watcher (works on both platforms)
        aw-watcher-afk = {
          package = pkgs.activitywatch;
        };
      };
    };
  };

  # Platform-specific additions
  linuxConfig = lib.optionalAttrs pkgs.stdenv.isLinux {
    # Linux-specific watchers (Wayland)
    services.activitywatch.watchers.aw-watcher-window-wayland = {
      package = pkgs.aw-watcher-window-wayland;
    };
  };

  darwinConfig = lib.optionalAttrs pkgs.stdenv.isDarwin {
    # macOS-specific watchers can be added here
    # Note: macOS window watchers may have different packages
  };

in
  # Merge all configurations
  lib.recursiveUpdate baseConfig (lib.recursiveUpdate linuxConfig darwinConfig)